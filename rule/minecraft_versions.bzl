"""Minecraft 版本管理模块。

此模块定义了支持的 Minecraft 版本列表和相关工具函数。
版本列表按发布顺序排列，用于数据包版本兼容性检查。

注意：此列表需要定期更新以包含新的 Minecraft 版本。
"""

# 完整的 Minecraft 版本列表（按发布顺序排列）
_ALL_MINECRAFT_VERSIONS = [
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

def get_all_minecraft_versions():
    """获取所有支持的 Minecraft 版本列表。
    
    Returns:
        按发布顺序排列的 Minecraft 版本字符串列表
    """
    return _ALL_MINECRAFT_VERSIONS

def get_latest_minecraft_version():
    """获取最新的 Minecraft 版本。
    
    Returns:
        最新的 Minecraft 版本字符串
    """
    return _ALL_MINECRAFT_VERSIONS[-1]

def is_version_supported(version):
    """检查指定的 Minecraft 版本是否受支持。
    
    Args:
        version: 要检查的版本字符串
        
    Returns:
        如果版本受支持则返回 True，否则返回 False
    """
    return version in _ALL_MINECRAFT_VERSIONS