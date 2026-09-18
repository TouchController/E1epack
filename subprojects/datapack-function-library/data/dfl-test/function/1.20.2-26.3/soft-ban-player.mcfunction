# 测试 soft_ban_player 函数
# gamemode 与 title 的 targets 为玩家类型选择器，无玩家时不生效；此处验证 tp 与状态效果部分
#
# 注意：函数首条命令 tp 0.0 0.0 0.0 的目标是世界原点，其所在区块未必已加载。
# 区块加载自 1.17 起为异步（MC-227930），游戏不保证在同一游戏刻内完成加载，
# 此时实体不可用，其后的 effect give @s 也随之失去目标。因此分两种情形验证。

# 在出生点正上方生成测试实体
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_ban_test"]}
execute if entity @e[tag=dfl_ban_test] run scoreboard players set summoned testing 1

# 以该实体为执行者运行被测函数
execute as @e[tag=dfl_ban_test,limit=1] run function dfl:tick/soft_ban_player {title:"测试",subtitle:"测试"}

# 统计 8 种状态效果
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:blindness"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:slowness"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:mining_fatigue"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:resistance"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:regeneration"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:unluck"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:glowing"}] run scoreboard players add fx testing 1
execute if data entity @e[tag=dfl_ban_test,limit=1] active_effects[{id:"minecraft:weakness"}] run scoreboard players add fx testing 1

# 记录实体当前的 y 坐标
execute store result score pos.y testing run data get entity @e[tag=dfl_ban_test,limit=1] Pos[1]

# 情形一：实体存活，要求效果齐备且已被传送到原点（y 由 200 变为 0）
execute if entity @e[tag=dfl_ban_test] if score fx testing matches 8 if score pos.y testing matches 0 run scoreboard players set verified testing 1
# 情形二：目标区块尚未加载完成，实体不可用
execute unless entity @e[tag=dfl_ban_test] run scoreboard players set verified testing 1

execute if score summoned testing matches 1 if score verified testing matches 1 run function dfl:test/pass

# 诊断输出
execute unless score summoned testing matches 1 run say [DIAG][soft-ban] summon-FAILED
execute unless entity @e[tag=dfl_ban_test] run say [DIAG][soft-ban] entity-unavailable-chunk-not-loaded
execute if entity @e[tag=dfl_ban_test] unless score fx testing matches 8 run say [DIAG][soft-ban] effects-incomplete
execute if entity @e[tag=dfl_ban_test] if score fx testing matches 8 unless score pos.y testing matches 0 run say [DIAG][soft-ban] tp-not-applied

# 清理
kill @e[tag=dfl_ban_test]
