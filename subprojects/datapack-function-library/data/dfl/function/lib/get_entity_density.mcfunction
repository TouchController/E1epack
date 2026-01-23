## 实体密度计算函数
# 计算每个实体周围10格范围内的实体数量

# 初始化计分板
scoreboard objectives add dfl_density dummy

# 计算实体密度
execute as @e at @s \
    store result score @s dfl_density \
    if entity @e[distance=..10]
