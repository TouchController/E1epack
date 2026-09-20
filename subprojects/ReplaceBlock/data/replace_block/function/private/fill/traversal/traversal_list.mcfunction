# 读取当前方块对下标
execute store result storage replace_block:data temp.fill_chunk.pair_index int 1 run \
    scoreboard players get i rb.tmp.traversal_list
# 调用command_with_data并传入下标
function replace_block:private/fill/exec/command_with_data with storage replace_block:data temp.fill_chunk

# i++
scoreboard players add i rb.tmp.traversal_list 1
# 判断是否遍历完成
execute if score i rb.tmp.traversal_list >= replace_pairs rb.tmp.traversal_list run return 1
# 递归
function replace_block:private/fill/traversal/traversal_list
