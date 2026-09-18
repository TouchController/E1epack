# 测试 change_block 函数
# 函数先把 max_block_modifications 提到上限，再以执行位置为中心把 old 替换为 new
# 命令使用命名空间形式 gamerule（1.21.11 pre1 起规则名称默认命名空间为 minecraft）
# 依据：fill ... replace <filter> 只替换匹配的方块（wiki 命令/fill）
#       execute if block / unless block 检测坐标方块（wiki 命令/execute）
# 坐标一律相对执行位置，以确保位于已加载区块

# 清理测试区域
fill ~-4 197 ~-4 ~4 205 ~4 minecraft:air

# 以执行位置为中心铺满石头（num=2 对应相对区域 x[-2,2] y[199,203] z[-2,2]）
fill ~-2 199 ~-2 ~2 203 ~2 minecraft:stone

# 以相对位置（y=201）为执行位置运行被测函数
execute positioned ~ 201 ~ run function dfl:tick/change_block {new:"minecraft:glass",old:"minecraft:stone",num:"2"}

# 验证：中心与两个对角已变为玻璃
execute if block ~ 201 ~ minecraft:glass if block ~-2 199 ~-2 minecraft:glass if block ~2 203 ~2 minecraft:glass run scoreboard players set replaced testing 1
# 验证：原位置的石头已不存在
execute unless block ~ 201 ~ minecraft:stone run scoreboard players set removed testing 1
# 验证：max_block_modifications 被提到上限
execute store result score limit testing run gamerule minecraft:max_block_modifications

execute if score replaced testing matches 1 if score removed testing matches 1 if score limit testing matches 2147483647 run function dfl:test/pass

# 清理
fill ~-4 197 ~-4 ~4 205 ~4 minecraft:air
