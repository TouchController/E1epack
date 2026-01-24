"""Minecraft 版本列表。

此文件包含所有支持的 Minecraft 版本列表，按发布顺序排列。
该列表用于 minecraft_versions_range() 函数和其他需要版本范围的功能。
"""

ALL_MINECRAFT_VERSIONS = [
    "1.13",
    "1.13.1",
    "1.13.2",
    "1.14",
    "1.14.1",
    "1.14.2",
    "1.14.3",
    "1.14.4",
    "1.15",
    "1.15.1",
    "1.15.2",
    "1.16",
    "1.16.1",
    "1.16.2",
    "1.16.3",
    "1.16.4",
    "1.16.5",
    "1.17",
    "1.17.1",
    "1.18",
    "1.18.1",
    "1.18.2",
    "1.19",
    "1.19.1",
    "1.19.2",
    "1.19.3",
    "1.19.4",
    "1.20",
    "1.20.1",
    "1.20.2",
    "1.20.3",
    "1.20.4",
    "1.20.5",
    "1.20.6",
    "1.21",
    "1.21.1",
    "1.21.2",
    "1.21.3",
    "1.21.4",
    "1.21.5",
    "1.21.6",
    "1.21.7",
    "1.21.8",
    "1.21.9",
    "1.21.10",
]

def _parse_version(version_str):
    """将版本字符串解析为整数列表以便比较。"""
    parts = version_str.split(".")
    result = []
    for part in parts:
        result.append(int(part))
    return result

def _compare_versions(v1, v2):
    """比较两个版本字符串，返回负数如果 v1 < v2，0 如果相等，正数如果 v1 > v2。"""
    parts1 = _parse_version(v1)
    parts2 = _parse_version(v2)
    # 使两个列表长度相同，用0填充较短的部分
    max_len = max(len(parts1), len(parts2))
    parts1.extend([0] * (max_len - len(parts1)))
    parts2.extend([0] * (max_len - len(parts2)))
    for i in range(max_len):
        if parts1[i] != parts2[i]:
            return parts1[i] - parts2[i]
    return 0

def _validate_versions():
    """验证版本列表是否按正确顺序排列。"""
    for i in range(len(ALL_MINECRAFT_VERSIONS) - 1):
        current = ALL_MINECRAFT_VERSIONS[i]
        next_version = ALL_MINECRAFT_VERSIONS[i + 1]
        if _compare_versions(current, next_version) >= 0:
            fail("版本列表未按正确顺序排列：'%s' 在 '%s' 之后" % (current, next_version))

_validate_versions()

def latest_minecraft_version():
    """获取最新的 Minecraft 版本。"""
    return ALL_MINECRAFT_VERSIONS[-1]