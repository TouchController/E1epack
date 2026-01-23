## 无权限玩家自杀

# 初始化记分板
scoreboard objectives add kill trigger
scoreboard players enable @a kill
# 杀死玩家
execute as @a \
    if score @s kill matches 1 \
    run kill
# 重置记分板
scoreboard players set @a kill 0
