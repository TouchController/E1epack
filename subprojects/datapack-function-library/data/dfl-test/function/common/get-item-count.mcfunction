# 测试 get_item_count 函数

summon minecraft:item ~ ~ ~ {Item:{id:"minecraft:stone"}}

function dfl:lib/get_item_count

execute if score item dfl_scoreboard matches 1.. run function dfl:test/pass

