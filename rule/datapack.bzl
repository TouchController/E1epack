"""Minecraft 数据包构建规则。

此模块定义了用于构建 Minecraft 数据包的 Bazel 宏和规则，包括：
- 函数文件的扩展和处理
- JSON 文件的压缩处理
- 对话系统的处理
- 数据包的打包和部署
- 开发服务器的启动配置
- 通用的数据包配置模式
- Modrinth 上传配置的简化
- SemVer 版本号验证

主要提供 datapack 宏，用于定义完整的数据包构建流程。
"""


load("@//rule:process_json.bzl", "process_json")
load("@//rule:process_mcfunction.bzl", "process_mcfunction")
load("@//rule:upload_modrinth.bzl", "modrinth_dependency", "upload_modrinth")
load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_pkg//pkg:mappings.bzl", "pkg_filegroup", "pkg_files")
load("@rules_pkg//pkg:zip.bzl", "pkg_zip")
load(":minecraft_versions.bzl", "ALL_MINECRAFT_VERSIONS")

def _is_valid_semver(version):
    """验证版本号是否符合语义化版本控制（SemVer）规范。
    
    根据 SemVer 2.0.0 规范验证版本号格式：
    - 标准格式：X.Y.Z（主版本号.次版本号.修订号）
    - 支持先行版本号：X.Y.Z-prerelease
    - 支持版本编译信息：X.Y.Z+build 或 X.Y.Z-prerelease+build
    
    Args:
        version: 要验证的版本号字符串
        
    Returns:
        如果版本号有效则返回 True，否则返回 False
    """
    if not version or type(version) != "string":
        return False
    
    # 移除可能的 "v" 前缀
    if version.startswith("v"):
        version = version[1:]
    
    # 分离版本编译信息（+号后的部分）
    build_parts = version.split("+")
    if len(build_parts) > 2:
        return False
    
    core_and_prerelease = build_parts[0]
    build_metadata = build_parts[1] if len(build_parts) == 2 else None
    
    # 验证版本编译信息格式
    if build_metadata:
        if not _is_valid_identifier_sequence(build_metadata):
            return False
    
    # 分离先行版本号（-号后的部分）
    prerelease_parts = core_and_prerelease.split("-")
    if len(prerelease_parts) > 2:
        return False
    
    version_core = prerelease_parts[0]
    prerelease = prerelease_parts[1] if len(prerelease_parts) == 2 else None
    
    # 验证先行版本号格式
    if prerelease:
        if not _is_valid_prerelease(prerelease):
            return False
    
    # 验证核心版本号格式 X.Y.Z
    core_parts = version_core.split(".")
    if len(core_parts) != 3:
        return False
    
    for part in core_parts:
        if not _is_valid_numeric_identifier(part):
            return False
    
    return True

def _is_valid_numeric_identifier(identifier):
    """验证数字标识符是否有效。
    
    Args:
        identifier: 要验证的标识符字符串
        
    Returns:
        如果标识符有效则返回 True，否则返回 False
    """
    if not identifier:
        return False
    
    # 检查是否只包含数字
    for i in range(len(identifier)):
        char = identifier[i]
        if char < "0" or char > "9":
            return False
    
    # 检查前导零：只有 "0" 本身是有效的，其他以 0 开头的多位数字无效
    if len(identifier) > 1 and identifier[0] == "0":
        return False
    
    return True

def _is_valid_prerelease(prerelease):
    """验证先行版本号是否有效。
    
    Args:
        prerelease: 要验证的先行版本号字符串
        
    Returns:
        如果先行版本号有效则返回 True，否则返回 False
    """
    if not prerelease:
        return False
    
    # 先行版本号由点分隔的标识符组成
    identifiers = prerelease.split(".")
    if not identifiers:
        return False
    
    for identifier in identifiers:
        if not _is_valid_prerelease_identifier(identifier):
            return False
    
    return True

def _is_valid_prerelease_identifier(identifier):
    """验证先行版本号标识符是否有效。
    
    Args:
        identifier: 要验证的标识符字符串
        
    Returns:
        如果标识符有效则返回 True，否则返回 False
    """
    if not identifier:
        return False
    
    # 检查是否只包含允许的字符 [0-9A-Za-z-]
    is_numeric = True
    for i in range(len(identifier)):
        char = identifier[i]
        if not ((char >= "0" and char <= "9") or 
                (char >= "A" and char <= "Z") or 
                (char >= "a" and char <= "z") or 
                char == "-"):
            return False
        if not (char >= "0" and char <= "9"):
            is_numeric = False
    
    # 如果是纯数字标识符，检查前导零
    if is_numeric and len(identifier) > 1 and identifier[0] == "0":
        return False
    
    return True

