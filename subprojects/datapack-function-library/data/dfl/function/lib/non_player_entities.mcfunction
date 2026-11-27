## 获取非玩家实体数

# 初始化记分板
function dfl:private/init_scoreboard

# 统计非玩家实体数量并存储到计分板
execute store result score other_entity dfl_scoreboard \
    if entity @e[type=!player]
