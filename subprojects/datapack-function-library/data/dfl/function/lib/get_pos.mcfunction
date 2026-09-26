# 此函数用于获取玩家当前位置至计分板
# 需要传参：execute的子命令：as 玩家（也许可以获取任意实体的，但没试过）

scoreboard objectives add player_x dummy
scoreboard objectives add player_y dummy
scoreboard objectives add player_z dummy

# x轴坐标
execute \
    at @s \
    store result score @s player_x \
    run data get entity @s Pos[0]

# y轴坐标
execute \
    at @s \
    store result score @s player_y \
    run data get entity @s Pos[1]

# z轴坐标
execute \
    at @s \
    store result score @s player_z \
    run data get entity @s Pos[2]
