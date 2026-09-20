## 主执行函数

# 重置rb.debug
scoreboard objectives remove rb.debug
scoreboard objectives add rb.debug dummy
# 创建rb.tmp
scoreboard objectives add rb.tmp dummy

# 计算玩家所在的chunk，输出到nbt
function replace_block:private/traversal/find_chunk
# chunk未加载报错
execute unless function replace_block:private/main/if_loaded run \
    function #unif.logger:logger/v1/warn \
    {"msg":'实体所在区块未加载',"namespace":"ReplaceBlock"}
execute unless function replace_block:private/main/if_loaded run \
    return 1
# fill在原位置成功，提前返回
execute if function replace_block:private/main/call_fill run \
    return 1
# 没有配置当前维度，退出
execute if score dimension.not.found rb.tmp matches 1 run return 1

# 添加临时记分板
scoreboard objectives add rb.tmp.chunk_pos dummy
# 初始化ring
scoreboard players set ring rb.debug 0
# 加载设置
execute store result score search_range rb.tmp run \
    data get storage replace_block:data settings.search_range
# 存储chunk坐标至临时命令存储
execute store result score x.a rb.tmp.chunk_pos run \
    data get storage replace_block:data temp.find_chunk.a_x
execute store result score z.a rb.tmp.chunk_pos run \
    data get storage replace_block:data temp.find_chunk.a_z
execute store result score x.b rb.tmp.chunk_pos run \
    data get storage replace_block:data temp.find_chunk.b_x
execute store result score z.b rb.tmp.chunk_pos run \
    data get storage replace_block:data temp.find_chunk.b_z

# 遍历并替换
function replace_block:private/traversal/traversal_chunk
