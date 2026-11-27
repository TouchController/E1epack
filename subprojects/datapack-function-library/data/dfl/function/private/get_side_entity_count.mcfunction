## 统计实体某一侧（左/右/上/下/前/后）的实体数量
# 传参：x/y/z 为该侧的局部坐标向量（±1024），side 为方位名（left/right/up/down/front/back）
# 结果：@s 在 dfl_<side>_entity 计分板上的分数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 沿指定方位偏移一个大数距离，再用同样半径的球形范围近似该侧的半空间
$execute rotated as @s \
    positioned ^$(x) ^$(y) ^$(z) \
    store result score @s dfl_$(side)_entity \
    if entity @e[distance=0..1024]
