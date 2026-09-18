# 测试 kill_tnt_by_density 函数
# 函数统计每个实体 5 格内的 TNT 数量写入 dfl_tntdensity，达阈值的实体清除其 5 格内的 TNT
# 实体只在纵向排列，不产生横向偏移
# 测试的全部命令在同一游戏刻内执行，TNT 引信不会走完，无需处理爆炸

scoreboard objectives remove dfl_tntdensity

# 纵向排列 3 个 TNT
summon minecraft:tnt ~ 200 ~ {Tags:["dfl_tnt_test"]}
summon minecraft:tnt ~ 201 ~ {Tags:["dfl_tnt_test"]}
summon minecraft:tnt ~ 202 ~ {Tags:["dfl_tnt_test"]}

# 执行被测函数（阈值 2）
function dfl:tick/kill_tnt_by_density {num:"2"}

# 验证：TNT 已被清除
execute unless entity @e[type=minecraft:tnt] run function dfl:test/pass

# 清理
kill @e[type=minecraft:tnt]
scoreboard objectives remove dfl_tntdensity
