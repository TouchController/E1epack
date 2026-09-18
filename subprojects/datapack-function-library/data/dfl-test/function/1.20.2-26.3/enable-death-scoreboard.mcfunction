# 测试 enable_death_scoreboard 函数
# 依据：scoreboard objectives add 在记分项已存在时执行失败（wiki 命令/scoreboard 结果表）
#       setdisplay 的显示位置无查询语法，故仅验证记分项创建

# 移除记分项并清空显示位置，确保从零开始
scoreboard objectives remove death
scoreboard objectives setdisplay sidebar

# 执行被测函数
function dfl:start/show/enable_death_scoreboard

# 重复创建同名记分项，失败即说明函数已创建
execute store success score created testing run scoreboard objectives add death deathCount
execute if score created testing matches 0 run function dfl:test/pass

# 清理
scoreboard objectives setdisplay sidebar
scoreboard objectives remove death
