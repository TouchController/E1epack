## 保持拥有指定数量的物品

# 统计物品数量
$function dfl:lib/count_items {namespace:"$(namespace)",name:"$(name)"}

# 给予物品
$execute unless score @s dfl_$(namespace).$(name)_count matches $(num).. \
    run give @s $(name) 1

# 清除多余物品
$execute unless score @s dfl_$(namespace).$(name)_count matches ..$(num) \
    run clear @s $(name) 1

# 结束条件
$execute if score @s dfl_$(namespace).$(name)_count matches $(num) \
    run return fail

# 递归调用
$function dfl:tick/maintain_item_count {namespace:"$(namespace)",name:"$(name)",num:"$(num)"}
