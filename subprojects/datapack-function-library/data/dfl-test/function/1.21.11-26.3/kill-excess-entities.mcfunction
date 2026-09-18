# 测试 kill_excess_entities 函数
# 函数统计非玩家、无 need 标签的实体数，达到阈值时清除这些实体
# 阈值为「不少于」，故世界中存在其他实体时本测试仍然成立
# 实体只在纵向排列，不产生横向偏移

scoreboard objectives remove dfl_scoreboard

# 纵向排列 5 个测试实体，其中 2 个带 need 标签（不计入统计、应被豁免）
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_excess_test","dfl_excess_all"]}
summon minecraft:armor_stand ~ 201 ~ {Tags:["dfl_excess_test","dfl_excess_all"]}
summon minecraft:armor_stand ~ 202 ~ {Tags:["dfl_excess_test","dfl_excess_all"]}
summon minecraft:armor_stand ~ 203 ~ {Tags:["dfl_excess_need","need","dfl_excess_all"]}
summon minecraft:armor_stand ~ 204 ~ {Tags:["dfl_excess_need","need","dfl_excess_all"]}

# 执行被测函数（阈值 3，恰好等于非 need 测试实体数）
function dfl:tick/kill_excess_entities {num:"3"}

# 验证：无 need 标签的实体被清除
execute unless entity @e[tag=dfl_excess_test] run scoreboard players set killed testing 1
# 验证：need 标签实体被豁免
execute if entity @e[tag=dfl_excess_need] run scoreboard players set need.alive testing 1

execute if score killed testing matches 1 if score need.alive testing matches 1 run function dfl:test/pass

# 清理
kill @e[tag=dfl_excess_all]
scoreboard objectives remove dfl_scoreboard
