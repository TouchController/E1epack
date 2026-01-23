## TPA 系统 - 玩家传送

# 初始化
scoreboard objectives add tpa trigger
scoreboard objectives add tpa_enable trigger
scoreboard objectives setdisplay list dfl_playerid
scoreboard players enable @a tpa

# 未启用tpa时允许启用
execute as @a unless score @s tpa_enable matches 1 \
    run scoreboard players enable @s tpa_enable

# 处理随机一个玩家tpa_enable
execute as @a[scores={tpa=1..}] \
    at @a[scores={tpa_enable=1}] \
    if score @s tpa = @p tpa \
    run tp @s @p
