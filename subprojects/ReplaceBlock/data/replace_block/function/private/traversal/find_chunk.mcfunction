## 所在区块坐标计算函数

# 添加临时记分板
scoreboard objectives add rb.tmp.find_chunk dummy
# 存储玩家位置
execute store result score x rb.tmp.find_chunk run data get entity @s Pos[0]
execute store result score y rb.tmp.find_chunk run data get entity @s Pos[1]
execute store result score z rb.tmp.find_chunk run data get entity @s Pos[2]

# 计算玩家所在的chunk
scoreboard players set c16 rb.tmp.find_chunk 16
scoreboard players operation chunk_x rb.tmp.find_chunk = x rb.tmp.find_chunk
scoreboard players operation chunk_z rb.tmp.find_chunk = z rb.tmp.find_chunk
scoreboard players operation chunk_x rb.tmp.find_chunk /= c16 rb.tmp.find_chunk
scoreboard players operation chunk_z rb.tmp.find_chunk /= c16 rb.tmp.find_chunk
scoreboard players operation chunk_x rb.tmp.find_chunk *= c16 rb.tmp.find_chunk
scoreboard players operation chunk_z rb.tmp.find_chunk *= c16 rb.tmp.find_chunk
execute store result storage replace_block:data temp.find_chunk.a_x int 1 run scoreboard players get chunk_x rb.tmp.find_chunk
execute store result storage replace_block:data temp.find_chunk.a_z int 1 run scoreboard players get chunk_z rb.tmp.find_chunk
scoreboard players add chunk_x rb.tmp.find_chunk 15
scoreboard players add chunk_z rb.tmp.find_chunk 15
execute store result storage replace_block:data temp.find_chunk.b_x int 1 run scoreboard players get chunk_x rb.tmp.find_chunk
execute store result storage replace_block:data temp.find_chunk.b_z int 1 run scoreboard players get chunk_z rb.tmp.find_chunk

# 移除临时记分板
scoreboard objectives remove rb.tmp.find_chunk
