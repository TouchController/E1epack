# 测试 teleport_request 函数
# 函数创建准则为 trigger 的 tpa 与 tpa_enable 记分项；无玩家时 enable @a 无目标
# 注意：函数中的 scoreboard objectives setdisplay list dfl_playerid 依赖 dfl_playerid 记分项，
# 该记分项仅由 dfl:lib/generate_player_id 创建，此处单独执行该命令会失败（不影响其余命令）
# 依据：scoreboard players enable 在「记分项不存在」或「准则不是 trigger」时执行失败
#       （wiki 命令/scoreboard 结果表）

# 移除记分项，确保从零开始
scoreboard objectives remove tpa
scoreboard objectives remove tpa_enable

# 执行被测函数
function dfl:tick/teleport_request

# 用虚拟分数持有者检测两个记分项都存在且准则为 trigger
execute store success score enabled.tpa testing run scoreboard players enable dfl.test_holder tpa
execute store success score enabled.enable testing run scoreboard players enable dfl.test_holder tpa_enable
execute if score enabled.tpa testing matches 1 if score enabled.enable testing matches 1 run function dfl:test/pass

# 清理
scoreboard players reset dfl.test_holder tpa
scoreboard players reset dfl.test_holder tpa_enable
scoreboard objectives remove tpa
scoreboard objectives remove tpa_enable