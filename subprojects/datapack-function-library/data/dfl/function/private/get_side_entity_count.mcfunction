## 统计实体某一侧的实体数量，按视角
# 传参：x/y/z 为该侧的坐标偏移（±1024），side 为方位名
# 结果：@s 在 dfl_<side>_entity 计分板上的分数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 基于视角朝向，以指定的偏移为中心计算球形范围内的实体数量
$execute rotated as @s \
    positioned ^$(x) ^$(y) ^$(z) \
    store result score @s dfl_$(side)_entity \
    if entity @e[distance=0..1024]
