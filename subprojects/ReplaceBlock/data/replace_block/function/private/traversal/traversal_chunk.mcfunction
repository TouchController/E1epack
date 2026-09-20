## 主区块遍历函数

# 检测ring是否到达设定上限
execute if score ring rb.debug >= search_range rb.tmp run \
    function #unif.logger:logger/v1/debug \
    {"msg":'遍历范围达到设定上限',"namespace":"ReplaceBlock"}
execute if score ring rb.debug >= search_range rb.tmp run return 1
# n+1
scoreboard players add ring rb.debug 1
# 计算2n
scoreboard players operation ring.2 rb.tmp = ring rb.debug
scoreboard players operation ring.2 rb.tmp += ring rb.debug

# 用于存储next返回值的记分板
scoreboard objectives remove rb.tmp.traversal_chunk
scoreboard objectives add rb.tmp.traversal_chunk dummy

# x+1
scoreboard players set step rb.tmp 1
    # 方向：x+
execute store success score finish rb.tmp.traversal_chunk run \
    function replace_block:private/traversal/next_chunk {op:"add",axis:"x"}
execute if score finish rb.tmp.traversal_chunk matches 1 run return 1

# z-(2n-1)
scoreboard players operation step rb.tmp = ring.2 rb.tmp
scoreboard players remove step rb.tmp 1
    # 方向：z-
execute store success score finish rb.tmp.traversal_chunk run \
    function replace_block:private/traversal/next_chunk {op:"remove",axis:"z"}
execute if score finish rb.tmp.traversal_chunk matches 1 run return 1

# x-2n
scoreboard players operation step rb.tmp = ring.2 rb.tmp
    # 方向：x-
execute store success score finish rb.tmp.traversal_chunk run \
    function replace_block:private/traversal/next_chunk {op:"remove",axis:"x"}
execute if score finish rb.tmp.traversal_chunk matches 1 run return 1

# z+2n
scoreboard players operation step rb.tmp = ring.2 rb.tmp
    # 方向：z+
execute store success score finish rb.tmp.traversal_chunk run \
    function replace_block:private/traversal/next_chunk {op:"add",axis:"z"}
execute if score finish rb.tmp.traversal_chunk matches 1 run return 1

# x+2n
scoreboard players operation step rb.tmp = ring.2 rb.tmp
    # 方向：x+
execute store success score finish rb.tmp.traversal_chunk run \
    function replace_block:private/traversal/next_chunk {op:"add",axis:"x"}
execute if score finish rb.tmp.traversal_chunk matches 1 run return 1

# 递归调用
function replace_block:private/traversal/traversal_chunk
