"""发布规则：把产物上传到 Modrinth，并在本地完成 Git 标签与 GitHub Release。

一次 `bazel run` 即可完成整个发布流程：

1. `publish_entry` 描述一个待发布的版本（产物、文件名、版本名、游戏版本）
2. `publish` 聚合一到多个 `publish_entry`，在同一个进程里依次上传全部版本
3. 全部上传成功后创建并推送 Git 标签，再用系统 `gh` 创建 GitHub Release

`datapack_publish` 是数据包场景的简化宏，供 `complete_datapack_config` 使用。
"""

load("@//rule:validation.bzl", "validate_semver")

_SH_TOOLCHAIN_TYPE = "@rules_shell//shell:toolchain_type"

# 发布默认值只在这里定义一次：规则属性与上层宏都引用同一组常量，
# 避免同一批默认值在多处各写一份而静默分叉
DEFAULT_VERSION_TYPE = "release"
DEFAULT_CHANGELOG = "NEWS.md"
DEFAULT_AUTO_TAG = True
DEFAULT_GITHUB_RELEASE = True
DEFAULT_GITHUB_DISCUSSION_CATEGORY = "Announcements"

# ---------------------------------------------------------------------------
# Modrinth 依赖
# ---------------------------------------------------------------------------

def _modrinth_dependency_info_init(*, version_id, project_id, dependency_type):
    if not project_id:
        fail("project_id must be specified")
    allowed_dependency_types = [
        "required",
        "optional",
        "incompatible",
        "embedded",
    ]
    if dependency_type not in allowed_dependency_types:
        fail("dependency_type must be one of %s" % allowed_dependency_types)
    return {
        "version_id": version_id,
        "project_id": project_id,
        "dependency_type": dependency_type,
    }

ModrinthDependencyInfo, _ = provider(
    doc = "A Modrinth dependency",
    fields = [
        "version_id",
        "project_id",
        "dependency_type",
    ],
    init = _modrinth_dependency_info_init,
)

def _modrinth_dependency_impl(ctx):
    return [
        ModrinthDependencyInfo(
            version_id = ctx.attr.version_id,
            project_id = ctx.attr.project_id,
            dependency_type = ctx.attr.dependency_type,
        ),
    ]

modrinth_dependency = rule(
    implementation = _modrinth_dependency_impl,
    attrs = {
        "version_id": attr.string(
            doc = "The ID of the version to depend on.",
            mandatory = False,
        ),
        "project_id": attr.string(
            doc = "The ID of the project to depend on.",
            mandatory = True,
        ),
        "dependency_type": attr.string(
            doc = "The type of the dependency.",
            mandatory = True,
        ),
    },
)

# ---------------------------------------------------------------------------
# 发布项
# ---------------------------------------------------------------------------

def _publish_entry_info_init(*, file, file_name, version_name, game_versions):
    return {
        "file": file,
        "file_name": file_name,
        "version_name": version_name,
        "game_versions": game_versions,
    }

PublishEntryInfo, _publish_entry_info = provider(
    doc = "A single version to publish",
    fields = [
        "file",
        "file_name",
        "version_name",
        "game_versions",
    ],
    init = _publish_entry_info_init,
)

def _strip_zip_suffix(file_name):
    if file_name.endswith(".zip"):
        return file_name[:-len(".zip")]
    return file_name

def _publish_entry_impl(ctx):
    file_name = ctx.attr.file_name if ctx.attr.file_name else ctx.file.file.basename
    return [
        PublishEntryInfo(
            file = ctx.file.file,
            file_name = file_name,
            # 版本名默认与产物同名（去掉 .zip），命名只在产物那一处决定
            version_name = ctx.attr.version_name if ctx.attr.version_name else _strip_zip_suffix(file_name),
            game_versions = ctx.attr.game_versions,
        ),
    ]

publish_entry = rule(
    doc = "描述单个待发布的版本，由 publish 聚合。",
    implementation = _publish_entry_impl,
    attrs = {
        "file": attr.label(
            doc = "The file to publish.",
            mandatory = True,
            allow_single_file = True,
        ),
        "file_name": attr.string(
            doc = "The name of the published file. Defaults to the basename of `file`, which is also the name used for GitHub Release attachments.",
            mandatory = False,
        ),
        "version_name": attr.string(
            doc = "The name of the version to publish. Defaults to the published file name without its .zip suffix.",
            mandatory = False,
        ),
        "game_versions": attr.string_list(
            doc = "The game versions of the version to publish.",
            mandatory = True,
        ),
    },
)

# ---------------------------------------------------------------------------
# 发布目标
# ---------------------------------------------------------------------------

