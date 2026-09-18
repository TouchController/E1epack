# 测试 create_rescue_platform 函数
# 平台生成依赖 @a[tag=dfl_slime]，无玩家时不执行；此处验证函数的两项初始化副作用：
# slime_time 未设置时被设为 200，以及 dfl_slime_marker_temp 记分项被创建
# 依据：execute if score 可检测分数（wiki 命令/execute）
#       scoreboard objectives add 在记分项已存在时执行失败（wiki 命令/scoreboard 结果表）

# 移除记分项，确保从零开始
scoreboard objectives remove dfl_scoreboard
scoreboard objectives remove dfl_slime_marker_temp

# 执行被测函数
function dfl:tick/create_rescue_platform

# 验证 slime_time 被设为默认值 200
execute if score slime_time dfl_scoreboard matches 200 run scoreboard players set slime_default testing 1

# 重复创建同名记分项，失败即说明函数已创建
execute store success score created.marker testing run scoreboard objectives add dfl_slime_marker_temp dummy
execute if score created.marker testing matches 0 run scoreboard players set marker_created testing 1

execute if score slime_default testing matches 1 if score marker_created testing matches 1 run function dfl:test/pass