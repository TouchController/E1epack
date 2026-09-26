# 此函数读取当前实体的位置并写入计分板

scoreboard objectives add dfl_entity_pos_x dummy
scoreboard objectives add dfl_entity_pos_y dummy
scoreboard objectives add dfl_entity_pos_z dummy

# x轴坐标
execute store result score @s dfl_entity_pos_x \
    run data get entity @s Pos[0]

# y轴坐标
execute store result score @s dfl_entity_pos_y \
    run data get entity @s Pos[1]

# z轴坐标
execute store result score @s dfl_entity_pos_z \
    run data get entity @s Pos[2]
