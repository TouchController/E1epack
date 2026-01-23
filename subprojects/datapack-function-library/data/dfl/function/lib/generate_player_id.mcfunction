## 玩家唯一ID分配系统

# 初始化记分板目标
scoreboard objectives add dfl_scoreboard dummy "DFL"
scoreboard objectives add dfl_playerid dummy

# 为未分配ID的玩家设置初始值
execute as @a unless score @s dfl_playerid matches 1.. \
    run scoreboard players set @s dfl_playerid 0

# 递增全局ID计数器
execute as @r[scores={dfl_playerid=0}] \
    run scoreboard players add playerid_temp dfl_scoreboard 1

# 为玩家分配新ID
execute as @r[scores={dfl_playerid=0}] \
    run scoreboard players operation @s dfl_playerid = playerid_temp dfl_scoreboard
