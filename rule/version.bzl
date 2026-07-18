"""Minecraft 版本范围与版本段拆分。

此模块提供版本范围获取和版本段拆分功能，包括：
- minecraft_versions_range: 获取版本列表
- version_segments: 按命令语法边界拆分版本段
- 数据包函数和本地化配置辅助函数
"""

load(":minecraft_versions.bzl", "ALL_MINECRAFT_VERSIONS")

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

# 命令替换规则：boundary 版本及其之后使用新语法，之前需要旧版替换
COMMAND_BOUNDARIES = [
    ("1.21.11", "//rule:data/gamerule_mapping.json"),
    ("26.1", "//rule:data/time_query_mapping.json"),
]

def _version_idx(v):
    if v not in ALL_MINECRAFT_VERSIONS:
        fail("COMMAND_BOUNDARIES 中的版本 '%s' 不在支持的版本列表中" % v)
    return ALL_MINECRAFT_VERSIONS.index(v)

def version_segments(game_versions):
    """按所有命令替换边界拆分版本列表，每段确定需要的 mapping 文件。

    Args:
      game_versions: 游戏版本列表

    Returns:
        [(range_name, versions, mapping_labels), ...]
        mapping_labels 为空时表示该段无需替换（最新语法）。
    """
    boundaries = sorted(COMMAND_BOUNDARIES, key = lambda bv: _version_idx(bv[0]))
    segments = []
    remaining = list(game_versions)

    for boundary_ver, _ in boundaries:
        boundary_idx = _version_idx(boundary_ver)
        pre = [v for v in remaining if _version_idx(v) < boundary_idx]
        remaining = [v for v in remaining if _version_idx(v) >= boundary_idx]
        if pre:
            range_name = pre[0] if pre[0] == pre[-1] else "%s-%s" % (pre[0], pre[-1])
            mappings = [
                m
                for bv, m in boundaries
                if _version_idx(bv) > _version_idx(pre[-1])
            ]
            segments.append((range_name, pre, mappings))

    if remaining:
        range_name = remaining[0] if remaining[0] == remaining[-1] else "%s-%s" % (remaining[0], remaining[-1])
        segments.append((range_name, remaining, []))

    return segments
