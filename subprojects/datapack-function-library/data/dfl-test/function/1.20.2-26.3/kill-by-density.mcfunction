# 测试 kill_by_density 函数
# 函数以「分数达到阈值的实体」为中心，清除其 10 格内的实体，玩家、村民与 need 标签实体被豁免
# 实体只在纵向排列，不产生横向偏移

scoreboard objectives remove dfl_density
scoreboard objectives add dfl_density dummy

# 纵向排列测试实体，其中 2 个应被豁免（村民、need 标签）
summon minecraft:armor_stand ~ 200 ~ {Tags:["dfl_density_test","dfl_density_all"]}
summon minecraft:armor_stand ~ 201 ~ {Tags:["dfl_density_test","dfl_density_all"]}
summon minecraft:villager ~ 202 ~ {Tags:["dfl_density_villager","dfl_density_all"]}
summon minecraft:armor_stand ~ 203 ~ {Tags:["dfl_density_need","need","dfl_density_all"]}

# 只让其中一个实体达到阈值，由它触发清除
scoreboard players set @e[tag=dfl_density_test,limit=1] dfl_density 50

# 执行被测函数（阈值 50）
function dfl:tick/kill_by_density {num:"50"}

# 验证：非豁免实体被清除
execute unless entity @e[tag=dfl_density_test] run scoreboard players set killed testing 1
# 验证：村民与 need 标签实体被豁免
execute if entity @e[tag=dfl_density_villager] run scoreboard players set villager.alive testing 1
execute if entity @e[tag=dfl_density_need] run scoreboard players set need.alive testing 1

execute if score killed testing matches 1 if score villager.alive testing matches 1 if score need.alive testing matches 1 run function dfl:test/pass

# 清理
kill @e[tag=dfl_density_all]
scoreboard objectives remove dfl_density
