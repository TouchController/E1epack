# 测试 iron_block_elevator 的实体部分
# 玩家部分使用 @a[gamemode=!spectator]，gamemode 参数会自动过滤非玩家目标，无玩家时不执行
# 两块铁块与测试实体同处一条竖线，不产生横向偏移

# 清理测试竖列
fill ~ 198 ~ ~ 210 ~ minecraft:air

# 放置上下两块铁块：实体位于 y=201 时 ~-1 为下方铁块、~5 为上方铁块
execute align xyz run fill ~ 200 ~ ~ 200 ~ minecraft:iron_block
execute align xyz run fill ~ 206 ~ ~ 206 ~ minecraft:iron_block

# 在两块铁块之间生成测试实体
execute align xyz run summon minecraft:armor_stand ~0.5 201 ~0.5 {Tags:["dfl_elevator_test"]}

# 执行被测函数
function dfl:tick/iron_block_elevator

# 验证实体被向上传送 6 格（y: 201 -> 207）
execute align xyz positioned ~ 207 ~ if entity @e[tag=dfl_elevator_test,distance=..1] run function dfl:test/pass

# 清理
kill @e[tag=dfl_elevator_test]
fill ~ 198 ~ ~ 210 ~ minecraft:air
