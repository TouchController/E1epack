## 清除指定物品并执行多次命令
# 递归函数，用于清除指定物品并执行相应次数的命令

# 获取玩家持有指定物品的数量
$function dfl:lib/count_items {name:"$(name)"}

# 如果物品数量大于等于1，执行指定命令
$execute if score @s dfl_$(name)_num matches 1.. \
    run $(run)

# 如果物品数量大于等于1，清除一个指定物品
$execute if score @s dfl_$(name)_num matches 1.. \
    run clear @s $(name) 1

# 如果物品数量为0，返回失败状态
$execute if score @s dfl_$(name)_num matches 0 \
    run return fail

# 递归调用自身，继续处理剩余物品
$function dfl:tick/clear_and_execute_multiple {name:"$(name)",run:"$(run)"}
