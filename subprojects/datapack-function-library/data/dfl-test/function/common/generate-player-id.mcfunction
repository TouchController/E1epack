# 测试 generate_player_id 函数
# 无玩家环境下 UID 分配逻辑不执行，此处验证函数创建的两个记分项
# 依据：scoreboard objectives add 在记分项已存在时执行失败（wiki 命令/scoreboard 结果表）

# 移除记分项，确保从零开始
scoreboard objectives remove dfl_scoreboard
scoreboard objectives remove dfl_playerid

# 执行被测函数
function dfl:lib/generate_player_id

# 重复创建同名记分项，失败即说明函数已创建
execute store success score created.id testing run scoreboard objectives add dfl_playerid dummy
execute store success score created.sb testing run scoreboard objectives add dfl_scoreboard dummy
execute if score created.id testing matches 0 if score created.sb testing matches 0 run function dfl:test/pass