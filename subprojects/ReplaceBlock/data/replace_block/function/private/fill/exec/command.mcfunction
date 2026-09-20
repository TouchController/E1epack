## fill执行函数

scoreboard objectives add rb.tmp.fill_command dummy

$execute store result score count rb.tmp.fill_command run \
    fill $(a_x) $(min_y) $(a_z) $(b_x) $(max_y) $(b_z) $(replace_with) replace $(target_block)
# 将数量累加，不存在会自动创建filled_blocks，且值等于count
scoreboard players operation filled_blocks rb.debug += count rb.tmp.fill_command

scoreboard objectives remove rb.tmp.fill_command
