"""Minecraft 数据包构建规则。

此模块定义了用于构建 Minecraft 数据包的 Bazel 宏和规则，包括：
- 数据包的打包和部署
- 开发服务器的启动配置
- 通用的数据包配置模式
- Modrinth 上传配置的简化

主要提供 datapack 宏，用于定义完整的数据包构建流程。
"""

load("@//rule:command_replacer.bzl", "command_replacer")
load("@//rule:merge_tags.bzl", "merge_function_tags")
load("@//rule:process_json.bzl", "process_json")
load("@//rule:process_mcfunction.bzl", "process_mcfunction", "validate_dep_compatibility")
load("@//rule:upload_modrinth.bzl", "modrinth_dependency")
load("@//rule:validation.bzl", "validate_pack_id", "validate_semver")
load("@//rule:version.bzl", "minecraft_versions_range", "version_segments")
load("@//rule:modrinth.bzl", "datapack_modrinth_upload")
load("@//rule:test_system.bzl", "SERVER_JVM_FLAGS", "SERVER_MAIN_CLASS", "setup_tests")
load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_pkg//pkg:mappings.bzl", "pkg_filegroup", "pkg_files")
load("@rules_pkg//pkg:zip.bzl", "pkg_zip")
load(":minecraft_versions.bzl", "ALL_MINECRAFT_VERSIONS")

def datapack_functions(pack_id):
    """生成数据包函数文件的 glob 模式。

    Args:
        pack_id: 数据包 ID

    Returns:
        包含基础函数和扩展函数的配置字典
    """
    return {
        "functions_include": [
            "data/%s/function/**/*.mcfunction" % pack_id,
            "data/%s/functions/**/*.mcfunction" % pack_id,
        ],
        "functions_exclude": [],
        "functions_expand_pattern": [],
    }

def standard_localization_dependency():
    """获取标准的本地化资源包依赖配置。

    Returns:
        本地化依赖的配置字典
    """
    return {
        "name": "localization_resource_pack",
        "dependency_type": "required",
        "project_id": "3S0b1XES",
    }

def _segment_deps(deps, seg_index):
    """将依赖列表中的命名空间目标替换为对应版本段的变体。

    仅对不同子项目的 pack_id 目标追加 _segment_<index> 后缀。
    """
    result = []
    for d in deps:
        s = str(d)
        if "//subprojects/" in s:
            result.append(s + "_segment_" + str(seg_index))
        else:
            result.append(s)
    return result

def _datapack_impl(
        name,
        deps,
        minecraft_version,
        mappings,
        seg_index = 0,
        seg_count = 1,
        func_target = None,
        ns_json_target = None,
        ns_tags_target = None,
        mc_json_target = None,
        mc_tags_target = None):
    """为单个版本段创建数据包 pipeline（替换 + 打包）。"""
    if not minecraft_version:
        minecraft_version = ALL_MINECRAFT_VERSIONS[-1]
    if not all([func_target, ns_json_target, ns_tags_target, mc_json_target, mc_tags_target]):
        fail("_datapack_impl requires all *_target parameters")
    ns_tags_target = list(ns_tags_target)
    mc_tags_target = list(mc_tags_target)

    if mappings:
        command_replacer(
            name = name + "_functions",
            src = func_target,
            mappings = mappings,
        )
        effective_func = ":" + name + "_functions"
        effective_deps = _segment_deps(deps, seg_index)
    else:
        effective_func = func_target
        effective_deps = deps

    pkg_filegroup(
        name = name + "_components",
        srcs = [effective_func, ns_json_target] + ns_tags_target + [mc_json_target] + mc_tags_target,
    )
    pkg_zip(
        name = name,
        srcs = [":" + name + "_components", "//template:mcmeta"] + effective_deps,
    )

    if seg_index == seg_count - 1:
        java_binary(
            name = name + "_server",
            srcs = [],
            data = [
                ":" + name,
                "//game:ops_json",
            ],
            jvm_flags = [
                "-Ddev.launch.version=%s" % minecraft_version,
                "-Ddev.launch.mainClass=net.minecraft.server.Main",
            ] + SERVER_JVM_FLAGS + [
                "-Ddev.launch.copyFiles=" +
                "$(rlocationpath //%s:%s):world/datapacks/%s.zip," % (native.package_name(), name, name) +
                "$(rlocationpath //game:ops_json):ops.json",
            ],
            main_class = SERVER_MAIN_CLASS,
            runtime_deps = [
                "//game:server_" + minecraft_version.replace(".", "_"),
                "//rule/tools/dev_launch_wrapper",
                "@minecraft//:%s_server_libraries" % minecraft_version,
            ],
        )


