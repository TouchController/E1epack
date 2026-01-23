## 获取非玩家实体数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 统计非玩家实体数量并存储到计分板
execute store result score other_entity dfl_scoreboard \
    if entity @e[type=!player]
