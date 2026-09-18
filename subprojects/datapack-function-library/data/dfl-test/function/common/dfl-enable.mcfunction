# 测试 dfl_enable 函数
# 依据：scoreboard objectives add 在记分项已存在时执行失败（wiki 命令/scoreboard 结果表）

# 移除记分项，确保从零开始
scoreboard objectives remove dfl_scoreboard

# 执行被测函数
function dfl:dfl_enable

# 验证 dfl_enable 分数为 1
execute if score dfl_enable dfl_scoreboard matches 1 run function dfl:test/pass