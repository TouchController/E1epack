## 物品数量检测通用函数

# 创建计分板目标
$scoreboard objectives add dfl_$(name)_num dummy
# 检测玩家物品数量并存储到计分板
$execute as @a store result score @s dfl_$(name)_num \
    run clear @s $(name) 0
