## 游戏时间获取函数

# 初始化记分板
function dfl:private/init_scoreboard

# 获取游戏时间
execute store result score gametime dfl_scoreboard \
    run time query time
