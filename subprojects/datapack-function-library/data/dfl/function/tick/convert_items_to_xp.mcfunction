## 物品转化为经验

# 物品计数
$function dfl:lib/count_items {name:"$(name)"}

# 给予经验与清除物品
$execute if score @s dfl_$(name)_num matches 1.. \
    run summon minecraft:experience_orb ~ ~ ~ {Value:$(xp)}
$execute if score @s dfl_$(name)_num matches 1.. \
    run clear @s $(name) 1

# 递归调用
$execute if score @s dfl_$(name)_num matches 0 \
    run return fail
$function dfl:tick/convert_items_to_xp {name:"$(name)",xp:"$(xp)"}
