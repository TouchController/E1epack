## 获取当日时间

# 初始化记分板
scoreboard objectives add dfl_scoreboard dummy "DFL"
# 查询游戏时间并存储到计分板
execute store result score daytime dfl_scoreboard run time query daytime
