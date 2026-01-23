## TNT 实体密度过大时清除 TNT

# 创建计分板目标用于存储 TNT 密度
scoreboard objectives add dfl_tntdensity dummy
# 计算每个实体周围 5 格内的 TNT 数量
execute as @e at @s \
    store result score @s dfl_tntdensity \
    if entity @e[distance=..5,type=minecraft:tnt]
# 清除密度超过阈值的 TNT
$execute as @e at @s \
    if score @s dfl_tntdensity matches $(num).. \
    run kill @e[distance=..5,type=minecraft:tnt]
