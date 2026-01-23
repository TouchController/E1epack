## 玩家数量统计函数
# 初始化记分板目标
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 统计在线玩家数量并存储到记分板
execute store result score players dfl_scoreboard if entity @a
