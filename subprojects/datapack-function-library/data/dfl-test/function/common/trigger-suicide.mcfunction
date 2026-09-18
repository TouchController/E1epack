# 测试 trigger_suicide 函数
# 函数创建准则为 trigger 的 kill 记分项；无玩家时 players enable @a 无目标
# 依据：scoreboard players enable 在「记分项不存在」或「准则不是 trigger」时执行失败
#       （wiki 命令/scoreboard 结果表）；分数持有者名无需对应在线玩家

# 移除记分项，确保从零开始
scoreboard objectives remove kill

# 执行被测函数
function dfl:tick/trigger_suicide

# 用虚拟分数持有者检测：enable 成功即说明 kill 记分项存在且准则为 trigger
execute store success score enabled testing run scoreboard players enable dfl.test_holder kill
execute if score enabled testing matches 1 run function dfl:test/pass

# 清理
scoreboard players reset dfl.test_holder kill
scoreboard objectives remove kill