def _is_valid_identifier_sequence(sequence):
    """验证标识符序列是否有效（用于版本编译信息）。
    
    Args:
        sequence: 要验证的标识符序列字符串
        
    Returns:
        如果序列有效则返回 True，否则返回 False
    """
    if not sequence:
        return False
    
    identifiers = sequence.split(".")
    if not identifiers:
        return False
    
    for identifier in identifiers:
        if not identifier:
            return False
        # 检查是否只包含允许的字符 [0-9A-Za-z-]
        for i in range(len(identifier)):
            char = identifier[i]
            if not ((char >= "0" and char <= "9") or 
                    (char >= "A" and char <= "Z") or 
                    (char >= "a" and char <= "z") or 
                    char == "-"):
                return False
    
    return True

def validate_semver(version, context = "版本号"):
    """验证并确保版本号符合 SemVer 规范。
    
    如果版本号不符合规范，会调用 fail() 终止构建。
    
    Args:
        version: 要验证的版本号字符串
        context: 上下文描述，用于错误消息
    """
    if not _is_valid_semver(version):
        fail("%s '%s' 不符合语义化版本控制（SemVer 2.0.0）规范。\n" % (context, version) +
             "有效的版本号格式示例：\n" +
             "  - 1.0.0\n" +
             "  - 2.1.3\n" +
             "  - 1.0.0-alpha\n" +
             "  - 1.0.0-alpha.1\n" +
             "  - 1.0.0-0.3.7\n" +
             "  - 1.0.0+20130313144700\n" +
             "  - 1.0.0-beta+exp.sha.5114f85\n" +
              "请参考项目根目录的 SemVer.md 文档了解详细规范。")

def _is_valid_pack_id(pack_id):
    """验证 pack_id 是否符合 Minecraft 命名空间 ID 规范。
    
    根据 Minecraft 命名空间 ID 规范验证 pack_id 格式：
    - 只能包含小写字母、数字、下划线、连字符和点
    - 不能以点、连字符或下划线开头或结尾
    - 不能包含连续的点
    - 长度在 1 到 255 个字符之间
    
    Args:
        pack_id: 要验证的命名空间 ID 字符串
        
    Returns:
        如果 pack_id 有效则返回 True，否则返回 False
    """
    if not pack_id or type(pack_id) != "string":
        return False
    
    # 检查长度
    if len(pack_id) < 1 or len(pack_id) > 255:
        return False
    
    # 检查首尾字符
    first_char = pack_id[0]
    last_char = pack_id[-1]
    if first_char in "._-" or last_char in "._-":
        return False
    
    # 检查是否只包含允许的字符
    for i in range(len(pack_id)):
        char = pack_id[i]
        if not ((char >= "a" and char <= "z") or 
                (char >= "0" and char <= "9") or 
                char == "_" or char == "-" or char == "."):
            return False
    
    # 检查连续的点
    if ".." in pack_id:
        return False
    
    return True

def validate_pack_id(pack_id, context = "pack_id"):
    """验证并确保 pack_id 符合 Minecraft 命名空间 ID 规范。
    
    如果 pack_id 不符合规范，会调用 fail() 终止构建。
    
    Args:
        pack_id: 要验证的命名空间 ID 字符串
        context: 上下文描述，用于错误消息
    """
    if not _is_valid_pack_id(pack_id):
        fail("%s '%s' 不符合 Minecraft 命名空间 ID 规范。\n" % (context, pack_id) +
             "有效的命名空间 ID 格式要求：\n" +
             "  - 只能包含小写字母、数字、下划线、连字符和点\n" +
             "  - 不能以点、连字符或下划线开头或结尾\n" +
             "  - 不能包含连续的点\n" +
             "  - 长度在 1 到 255 个字符之间\n" +
             "有效的 pack_id 示例：\n" +
             "  - stone_disappearance\n" +
             "  - auto_lucky_block\n" +
             "  - dfl\n" +
             "  - unif.logger")



def minecraft_versions_range(start_version, end_version = None):
    """根据起始和结束版本获取版本列表。

    Args:
        start_version: 起始版本（包含）
        end_version: 结束版本（包含），如果为 None 则取到最新版本

    Returns:
        包含指定范围内所有版本的列表

    Example:
        minecraft_versions_range("1.20.3", "1.21.5")
        # 返回从 1.20.3 到 1.21.5 的所有版本

        minecraft_versions_range("1.20.3")
        # 返回从 1.20.3 到最新版本的所有版本
    """
    if start_version not in ALL_MINECRAFT_VERSIONS:
        fail("起始版本 '%s' 不在支持的版本列表中" % start_version)

    start_index = ALL_MINECRAFT_VERSIONS.index(start_version)

    if end_version == None:
        # 如果没有指定结束版本，则取到最新版本
        return ALL_MINECRAFT_VERSIONS[start_index:]

    if end_version not in ALL_MINECRAFT_VERSIONS:
        fail("结束版本 '%s' 不在支持的版本列表中" % end_version)

    end_index = ALL_MINECRAFT_VERSIONS.index(end_version)

    if start_index > end_index:
        fail("起始版本 '%s' 不能晚于结束版本 '%s'" % (start_version, end_version))

    return ALL_MINECRAFT_VERSIONS[start_index:end_index + 1]

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

