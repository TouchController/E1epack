## 向特定方向步进一个区块
# 返回1表示替换结束了，fail表示需要继续遍历

# 当前方向的步数-1
scoreboard players remove step rb.tmp 1
# x/z坐标+/-16，移动到下一个区块
$scoreboard players $(op) $(axis).a rb.tmp.chunk_pos 16
$scoreboard players $(op) $(axis).b rb.tmp.chunk_pos 16

# 坐标写入nbt，后续传给宏函数
execute store result storage replace_block:data temp.fill_chunk.a_x int 1 run \
    scoreboard players get x.a rb.tmp.chunk_pos
execute store result storage replace_block:data temp.fill_chunk.a_z int 1 run \
    scoreboard players get z.a rb.tmp.chunk_pos
execute store result storage replace_block:data temp.fill_chunk.b_x int 1 run \
    scoreboard players get x.b rb.tmp.chunk_pos
execute store result storage replace_block:data temp.fill_chunk.b_z int 1 run \
    scoreboard players get z.b rb.tmp.chunk_pos

# 未加载则退出
execute store success score child_traversal.chunk_loaded rb.tmp run \
    function replace_block:private/main/if_loaded with storage replace_block:data temp.fill_chunk
$execute if score child_traversal.chunk_loaded rb.tmp matches 0 run \
    function #unif.logger:logger/v1/warn \
    {"msg":'遍历遇到了未加载区块，当前轴 $(axis)，操作 $(op)',"namespace":"ReplaceBlock"}
execute if score child_traversal.chunk_loaded rb.tmp matches 0 run \
    return fail

# 填充，成功退出
execute if function replace_block:private/fill/main run \
    return 1
# 这里不检测dimension.not.found，因为main/run已经在dimension.not.found时return了

# 当前方向步数耗尽，退出，上层会换向
execute if score step rb.tmp matches 0 run return fail
# 递归调用并传出返回值
$return run function replace_block:private/traversal/next_chunk {op:"$(op)",axis:"$(axis)"}
