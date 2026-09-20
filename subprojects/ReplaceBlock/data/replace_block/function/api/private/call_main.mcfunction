scoreboard objectives remove rb.debug
function replace_block:private/main/run
# 清理用于读取Pos的marker
kill @s
# 移除临时记分板
scoreboard objectives remove rb.tmp
scoreboard objectives remove rb.tmp.fill
scoreboard objectives remove rb.tmp.chunk_pos
scoreboard objectives remove rb.tmp.traversal_list
scoreboard objectives remove rb.tmp.traversal_dimension
scoreboard objectives remove rb.tmp.traversal_chunk
# 移除临时命令存储
data remove storage replace_block:data temp
data remove storage replace_block:data settings
# 如果main失败，filled_blocks不会被设置，这条命令fail
return run scoreboard players get filled_blocks rb.debug
