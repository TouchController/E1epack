# 测试 force_death_drops 函数
# 函数流程：关闭死亡不掉落 -> 杀死执行者 -> 重新开启死亡不掉落
# 依据：kill 未指定目标时以执行者为目标（wiki 命令/kill）
#       gamerule 的 result 为该规则执行后的数值，布尔 true 为 1、false 为 0

# 把规则重置为非目标值
gamerule minecraft:keep_inventory false

# 在出生点正上方生成测试实体
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_death_test"]}

# 以该实体为执行者运行被测函数
execute as @e[tag=dfl_death_test,limit=1] run function dfl:lib/force_death_drops

# 验证：执行者已死亡
execute unless entity @e[tag=dfl_death_test] run scoreboard players set killed testing 1
# 验证：keep_inventory 最终恢复为 true
execute store result score keep testing run gamerule minecraft:keep_inventory

execute if score killed testing matches 1 if score keep testing matches 1 run function dfl:test/pass
