## 递归fill x-16

# 已遍历次数-1
scoreboard players remove n temp.chunk.child 1
# x坐标-16
scoreboard players remove x.a temp.chunk 16
scoreboard players remove x.b temp.chunk 16

# 坐标写入nbt
execute store result storage stone_disappearance:data temp.fill_chunk.a_x int 1 run \
    scoreboard players get x.a temp.chunk
execute store result storage stone_disappearance:data temp.fill_chunk.a_z int 1 run \
    scoreboard players get z.a temp.chunk
execute store result storage stone_disappearance:data temp.fill_chunk.b_x int 1 run \
    scoreboard players get x.b temp.chunk
execute store result storage stone_disappearance:data temp.fill_chunk.b_z int 1 run \
    scoreboard players get z.b temp.chunk

# 未加载则退出
execute store success score loaded temp.chunk.child run function stone_disappearance:new/child_if_loaded with storage stone_disappearance:data temp.fill_chunk
execute if score loaded temp.chunk.child matches 0 run \
    function #unif.logger:logger/v1/warn \
    {"msg":'loaded在递归x-中检测失败',"namespace":"Stone-Disappearance"}
execute if score loaded temp.chunk.child matches 0 run \
    scoreboard players set success temp.chunk 1
execute if score loaded temp.chunk.child matches 0 run return 1

# 填充
execute store success score success temp.chunk run \
    function stone_disappearance:new/fill with storage stone_disappearance:data temp.fill_chunk
# 成功后退出
execute if score success temp.chunk matches 1 run return 1
execute if score n temp.chunk.child matches 0 run return fail
# 递归调用
function stone_disappearance:new/child_traversal_chunk/x-
