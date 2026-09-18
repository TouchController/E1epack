# 测试 count_items 函数
# 无玩家时 execute as @a 无目标，物品计数不会写入；此处验证函数创建的记分项
# 依据：scoreboard objectives add 在记分项已存在时执行失败（wiki 命令/scoreboard 结果表）

# 移除记分项，确保从零开始
scoreboard objectives remove dfl_minecraft.stone_count

# 执行被测函数（宏函数，需传参）
function dfl:lib/count_items {namespace:"minecraft",name:"stone"}

# 重复创建同名记分项，失败即说明函数已创建
execute store success score created testing run scoreboard objectives add dfl_minecraft.stone_count dummy
execute if score created testing matches 0 run function dfl:test/pass

# 清理
scoreboard objectives remove dfl_minecraft.stone_count
