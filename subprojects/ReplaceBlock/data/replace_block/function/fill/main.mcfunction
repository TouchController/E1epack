# 添加临时记分板
scoreboard objectives add temp.fill dummy
# 读取方块列表条目数
execute store result score replace_pairs temp.fill run \
    data get storage replace_block:data settings.replace_pairs
scoreboard players remove replace_pairs temp.fill 1
# 读取当前维度
data modify storage replace_block:data temp.fill_chunk.Dimension set from entity @s Dimension
function replace_block:fill/get_dimension with storage replace_block:data temp.fill_chunk
execute if score dimension.not.found rb.return matches 1 run return run \
    function #unif.logger:logger/v1/debug \
    {"msg":'维度不存在',"namespace":"ReplaceBlock"}

# 添加遍历方块列表的计数记分板
scoreboard objectives add temp.fill.list dummy
scoreboard players set i temp.fill.list 0
# 遍历方块列表
function replace_block:fill/traversal_list

# 读取success_threshold
execute store result score success_threshold temp.fill run \
    data get storage replace_block:data settings.success_threshold
# 判断成败
execute if score filled_blocks temp.fill >= success_threshold temp.fill run \
    scoreboard players set success temp.chunk 1
execute if score filled_blocks temp.fill < success_threshold temp.fill run \
    scoreboard players set success temp.chunk 0

# 移除临时记分板
scoreboard objectives remove temp.fill
scoreboard objectives remove temp.fill.list


# 通过success temp.chunk返回成败
# 路径temp.fill_chunk中存储了坐标
