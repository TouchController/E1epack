# 测试 apply_debuffs 函数
# 函数给执行者施加 9 种效果：slowness、mining_fatigue、nausea、darkness、hunger、
#                                weakness、poison、unluck、trial_omen

# 在出生点正上方生成测试实体
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_debuff_test"]}

# 以该实体为执行者运行被测函数
execute as @e[tag=dfl_debuff_test,limit=1] run function dfl:tick/apply_debuffs

# 逐项核对 9 种效果
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:slowness"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:mining_fatigue"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:nausea"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:darkness"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:hunger"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:weakness"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:poison"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:unluck"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_debuff_test,limit=1] active_effects[{id:"minecraft:trial_omen"}] run scoreboard players add fx testing 1

execute if score fx testing matches 9 run function dfl:test/pass

# 清理
kill @e[tag=dfl_debuff_test]
