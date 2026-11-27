## 获取当日时间

# 初始化记分板
function dfl:private/init_scoreboard
# 查询游戏时间并存储到计分板
execute store result score daytime dfl_scoreboard run time query minecraft:day
