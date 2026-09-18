# 测试 non_player_entities 函数

summon minecraft:armor_stand ~ ~ ~ {Tags:["dfl_npe_test"]}

function dfl:lib/non_player_entities

execute if score other_entity dfl_scoreboard matches 1..1000 run function dfl:test/pass

# 清理
kill @e[tag=dfl_npe_test]
