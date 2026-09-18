# 测试 create_glass_box 函数
# 函数生成 5x5x5 空心玻璃立方体：外壳范围相对执行位置 x[-2,2] y[-1,3] z[-2,2]，内部为空气
# 依据：fill ... hollow 仅替换外层，内部替换为空气（wiki 命令/fill）
#       execute if block 可检测指定坐标的方块（wiki 命令/execute）
# 坐标一律相对执行位置，以确保位于已加载区块

# 清理测试区域（范围收紧到 ±3，避免触及出生点以外的区块）
fill ~-3 197 ~-3 ~3 205 ~3 minecraft:air

# 在相对执行位置（y=200）执行被测函数
execute positioned ~ 200 ~ run function dfl:lib/create_glass_box

# 验证：两个对角为玻璃，内部与外部为空气
execute if block ~2 203 ~2 minecraft:glass if block ~-2 199 ~-2 minecraft:glass if block ~ 201 ~ minecraft:air if block ~3 200 ~ minecraft:air run function dfl:test/pass

# 清理
fill ~-3 197 ~-3 ~3 205 ~3 minecraft:air
