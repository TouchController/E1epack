## 清除单个物品并执行命令
# 为所有持有指定物品的玩家执行一次命令并清除一个物品

# 获取所有玩家持有指定物品的数量
$function dfl:lib/count_items {name:"$(name)"}

# 为持有该物品的每个玩家执行一次指定命令
$execute as @a \
    if score @s dfl_$(name)_num matches 1.. \
    run $(run)

# 为持有该物品的每个玩家清除一个指定物品
$execute as @a \
    if score @s dfl_$(name)_num matches 1.. \
    run clear @s $(name) 1
