# 测试 disable_friendly_fire 函数
# 无玩家时 team join dfl @a 无目标，此处验证队伍创建与两项属性设置
# 依据：team modify 在「指定值与当前值一致」时执行失败（wiki 命令/team 结果表），
#       故先重建队伍取得默认值（friendlyFire=true、collisionRule=always），
#       函数执行后再次写入相同值将失败，以此反证函数已写入该值

# 重建队伍，取得默认属性
team remove dfl
team add dfl

# 执行被测函数
function dfl:tick/disable_friendly_fire

# 再次写入函数设定的值，失败即说明当前值已与函数设定一致
execute store success score ff testing run team modify dfl friendlyFire false
execute store success score cr testing run team modify dfl collisionRule pushOwnTeam
execute if score ff testing matches 0 if score cr testing matches 0 run function dfl:test/pass

# 清理
team remove dfl