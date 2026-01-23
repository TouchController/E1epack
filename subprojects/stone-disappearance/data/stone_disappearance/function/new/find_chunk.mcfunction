## 所在区块坐标计算函数

# 添加临时记分板
scoreboard objectives add find_chunk dummy
# 存储玩家位置
execute store result score x find_chunk run data get entity @s Pos[0]
execute store result score y find_chunk run data get entity @s Pos[1]
execute store result score z find_chunk run data get entity @s Pos[2]

# 计算玩家所在的chunk
scoreboard players set c16 find_chunk 16
scoreboard players operation chunk_x find_chunk = x find_chunk
scoreboard players operation chunk_z find_chunk = z find_chunk
scoreboard players operation chunk_x find_chunk /= c16 find_chunk
scoreboard players operation chunk_z find_chunk /= c16 find_chunk
scoreboard players operation chunk_x find_chunk *= c16 find_chunk
scoreboard players operation chunk_z find_chunk *= c16 find_chunk
execute store result storage stone_disappearance:data temp.find_chunk.a_x int 1 run scoreboard players get chunk_x find_chunk
execute store result storage stone_disappearance:data temp.find_chunk.a_z int 1 run scoreboard players get chunk_z find_chunk
scoreboard players add chunk_x find_chunk 15
scoreboard players add chunk_z find_chunk 15
execute store result storage stone_disappearance:data temp.find_chunk.b_x int 1 run scoreboard players get chunk_x find_chunk
execute store result storage stone_disappearance:data temp.find_chunk.b_z int 1 run scoreboard players get chunk_z find_chunk

# 移除临时记分板
scoreboard objectives remove find_chunk
