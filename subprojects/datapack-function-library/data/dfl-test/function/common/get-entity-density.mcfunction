# 测试 get_entity_density 函数
# 密度统计的是「10 格内的所有实体」，因此本测试独占 y=250 这一层：
#   1) 与其它测试使用的 y≈200 隔开 50 格，远超 10 格判定范围，不会互相计入
#   2) 实体只在纵向排列，同一 (x,z) 必然落在同一区块
# 全部命令在同一游戏刻内执行，世界不推进，实体不会移动

summon minecraft:armor_stand ~ 250 ~ {Tags:["density_center"]}
summon minecraft:armor_stand ~ 251 ~ {Tags:["density_near"]}
summon minecraft:armor_stand ~ 252 ~ {Tags:["density_near"]}
summon minecraft:armor_stand ~ 253 ~ {Tags:["density_near"]}

function dfl:lib/get_entity_density

# 中心实体周围 10 格内应恰好是 4 个（自己 + 3 个 near）
execute if score @e[limit=1,tag=density_center,type=minecraft:armor_stand] dfl_density matches 4 run function dfl:test/pass

# 清理
kill @e[tag=density_center]
kill @e[tag=density_near]
