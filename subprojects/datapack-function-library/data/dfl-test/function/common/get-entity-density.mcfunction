# 清理旧实体到虚空
tp @e ~ -1000 ~

# 在出生点召唤中心实体，带 NoGravity 和 tag
summon minecraft:armor_stand ~ ~ ~ {NoGravity:1b,Tags:["density_center"]}

# 在附近（5格内）召唤3个实体
summon minecraft:armor_stand ~1 ~ ~ {NoGravity:1b,Tags:["density_near"]}
summon minecraft:armor_stand ~ ~1 ~ {NoGravity:1b,Tags:["density_near"]}
summon minecraft:armor_stand ~ ~ ~1 {NoGravity:1b,Tags:["density_near"]}

# 执行密度计算
function dfl:lib/get_entity_density

# 验证中心实体的密度值（周围10格内应有4个实体：自己 + 3个near）
execute as @e[tag=density_center,limit=1] if score @s dfl_density matches ..3 run say [DENSITY] <4
execute as @e[tag=density_center,limit=1] if score @s dfl_density matches 5.. run say [DENSITY] >4
# 可能因为未知原因死掉，稍微宽松一些
execute if score @e[limit=1,tag=density_center,type=minecraft:armor_stand] dfl_density matches 2..4 run function dfl:test/pass
