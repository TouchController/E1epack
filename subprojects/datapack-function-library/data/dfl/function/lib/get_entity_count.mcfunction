## 实体数量统计工具函数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 统计所有实体数量并存储到计分板
execute store result score entity dfl_scoreboard if entity @e
