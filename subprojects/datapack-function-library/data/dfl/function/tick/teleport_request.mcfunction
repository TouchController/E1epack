## TPA 系统 - 玩家传送

# 初始化
scoreboard objectives add tpa trigger
scoreboard objectives add tpa_enable trigger
scoreboard objectives setdisplay list dfl_playerid
scoreboard players enable @a tpa

# 未启用tpa时允许启用
execute as @a unless score @s tpa_enable matches 1 \
    run scoreboard players enable @s tpa_enable

# 处理传送请求，遍历设置了tpa计分板的玩家
    # 对每个玩家，遍历并设置位置到tpa_enable玩家，判断id并tp
execute as @a[scores={tpa=1..}] \
    at @a[scores={tpa_enable=1}] \
    if score @s tpa = @p dfl_playerid \
    run tp @s @p
