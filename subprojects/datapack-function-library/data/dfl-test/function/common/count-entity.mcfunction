summon armor_stand
summon armor_stand
summon armor_stand
summon armor_stand

execute if entity @e run say 有实体生成
execute unless entity @e run say 没有实体生成

say 全部实体： @e
say 盔甲架： @e[type=armor_stand]

execute if entity @e[type=armor_stand] run function dfl:test/pass