def _datapack_impl(
        name,
        visibility,
        pack_id,
        functions,
        function_tags,
        deps,
        minecraft_version,
        namespace_json,
        minecraft_json):
    # 默认使用版本列表中的最新版本
    if not minecraft_version:
        minecraft_version = ALL_MINECRAFT_VERSIONS[-1]


    process_mcfunction(
        name = name + "_pack_function",
        visibility = visibility,
        pack_id = pack_id,
        srcs = functions,
        deps = deps,
    )

    process_json(
        name = name + "_namespace_json_compress",
        srcs = namespace_json,
    )

    pkg_files(
        name = name + "_pack_namespace_json",
        visibility = visibility,
        srcs = [":%s_namespace_json_compress" % name],
        prefix = "data",
        strip_prefix = "data",
    )

    process_json(
        name = name + "_minecraft_json_compress",
        srcs = minecraft_json,
    )

    pkg_files(
        name = name + "_pack_minecraft_json",
        visibility = visibility,
        srcs = [":%s_minecraft_json_compress" % name],
        prefix = "data",
        strip_prefix = "data",
    )

    process_json(
        name = name + "_function_tag_legacy_compress",
        srcs = function_tags,
    )

    pkg_files(
        name = name + "_function_tag_legacy",
        visibility = visibility,
        srcs = [":%s_function_tag_legacy_compress" % name],
        prefix = "data/minecraft/tags/functions",
        strip_prefix = "data/minecraft/tags/function",
    )

    pkg_filegroup(
        name = name + "_components",
        visibility = visibility,
        srcs = [
            ":%s_pack_function" % name,
            ":%s_pack_namespace_json" % name,
            ":%s_pack_minecraft_json" % name,
            ":%s_function_tag_legacy" % name,
        ],
    )

    pkg_zip(
        name = name,
        visibility = visibility,
        srcs = [
            ":%s_components" % name,
            "//template:mcmeta",
        ] + deps,
    )

    java_binary(
        name = name + "_server",
        visibility = visibility,
        srcs = [],
        data = [
            ":" + name,
            "//game:ops_json",
        ],
        jvm_flags = [
            "-Ddev.launch.version=%s" % minecraft_version,
            "-Ddev.launch.type=server",
            "-Ddev.launch.mainClass=net.minecraft.server.Main",
            "-Xmx4G",
            "-Ddev.launch.copyFiles=" +
            "$(rlocationpath //%s:%s):world/datapacks/%s.zip," % (native.package_name(), name, name) +
            "$(rlocationpath //game:ops_json):ops.json",
        ],
        main_class = "top.fifthlight.fabazel.devlaunchwrapper.DevLaunchWrapper",
        runtime_deps = [
            "//game:server",
            "//rule/dev_launch_wrapper",
            "@minecraft//:%s_server_libraries" % minecraft_version,
        ],
    )

# buildifier: disable=unused-variable
datapack = macro(
    attrs = {
        "pack_id": attr.string(configurable = False, mandatory = True),
        "functions": attr.label_list(default = []),
        "function_tags": attr.label_list(default = []),
        "namespace_json": attr.label_list(default = []),
        "minecraft_json": attr.label_list(default = []),
        "deps": attr.label_list(default = []),
        # 留空则在实现中自动选取最新版本
        "minecraft_version": attr.string(configurable = False, default = ""),
    },
    implementation = _datapack_impl,
)

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
        name = "upload_modrinth",
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
            if version not in _ALL_MINECRAFT_VERSIONS:
                fail("游戏版本 '%s' 不在支持的版本列表中" % version)

    # 确定目标名称，默认使用当前包名称
    if target_name == None:
        target_name = native.package_name().split("/")[-1]

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

    # 创建数据包
    datapack(
        name = target_name,
        pack_id = pack_id,
        functions = native.glob(
            include = func_config["functions_include"],
            exclude = func_config["functions_exclude"],
            allow_empty = True,
        ),
        namespace_json = native.glob(["data/%s/**/*.json" % pack_id], allow_empty = True),
        minecraft_json = native.glob(["data/minecraft/**/*.json"], allow_empty = True),
        function_tags = native.glob(["data/minecraft/tags/function/*.json"], allow_empty = True),
        **kwargs
    )

    # 创建服务器别名
    native.alias(
        name = "server",
        actual = ":%s_server" % target_name,
    )

    # 创建 Modrinth 上传配置（如果提供了项目 ID）
    if modrinth_project_id:
        datapack_modrinth_upload(
            name = target_name,
            datapack_target = ":" + target_name,
            pack_version = pack_version,
            project_id = modrinth_project_id,
            game_versions = game_versions,
            version_type = version_type,
            changelog = changelog,
            deps = dep_labels,
        )
