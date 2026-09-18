# 测试 get_entity_count 函数

# 在出生点正上方纵向生成 2 个实体，避开地表的自然生成实体
summon minecraft:creeper ~ 200 ~ {Tags:["dfl_ec_test"]}
summon minecraft:creeper ~ 201 ~ {Tags:["dfl_ec_test"]}

function dfl:lib/get_entity_count

execute if score entity dfl_scoreboard matches 2..500 run function dfl:test/pass

# 清理
kill @e[tag=dfl_ec_test]