def _publish_impl(ctx):
    changelog_file = ctx.file.changelog

    allowed_version_types = [
        "alpha",
        "beta",
        "release",
    ]
    if ctx.attr.version_type not in allowed_version_types:
        fail("version_type must be one of %s" % allowed_version_types)

    # 开关与标签名的组合必须自洽，避免运行期静默跳过发布步骤
    if ctx.attr.auto_tag and not ctx.attr.git_tag_name:
        fail("auto_tag = True 时必须提供 git_tag_name")
    if ctx.attr.github_release:
        if not ctx.attr.git_tag_name:
            fail("github_release = True 时必须提供 git_tag_name（Release 必须绑定标签）")
        if not changelog_file:
            fail("github_release = True 时必须提供 changelog（用作发布说明）")

    # 所有发布项共用的参数
    args = []
    args += ["--token-secret-id", ctx.attr.token_secret_id]
    args += ["--project-id", ctx.attr.project_id]
    args += ["--version-id", ctx.attr.version_id]
    args += ["--version-type", ctx.attr.version_type]
    if changelog_file:
        args += ["--changelog", "@rlocation:" + changelog_file.short_path]
    for loader in ctx.attr.loaders:
        args += ["--loader", loader]
    for dependency_info in ctx.attr.deps:
        dependency = dependency_info[ModrinthDependencyInfo]
        args += ["--dependency", "--dependency-project-id", dependency.project_id]
        if dependency.version_id:
            args += ["--dependency-version-id", dependency.version_id]
        args += ["--dependency-type", dependency.dependency_type]

    # 每个发布项一组 --upload 参数，全部交给同一个上传进程依次上传
    runfiles_files = [changelog_file] if changelog_file else []
    release_assets = []
    for target in ctx.attr.entries:
        entry = target[PublishEntryInfo]
        args.append("--upload")
        args += ["--file", "@rlocation:" + entry.file.short_path]
        args += ["--file-name", entry.file_name]
        args += ["--version-name", entry.version_name]
        for game_version in entry.game_versions:
            args += ["--game-version", game_version]
        runfiles_files.append(entry.file)
        release_assets.append("@rlocation:" + entry.file.short_path)

    # GitHub Release 的发布说明
    release_notes = "@rlocation:" + changelog_file.short_path if changelog_file else ""

    # 注意：{ARGS} 等值写入的是带引号的 heredoc，其中的引号既无需也无法转义
    substitutions = {
        "{WORKSPACE_NAME}": ctx.workspace_name,
        "{EXEC_PATH}": "@rlocation:" + ctx.executable._modrinth_uploader_binary.short_path,
        "{ARGS}": "\n".join(args),
        "{GIT_TAG_NAME}": ctx.attr.git_tag_name if ctx.attr.git_tag_name else "",
        "{AUTO_TAG}": "1" if ctx.attr.auto_tag else "",
        "{GITHUB_RELEASE}": "1" if ctx.attr.github_release else "",
        "{RELEASE_NOTES_PATH}": release_notes,
        "{RELEASE_ASSETS}": "\n".join(release_assets),
        "{DISCUSSION_CATEGORY}": ctx.attr.github_discussion_category,
    }

    runfiles_files.append(ctx.file._rlocation_library)
    runfiles = ctx.runfiles(files = runfiles_files).merge(
        ctx.attr._modrinth_uploader_binary[DefaultInfo].default_runfiles,
    )

    output_script = ctx.actions.declare_file(ctx.attr.name + ".bash")
    ctx.actions.expand_template(
        output = output_script,
        template = ctx.file._publish_wrapper,
        substitutions = substitutions,
        is_executable = True,
    )
    runfiles = runfiles.merge(ctx.runfiles(files = [output_script]))

    if ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]):
        # Windows 上额外包一层 .bat：借 shell toolchain 启动上面那个 bash 脚本
        sh_toolchain = ctx.toolchains[_SH_TOOLCHAIN_TYPE]
        if not sh_toolchain or not sh_toolchain.path:
            fail("No suitable shell toolchain found")

        output_executable = ctx.actions.declare_file(ctx.attr.name + ".bat")
        ctx.actions.write(
            output = output_executable,
            content = "@\"%s\" -c 'PATH=/usr/local/bin:/usr/bin:/bin:/opt/bin:$PATH RUNFILES_MANIFEST_FILE=../%s.bat.runfiles_manifest ../%s'" % (sh_toolchain.path.strip(), ctx.attr.name, output_script.basename),
            is_executable = True,
        )
    else:
        output_executable = output_script

    return [DefaultInfo(
        runfiles = runfiles,
        executable = output_executable,
    )]

