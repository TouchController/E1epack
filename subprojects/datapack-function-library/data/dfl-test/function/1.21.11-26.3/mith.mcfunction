# 测试 mith 函数
# 函数效果：开启死亡不掉落、给予夜视与发光、清除黑暗

# 把规则重置为非目标值
gamerule minecraft:keep_inventory false

# 在出生点正上方生成测试实体，并先施加黑暗效果用于验证 effect clear
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_mith_test"]}
effect give @e[tag=dfl_mith_test,limit=1] minecraft:darkness 60 0

# 以该实体为执行者运行被测函数
execute as @e[tag=dfl_mith_test,limit=1] run function dfl:tick/mith

# 验证：keep_inventory 为 true
execute store result score keep testing run gamerule minecraft:keep_inventory
# 验证：获得夜视与发光
execute if data entity @e[tag=dfl_mith_test,limit=1] active_effects[{id:"minecraft:night_vision"}] run scoreboard players set has.nv testing 1
execute if data entity @e[tag=dfl_mith_test,limit=1] active_effects[{id:"minecraft:glowing"}] run scoreboard players set has.glowing testing 1
# 验证：黑暗已被清除
execute unless data entity @e[tag=dfl_mith_test,limit=1] active_effects[{id:"minecraft:darkness"}] run scoreboard players set no.darkness testing 1

execute if score keep testing matches 1 if score has.nv testing matches 1 if score has.glowing testing matches 1 if score no.darkness testing matches 1 run function dfl:test/pass

# 清理
kill @e[tag=dfl_mith_test]
