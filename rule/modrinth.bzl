"""Modrinth 上传配置的简化宏。

此模块提供 datapack_modrinth_upload 宏，封装了 Modrinth 上传的常用配置模式。
"""

load("@//rule:upload_modrinth.bzl", "upload_modrinth")
load("@//rule:validation.bzl", "validate_semver")
load("@//rule:version.bzl", "minecraft_versions_range")

def datapack_modrinth_upload(
        name,
        datapack_target,
        pack_version,
        project_id,
        file_name_template = None,
        version_name_template = None,
        game_versions = None,
        version_type = "release",
        changelog = "NEWS.md",
        deps = None,
        auto_tag = True):
    """创建 Modrinth 上传配置的简化宏。

    Args:
        name: 上传目标的名称
        datapack_target: 数据包目标（如 ":my-datapack"）
        pack_version: 数据包版本（必须符合 SemVer 规范）
        project_id: Modrinth 项目 ID
        file_name_template: 文件名模板，默认为 "{name}_v{version}_{game_range}.zip"
        version_name_template: 版本名模板，默认为 "{name}_v{version}_{game_range}"
        game_versions: 支持的游戏版本列表，默认为从 1.20 开始的所有版本
        version_type: 版本类型（alpha, beta, release），默认为 release
        changelog: 更新日志文件，默认为 "NEWS.md"
        deps: 依赖列表，默认包含本地化资源包
        auto_tag: 是否在上传前自动创建并推送 Git 标签，默认为 True
    """

    # 验证版本号是否符合 SemVer 规范
    validate_semver(pack_version, "数据包版本号")
    if game_versions == None:
        game_versions = minecraft_versions_range("1.20")

    if deps == None:
        deps = [":localization_resource_pack"]

    # 确定游戏版本范围字符串，使用首尾版本
    game_range = "%s-%s" % (game_versions[0], game_versions[-1])

    # 设置默认模板
    if file_name_template == None:
        file_name_template = "%s_v%s_%s.zip" % (name, pack_version, game_range)
    else:
        file_name_template = file_name_template.format(
            name = name,
            version = pack_version,
            game_range = game_range,
        )

    if version_name_template == None:
        version_name_template = "%s_v%s_%s" % (name, pack_version, game_range)
    else:
        version_name_template = version_name_template.format(
            name = name,
            version = pack_version,
            game_range = game_range,
        )

    # 生成 Git 标签名称
    git_tag_name = "%s_v%s" % (name, pack_version) if auto_tag else None

    upload_modrinth(
        name = name + "_" + game_range + "_modrinth",
        changelog = changelog,
        file = datapack_target,
        file_name = file_name_template,
        game_versions = game_versions,
        loaders = ["datapack"],
        project_id = project_id,
        token_secret_id = "modrinth_token",
        version_id = pack_version,
        version_name = version_name_template,
        version_type = version_type,
        deps = deps,
        git_tag_name = git_tag_name,
    )
