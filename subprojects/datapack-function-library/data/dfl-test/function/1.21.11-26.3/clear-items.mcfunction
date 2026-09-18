# 测试 clear_items 函数
# 函数清除所有无 need 标签的掉落物，并把清除数量写入 item_number
# 掉落物只在纵向排列，不产生横向偏移

# 掉落物无其他测试依赖，先清空以保证计数精确
kill @e[type=item]
scoreboard objectives remove dfl_scoreboard

# 纵向排列 3 个掉落物
summon minecraft:item ~ 200 ~ {Tags:["dfl_item_test"],Item:{id:"minecraft:stone"}}
summon minecraft:item ~ 201 ~ {Tags:["dfl_item_test"],Item:{id:"minecraft:stone"}}
summon minecraft:item ~ 202 ~ {Tags:["dfl_item_test"],Item:{id:"minecraft:stone"}}

# 执行被测函数
function dfl:timer/clear_items

# 验证：掉落物已全部清除，且计数与召唤数量一致
execute unless entity @e[type=item] if score item_number dfl_scoreboard matches 3 run function dfl:test/pass

# 清理
kill @e[type=item]
scoreboard objectives remove dfl_scoreboard
