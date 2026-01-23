## fill执行函数

$execute if dimension $(dimension) \
    store result score count temp.fill run \
    fill $(a_x) $(min_y) $(a_z) $(b_x) $(max_y) $(b_z) $(replace_with) replace $(target_block)
# 将数量累加
scoreboard players operation filled_blocks temp.fill += count temp.fill
