## 获取掉落物数

# 初始化记分板
function dfl:private/init_scoreboard

# 统计掉落物数量
execute store result score item dfl_scoreboard if entity @e[type=item]
