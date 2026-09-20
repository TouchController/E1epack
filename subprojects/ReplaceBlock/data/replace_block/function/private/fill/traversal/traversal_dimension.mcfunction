# 读取当前维度下标
execute store result storage replace_block:data temp.fill_chunk.dimension_index int 1 run \
    scoreboard players get i rb.tmp.traversal_dimension
# 调用test_dimension并传入下标
execute store success score success rb.tmp.traversal_dimension run \
    function replace_block:private/fill/traversal/test_dimension with storage replace_block:data temp.fill_chunk
# 找到了，读数据
execute if score success rb.tmp.traversal_dimension matches 1 run \
    function replace_block:private/fill/traversal/get_dimension with storage replace_block:data temp.fill_chunk
execute if score success rb.tmp.traversal_dimension matches 1 run \
    return 1

# i++
scoreboard players add i rb.tmp.traversal_dimension 1
# 遍历完成仍找不到
execute if score i rb.tmp.traversal_dimension >= dimensions_count rb.tmp.traversal_dimension run \
    scoreboard players set dimension.not.found rb.tmp 1
execute if score i rb.tmp.traversal_dimension >= dimensions_count rb.tmp.traversal_dimension run \
    return 1

# 递归
function replace_block:private/fill/traversal/traversal_dimension