publish = rule(
    doc = "把一到多个版本发布出去：上传 Modrinth、打 Git 标签、创建 GitHub Release。",
    implementation = _publish_impl,
    executable = True,
    toolchains = [
        config_common.toolchain_type(_SH_TOOLCHAIN_TYPE, mandatory = False),
    ],
    attrs = {
        "token_secret_id": attr.string(
            doc = "The secret ID of the token.",
            mandatory = True,
        ),
        "project_id": attr.string(
            doc = "The ID of the project to upload to.",
            mandatory = True,
        ),
        "version_id": attr.string(
            doc = "The ID of the version to upload.",
            mandatory = True,
        ),
        "version_type": attr.string(
            doc = "The type of the version to upload. Can be one of alpha, beta, or release.",
            mandatory = True,
        ),
        "changelog": attr.label(
            doc = "The changelog file, shared by all entries. Also used as the GitHub Release notes.",
            allow_single_file = [".md"],
            mandatory = False,
        ),
        "loaders": attr.string_list(
            doc = "The loaders of the version to upload.",
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "The dependencies of the version to upload.",
            providers = [ModrinthDependencyInfo],
            mandatory = False,
        ),
        "entries": attr.label_list(
            doc = "待发布的版本列表，全部在同一个上传进程内依次上传。",
            providers = [PublishEntryInfo],
            mandatory = True,
        ),
        "git_tag_name": attr.string(
            doc = "整次发布的 Git 标签名，同时也是 GitHub Release 绑定的标签。为空则既不创建标签也不创建 Release。",
            mandatory = False,
        ),
        "auto_tag": attr.bool(
            doc = "是否创建并推送 git_tag_name 指定的标签；关闭后不会创建标签，但 github_release 仍可用该标签名（需已存在）。",
            default = DEFAULT_AUTO_TAG,
        ),
        "github_release": attr.bool(
            doc = "推送 Git 标签后是否用系统 gh CLI 创建 GitHub Release。发布说明取 changelog，附件为本目标的全部产物。",
            default = DEFAULT_GITHUB_RELEASE,
        ),
        "github_discussion_category": attr.string(
            doc = "GitHub Release 关联的 Discussion 分类名，为空则不创建 Discussion。",
            default = DEFAULT_GITHUB_DISCUSSION_CATEGORY,
        ),
        "_modrinth_uploader_binary": attr.label(
            default = "//rule/tools/modrinth_uploader",
            executable = True,
            cfg = "exec",
        ),
        "_publish_wrapper": attr.label(
            default = "//rule/tools/modrinth_uploader:publish_wrapper",
            allow_single_file = [".bash"],
        ),
        "_rlocation_library": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
            allow_single_file = [".bash"],
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
)

# ---------------------------------------------------------------------------
# 简化宏
# ---------------------------------------------------------------------------

def datapack_publish(
        name,
        pack_name,
        segments,
        pack_version,
        project_id,
        version_type = DEFAULT_VERSION_TYPE,
        changelog = DEFAULT_CHANGELOG,
        deps = None,
        auto_tag = DEFAULT_AUTO_TAG,
        github_release = DEFAULT_GITHUB_RELEASE,
        github_discussion_category = DEFAULT_GITHUB_DISCUSSION_CATEGORY):
    """创建数据包的发布配置。

    所有版本段会被聚合成单个目标：一次 `bazel run` 只启动一个上传进程，在其中
    依次上传全部版本段；全部成功之后创建并推送 Git 标签，随后用系统 `gh` CLI
    创建 GitHub Release（发布说明取 changelog，附件为各版本段的产物）。

    Args:
        name: 发布目标的名称
        pack_name: 数据包名称，用于推导版本名与 Git 标签名
        segments: 版本段列表，每项为 dict：
            - "range_name": 版本范围名
            - "game_versions": 该版本段支持的游戏版本列表
            对应产物为 `:<range_name>`，其文件名 `<pack>_v<version>_<range>.zip`
            同时决定 Modrinth 文件名/版本名与 Release 附件名
        pack_version: 数据包版本（必须符合 SemVer 规范）
        project_id: Modrinth 项目 ID
        version_type: 版本类型（alpha, beta, release）
        changelog: 更新日志文件，同时用作 GitHub Release 的发布说明
        deps: 依赖列表，默认包含本地化资源包
        auto_tag: 是否创建并推送 Git 标签；关闭后不碰标签，但仍可建 Release
        github_release: 是否创建 GitHub Release
        github_discussion_category: GitHub Release 关联的 Discussion 分类名
    """

    # 验证版本号是否符合 SemVer 规范
    validate_semver(pack_version, "数据包版本号")

    if deps == None:
        deps = [":localization_resource_pack"]

    # 每个版本段生成一个发布项，全部交给同一个发布目标。
    # 产物目标与文件名都由 datapack_config 生成，这里不再重复拼装命名。
    entries = []
    for segment in segments:
        range_name = segment["range_name"]
        entry_name = "%s_%s" % (name, range_name)
        publish_entry(
            name = entry_name,
            file = ":" + range_name,
            game_versions = segment["game_versions"],
        )
        entries.append(":" + entry_name)

    publish(
        name = name,
        changelog = changelog,
        entries = entries,
        github_discussion_category = github_discussion_category,
        github_release = github_release,
        # 标签名始终提供：auto_tag 只决定是否创建/推送，Release 仍需要它作锚点
        git_tag_name = "%s_v%s" % (pack_name, pack_version),
        auto_tag = auto_tag,
        loaders = ["datapack"],
        project_id = project_id,
        token_secret_id = "modrinth_token",
        version_id = pack_version,
        version_type = version_type,
        deps = deps,
    )
