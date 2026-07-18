"""数据包验证规则。

此模块提供 Minecraft 数据包构建所需的验证函数，包括：
- SemVer 2.0.0 版本号验证
- Minecraft 命名空间 ID (pack_id) 验证
"""

def _str_in_set(s, allowed):
    """检查字符串所有字符是否都在 allowed 集合中。"""
    for c in s.elems():
        if c not in allowed:
            return False
    return True

def _is_valid_numeric_identifier(identifier):
    """验证数字标识符是否有效。"""
    if not identifier:
        return False
    if not _str_in_set(identifier, "0123456789"):
        return False
    if len(identifier) > 1 and identifier[0] == "0":
        return False
    return True

def _is_valid_prerelease_identifier(identifier):
    """验证先行版本号标识符是否有效。"""
    if not identifier:
        return False
    is_numeric = True
    for c in identifier.elems():
        if not ((c >= "0" and c <= "9") or (c >= "A" and c <= "Z") or (c >= "a" and c <= "z") or c == "-"):
            return False
        if c < "0" or c > "9":
            is_numeric = False
    if is_numeric and len(identifier) > 1 and identifier[0] == "0":
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

def _is_valid_identifier_sequence(sequence):
    """验证标识符序列是否有效（用于版本编译信息）。"""
    if not sequence:
        return False
    for id in sequence.split("."):
        if not id:
            return False
        for c in id.elems():
            if not ((c >= "0" and c <= "9") or (c >= "A" and c <= "Z") or (c >= "a" and c <= "z") or c == "-"):
                return False
    return True

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

    # 检查是否只包含允许的字符 [a-z0-9_-.]
    for c in pack_id.elems():
        if not ((c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_" or c == "-" or c == "."):
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
