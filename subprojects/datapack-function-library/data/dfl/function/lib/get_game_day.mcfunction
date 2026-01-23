## 获取游戏天数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 查询游戏天数并存储到计分板
execute store result score day dfl_scoreboard run time query day
