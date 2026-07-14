# 计数
    # 输入物品数量
$function dfl:lib/count_items {namespace:"$(input_namespace)",name:"$(input)"}
    # 燃料数量
$function dfl:lib/count_items {namespace:"$(fuel_namespace)",name:"$(fuel)"}
# 数量足够则添加标签
$execute \
    if score @s dfl_$(input_namespace).$(input)_count matches $(amount).. \
    if score @s dfl_$(fuel_namespace).$(fuel)_count matches 1.. \
    if score @s xp matches $(amount).. run \
    tag @s add dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)
# 处理拥有标签的玩家
    # 给予输出物
$give @s[tag=dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)] $(output) $(amount)
    # 清除输入物
$clear @s[tag=dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)] $(input) $(amount)
    # 清除燃料
$clear @s[tag=dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)] $(fuel) 1
    # 扣除经验
$xp add @s[tag=dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)] -$(amount)
    # 移除标签
$tag @s remove dfl_smelt_$(input_namespace)_$(input)_$(fuel_namespace)_$(fuel)
