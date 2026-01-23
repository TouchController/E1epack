$execute as $(selector) at @s run function replace_block:main/main
data remove storage replace_block:data settings
scoreboard objectives remove temp.fill
scoreboard objectives remove temp.fill.list
# 移除临时记分板
scoreboard objectives remove temp.chunk
scoreboard objectives remove temp.chunk.child
# 移除临时命令存储
data remove storage replace_block:data temp
