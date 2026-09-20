scoreboard objectives remove rb.tmp.fill
scoreboard objectives remove rb.tmp.traversal_list
scoreboard objectives remove rb.tmp.traversal_dimension
# 添加临时记分板
scoreboard objectives add rb.tmp.fill dummy
scoreboard objectives add rb.tmp.traversal_list dummy
scoreboard objectives add rb.tmp.traversal_dimension dummy

# 读取维度列表条目数
execute store result score dimensions_count rb.tmp.traversal_dimension run \
    data get storage replace_block:data settings.dimensions

# 添加遍历维度列表的计数器
scoreboard players set i rb.tmp.traversal_dimension 0

function replace_block:private/fill/traversal/traversal_dimension
execute if score dimension.not.found rb.tmp matches 1 run \
    function #unif.logger:logger/v1/debug \
    {"msg":'要fill的维度不存在替换配置',"namespace":"ReplaceBlock"}
execute if score dimension.not.found rb.tmp matches 1 run \
    return fail

# 读取方块列表条目数
execute store result score replace_pairs rb.tmp.traversal_list run \
    data get storage replace_block:data settings.replace_pairs

# 添加遍历方块列表的计数记分板
scoreboard players set i rb.tmp.traversal_list 0
# 遍历方块列表
function replace_block:private/fill/traversal/traversal_list

# 读取success_threshold
execute store result score success_threshold rb.tmp.fill run \
    data get storage replace_block:data settings.success_threshold
# 判断成败
execute if score filled_blocks rb.debug >= success_threshold rb.tmp.fill run \
    return 1
execute if score filled_blocks rb.debug < success_threshold rb.tmp.fill run \
    return fail
