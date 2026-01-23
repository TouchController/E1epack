## 传参并调用fill函数

# 添加临时记分板
scoreboard objectives add temp.chunk dummy
# 运行fill，传入pos
data modify storage replace_block:data temp.fill_chunk set from storage replace_block:data temp.find_chunk
function replace_block:fill/main
# 返回成败
execute if score dimension.not.found rb.return matches 1 run return fail
execute if score success temp.chunk matches 1 run return 1
execute if score success temp.chunk matches 0 run return fail
