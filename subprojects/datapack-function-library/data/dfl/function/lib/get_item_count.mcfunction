## 获取掉落物数

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 统计掉落物数量
execute store result score item dfl_scoreboard if entity @e[type=item]
