# 测试 set_world_spawn 函数
# 函数设置世界出生点为 (0,0,0) 并将重生点半径设为 0
# 命令使用命名空间形式 gamerule（1.21.11 pre1 起规则名称默认命名空间为 minecraft）
# 依据：gamerule 的 result 为该规则执行后的数值（wiki 命令/gamerule 输出表）
#       世界出生点坐标无查询命令，故仅验证 respawn_radius

# 先把规则重置为非目标值
gamerule minecraft:respawn_radius 10

# 执行被测函数
function dfl:start/set_world_spawn

# 验证 respawn_radius 为 0
execute store result score radius testing run gamerule minecraft:respawn_radius
execute if score radius testing matches 0 run function dfl:test/pass
