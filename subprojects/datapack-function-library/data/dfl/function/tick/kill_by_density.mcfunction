## 实体密度过大时清除实体

# 检查实体密度分数并清除高密度区域实体
$execute as @e at @s \
    if score @s dfl_density matches $(num).. \
    run kill @e[distance=..10,type=!player,type=!minecraft:villager,tag=!need]
