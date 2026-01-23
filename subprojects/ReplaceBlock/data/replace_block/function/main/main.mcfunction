## 主执行函数

# 计算玩家所在的chunk，输出到nbt
function replace_block:traversal/find_chunk
# chunk未加载报错
execute unless function replace_block:parent/if_loaded run \
    function #unif.logger:logger/v1/error \
    {"msg":'find_chunk输出坐标在if_loaded检测失败',"namespace":"ReplaceBlock"}
execute unless function replace_block:parent/if_loaded run \
    return fail
# fill在原位置成功
execute if function replace_block:parent/parent_fill run return run \
    function #unif.logger:logger/v1/info \
    {"msg":'fill在原位置成功',"namespace":"ReplaceBlock"}
execute if score dimension.not.found rb.return matches 1 run return fail

# 添加临时记分板
scoreboard objectives add temp.chunk.child dummy
# 初始化n
scoreboard players set n temp.chunk 0
# 加载设置
execute store result score n rb.settings run \
    data get storage replace_block:data settings.search_range
# 存储chunk坐标至临时命令存储
execute store result score x.a temp.chunk run \
    data get storage replace_block:data temp.find_chunk.a_x
execute store result score z.a temp.chunk run \
    data get storage replace_block:data temp.find_chunk.a_z
execute store result score x.b temp.chunk run \
    data get storage replace_block:data temp.find_chunk.b_x
execute store result score z.b temp.chunk run \
    data get storage replace_block:data temp.find_chunk.b_z

# 遍历并存储n
execute store result score n rb.debug run \
    function replace_block:traversal/traversal_chunk
# 移除临时记分板
scoreboard objectives remove temp.chunk
scoreboard objectives remove temp.chunk.child
# 移除临时命令存储
data remove storage replace_block:data temp