def complete_datapack_config(
        pack_id,
        pack_version,
        target_name = None,
        game_versions = None,
        modrinth_project_id = None,
        changelog = "NEWS.md",
        version_type = "release",
        modrinth_deps = [],
        include_localization_dependency = True,
        test_ignore_errors_from = [],
        **kwargs):
    """完整的数据包配置宏，包含所有常用设置。

    这个宏会生成完整的数据包配置，包括：
    - 数据包规则
    - 服务器别名
    - Modrinth 上传配置（可选）

    Args:
        pack_id: 命名空间 ID
        pack_version: 数据包版本（必须符合 SemVer 规范）
        target_name: 主要目标名称，默认为当前包名称
        game_versions: 支持的游戏版本列表
        modrinth_project_id: Modrinth 项目 ID
        changelog: 更新日志，默认为 "NEWS.md"
        version_type: 版本类型 (release, beta, alpha)
        modrinth_deps: Modrinth 依赖字典列表
        include_localization_dependency: 是否自动包含本地化资源包作为依赖
        test_ignore_errors_from: 测试时忽略来自指定命名空间的加载错误
        **kwargs: 传递给 datapack 规则的其他参数
    """

    # 验证版本号是否符合 SemVer 规范
    validate_semver(pack_version, "数据包版本号")

    # 验证 pack_id 是否符合 Minecraft 命名空间 ID 规范
    validate_pack_id(pack_id, "pack_id")

    # 验证 version_type 是否有效
    if version_type not in ["release", "beta", "alpha"]:
        fail("version_type 必须是 'release', 'beta' 或 'alpha'，但提供了 '%s'" % version_type)

    # 验证 target_name（如果提供）
    if target_name != None:
        if not target_name or type(target_name) != "string":
            fail("target_name 必须是非空字符串")

        # 简单的目标名称验证：只允许字母、数字、下划线、连字符和点
        for i in range(len(target_name)):
            char = target_name[i]
            if not ((char >= "a" and char <= "z") or
                    (char >= "A" and char <= "Z") or
                    (char >= "0" and char <= "9") or
                    char == "_" or char == "-" or char == "."):
                fail("target_name 包含无效字符 '%s'，只能包含字母、数字、下划线、连字符和点" % char)

    # 验证 game_versions（如果提供）
    if game_versions != None:
        if type(game_versions) != "list":
            fail("game_versions 必须是列表")
        if len(game_versions) == 0:
            fail("game_versions 不能为空列表")

        # 检查每个版本是否在支持的版本列表中
        for version in game_versions:
            if version not in ALL_MINECRAFT_VERSIONS:
                fail("游戏版本 '%s' 不在支持的版本列表中" % version)

    # 确定目标名称，默认使用当前包名称
    if target_name == None:
        target_name = native.package_name().split("/")[-1]
    if target_name == pack_id:
        fail("target_name '%s' 与 pack_id 相同，会导致目标名冲突，请设置不同的 target_name" % target_name)

    # 设置默认游戏版本
    if game_versions == None:
        game_versions = minecraft_versions_range("1.20")

    # 验证 modrinth_project_id（如果提供）
    if modrinth_project_id != None:
        if not modrinth_project_id or type(modrinth_project_id) != "string":
            fail("modrinth_project_id 必须是非空字符串")

        # 检查长度
        if len(modrinth_project_id) < 1 or len(modrinth_project_id) > 64:
            fail("modrinth_project_id 长度必须在 1 到 64 个字符之间")

        # 检查是否只包含允许的字符：字母、数字、下划线、连字符
        for i in range(len(modrinth_project_id)):
            char = modrinth_project_id[i]
            if not ((char >= "a" and char <= "z") or
                    (char >= "A" and char <= "Z") or
                    (char >= "0" and char <= "9") or
                    char == "_" or char == "-"):
                fail("modrinth_project_id 包含无效字符 '%s'，只能包含字母、数字、下划线和连字符" % char)

    # 获取函数文件配置
    func_config = datapack_functions(pack_id)

    # 准备 Modrinth 依赖列表
    effective_modrinth_deps = list(modrinth_deps)
    if include_localization_dependency:
        effective_modrinth_deps.append(standard_localization_dependency())

    # 创建 Modrinth 依赖
    dep_labels = []
    for dep in effective_modrinth_deps:
        modrinth_dependency(**dep)
        dep_labels.append(":" + dep["name"])

    deps = kwargs.pop("deps", [])

    # 拆分 namespace JSON
    all_ns_json = native.glob(["data/%s/**/*.json" % pack_id], allow_empty = True)
    ns_tag_pattern = "data/%s/tags/function/" % pack_id
    namespace_function_tags = [f for f in all_ns_json if ns_tag_pattern in f]
    namespace_json = [f for f in all_ns_json if ns_tag_pattern not in f]

    functions_srcs = native.glob(
        include = func_config["functions_include"],
        exclude = func_config["functions_exclude"],
        allow_empty = True,
    )
    mc_json = native.glob(
        ["data/minecraft/**/*.json"],
        exclude = ["data/minecraft/tags/function/*.json"],
        allow_empty = True,
    )
    mc_tags = native.glob(["data/minecraft/tags/function/*.json"], allow_empty = True)

    # Export raw mc_tags for dependents to merge
    native.filegroup(
        name = pack_id + "_mc_tags",
        srcs = mc_tags,
        visibility = ["//visibility:public"],
    )

    # 按版本段为每个段创建独立的 datapack pipeline

    extra_mc_version = kwargs.pop("minecraft_version", "")
    if kwargs:
        fail("complete_datapack_config received unexpected kwargs: %s" % list(kwargs.keys()))

    # 共享组件：所有段共用
    segments = version_segments(game_versions)
    total_segments = len(segments)

    process_mcfunction(
        name = "process_functions",
        pack_id = pack_id,
        srcs = functions_srcs,
        deps = deps,
        game_versions = game_versions,
        segment_count = total_segments,
    )
    func_target = ":process_functions"

    validate_dep_compatibility(
        name = "validate_dependencies",
        pack_id = pack_id,
        caller_game_versions = game_versions,
        deps = [d for d in deps if "//subprojects/" in str(d)],
    )

    process_json(name = "compress_namespace_json", srcs = namespace_json)
    pkg_files(
        name = "package_namespace_json",
        srcs = [":compress_namespace_json"],
        prefix = "data",
        strip_prefix = "data",
    )
    ns_json_target = ":package_namespace_json"

    process_json(name = "compress_namespace_function_tags", srcs = namespace_function_tags)
    pkg_files(
        name = "package_namespace_function_tags_singular",
        srcs = [":compress_namespace_function_tags"],
        prefix = "data/" + pack_id + "/tags/function",
        strip_prefix = "data/" + pack_id + "/tags/function",
    )
    pkg_files(
        name = "package_namespace_function_tags_plural",
        srcs = [":compress_namespace_function_tags"],
        prefix = "data/" + pack_id + "/tags/functions",
        strip_prefix = "data/" + pack_id + "/tags/function",
    )
    ns_tags_target = [
        ":package_namespace_function_tags_singular",
        ":package_namespace_function_tags_plural",
    ]

    process_json(name = "compress_minecraft_json", srcs = mc_json)
    pkg_files(
        name = "package_minecraft_json",
        srcs = [":compress_minecraft_json"],
        prefix = "data",
        strip_prefix = "data",
    )
    mc_json_target = ":package_minecraft_json"

    # Merge mc_tags from dependencies
    _dep_mc_tags = []
    for dep in deps:
        dep_str = str(dep)
        if "//subprojects/" in dep_str:
            _dep_mc_tags.append(dep_str + "_mc_tags")

    if _dep_mc_tags:
        merge_function_tags(
            name = "merge_mc_tags",
            srcs = mc_tags + _dep_mc_tags,
        )
        pkg_files(
            name = "merge_mc_tag_files_singular",
            srcs = [":merge_mc_tags"],
            prefix = "data/minecraft/tags/function",
            strip_prefix = "data/minecraft/tags/function",
        )
        pkg_files(
            name = "merge_mc_tag_files_plural",
            srcs = [":merge_mc_tags"],
            prefix = "data/minecraft/tags/functions",
            strip_prefix = "data/minecraft/tags/function",
        )
        mc_tags_target = [
            ":merge_mc_tag_files_singular",
            ":merge_mc_tag_files_plural",
        ]
    else:
        process_json(name = "compress_minecraft_function_tags", srcs = mc_tags)
        pkg_files(
            name = "package_minecraft_function_tags_singular",
            srcs = [":compress_minecraft_function_tags"],
            prefix = "data/minecraft/tags/function",
            strip_prefix = "data/minecraft/tags/function",
        )
        pkg_files(
            name = "package_minecraft_function_tags_plural",
            srcs = [":compress_minecraft_function_tags"],
            prefix = "data/minecraft/tags/functions",
            strip_prefix = "data/minecraft/tags/function",
        )
        mc_tags_target = [
            ":package_minecraft_function_tags_singular",
            ":package_minecraft_function_tags_plural",
        ]

    for i, seg in enumerate(segments):
        range_name, seg_versions, mappings = seg
        seg_name = range_name

        _datapack_impl(
            name = seg_name,
            deps = deps,
            minecraft_version = extra_mc_version,
            mappings = mappings,
            seg_index = i,
            seg_count = total_segments,
            func_target = func_target,
            ns_json_target = ns_json_target,
            ns_tags_target = ns_tags_target,
            mc_json_target = mc_json_target,
            mc_tags_target = mc_tags_target,
        )

        native.genrule(
            name = "release_" + range_name,
            srcs = [":" + seg_name],
            outs = ["release/%s_v%s_%s.zip" % (target_name, pack_version, range_name)],
            cmd = "cp $< $@",
        )

        if modrinth_project_id:
            datapack_modrinth_upload(
                name = target_name,
                datapack_target = ":" + seg_name,
                pack_version = pack_version,
                project_id = modrinth_project_id,
                game_versions = seg_versions,
                version_type = version_type,
                changelog = changelog,
                deps = dep_labels,
                auto_tag = (i == total_segments - 1),
            )

    # 向后兼容别名
    latest_seg_name = segments[-1][0]
    native.filegroup(
        name = target_name,
        srcs = [":release_" + seg[0] for seg in segments],
    )
    native.alias(
        name = "server",
        actual = ":%s_server" % latest_seg_name,
    )

    # 命名空间依赖目标
    _namespace_deps = [d for d in deps if "//subprojects/" in str(d)]
    pkg_filegroup(
        name = pack_id,
        srcs = [func_target, ns_json_target] + ns_tags_target + _namespace_deps,
        visibility = ["//visibility:public"],
    )

    for i, seg in enumerate(segments):
        range_name, _, mappings = seg
        seg_func_target = func_target if not mappings else ":" + range_name + "_functions"
        seg_srcs = [seg_func_target, ns_json_target] + ns_tags_target + _segment_deps(_namespace_deps, i)
        pkg_filegroup(
            name = pack_id + "_segment_%d" % i,
            srcs = seg_srcs,
            visibility = ["//visibility:public"],
        )

    # --- Test 系统 ---
    # 从依赖标签自动传播 test_ignore_errors_from
    _all_ignore = [ns for ns in test_ignore_errors_from if type(ns) == "string"]
    for d in deps:
        dep_str = str(d)
        if dep_str.startswith("//") and ":" in dep_str:
            ns = dep_str.rsplit(":", 1)[1]
            if ns not in _all_ignore:
                _all_ignore.append(ns)
    setup_tests(
        pack_id = pack_id,
        target_name = target_name,
        game_versions = game_versions,
        segments = segments,
        ignore_error_ns = _all_ignore,
    )
