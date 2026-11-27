## 获取游戏天数

# 初始化记分板
function dfl:private/init_scoreboard

# 查询游戏天数并存储到计分板
execute store result score day dfl_scoreboard run time query minecraft:day repetition
