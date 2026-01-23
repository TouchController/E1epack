# 计数
    # 输入物品数量
$function dfl:lib/count_items {name:"$(input)"}
    # 燃料数量
function dfl:lib/count_items {name:"$(fuel)"}
# 数量足够则添加标签
$execute \
    if score @s dfl_$(input)_num matches $(amount).. \
    if score @s dfl_$(fuel)_num matches 1.. \
    if score @s xp matches $(amount).. run \
    tag @s add $(input)_$(fuel)
# 处理拥有标签的玩家
    # 给予输出物
$give @s[tag=$(input)_$(fuel)] $(output) $(amount)
    # 清除输入物
$clear @s[tag=$(input)_$(fuel)] $(input) $(amount)
    # 清除燃料
$clear @s[tag=$(input)_$(fuel)] $(fuel) 1
    # 扣除经验
$xp add @s[tag=$(input)_$(fuel)] -$(amount)
    # 移除标签
$tag @s remove $(input)_$(fuel)
