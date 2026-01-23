## 保持拥有指定数量的物品

# 统计物品数量
$function dfl:lib/count_items {name:"$(name)"}

# 给予物品
$execute unless score @s dfl_$(name)_num matches $(num).. \
    run give @s $(name) 1

# 清除多余物品
$execute unless score @s dfl_$(name)_num matches ..$(num) \
    run clear @s $(name) 1

# 结束条件
$execute if score @s dfl_$(name)_num matches $(num) \
    run return fail

# 递归调用
$function dfl:tick/maintain_item_count {name:"$(name)",num:"$(num)"}
