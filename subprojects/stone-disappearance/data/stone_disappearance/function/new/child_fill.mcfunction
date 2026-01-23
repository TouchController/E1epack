## fill执行函数

# 读取fill_falling_block
scoreboard objectives add sd.temp dummy
execute store result score fill_falling_block sd.temp run data get storage stone_disappearance:data settings.fill_falling_block
# 主世界
$execute if dimension minecraft:overworld \
    store result score 1 temp.fill run \
    fill $(a_x) $(overworld_min) $(a_z) $(b_x) $(overworld_max) $(b_z) $(overworld_block) replace deepslate
$execute if dimension minecraft:overworld \
    store result score 2 temp.fill run \
    fill $(a_x) $(overworld_min) $(a_z) $(b_x) $(overworld_max) $(b_z) $(overworld_block) replace stone
execute if dimension minecraft:overworld run \
    scoreboard players operation 1 temp.fill += 2 temp.fill
# 主世界 - 处理沙子、红沙、沙砾
    $execute if dimension minecraft:overworld \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(overworld_min) $(a_z) $(b_x) $(overworld_max) $(b_z) $(fill_falling_block_with) replace sand
    $execute if dimension minecraft:overworld \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(overworld_min) $(a_z) $(b_x) $(overworld_max) $(b_z) $(fill_falling_block_with) replace red_sand
    $execute if dimension minecraft:overworld \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(overworld_min) $(a_z) $(b_x) $(overworld_max) $(b_z) $(fill_falling_block_with) replace gravel
# 下界
$execute if dimension minecraft:the_nether \
    store result score 1 temp.fill run \
    fill $(a_x) $(nether_min) $(a_z) $(b_x) $(nether_max) $(b_z) $(nether_block) replace netherrack
$execute if dimension minecraft:the_nether \
    store result score 2 temp.fill run \
    fill $(a_x) $(nether_min) $(a_z) $(b_x) $(nether_max) $(b_z) $(nether_block) replace basalt
execute if dimension minecraft:the_nether run \
    scoreboard players operation 1 temp.fill += 2 temp.fill
# 下界 - 处理沙子、红沙、沙砾
    $execute if dimension minecraft:the_nether \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(nether_min) $(a_z) $(b_x) $(nether_max) $(b_z) $(fill_falling_block_with) replace sand
    $execute if dimension minecraft:the_nether \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(nether_min) $(a_z) $(b_x) $(nether_max) $(b_z) $(fill_falling_block_with) replace red_sand
    $execute if dimension minecraft:the_nether \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(nether_min) $(a_z) $(b_x) $(nether_max) $(b_z) $(fill_falling_block_with) replace gravel
# 末地
$execute if dimension minecraft:the_end \
    store result score 1 temp.fill run \
    fill $(a_x) $(end_min) $(a_z) $(b_x) $(end_max) $(b_z) $(end_block) replace end_stone
# 末地 - 处理沙子、红沙、沙砾
    $execute if dimension minecraft:the_end \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(end_min) $(a_z) $(b_x) $(end_max) $(b_z) $(fill_falling_block_with) replace sand
    $execute if dimension minecraft:the_end \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(end_min) $(a_z) $(b_x) $(end_max) $(b_z) $(fill_falling_block_with) replace red_sand
    $execute if dimension minecraft:the_end \
        if score fill_falling_block sd.temp matches 1 \
        run fill $(a_x) $(end_min) $(a_z) $(b_x) $(end_max) $(b_z) $(fill_falling_block_with) replace gravel

# 移除临时记分板
scoreboard objectives remove sd.temp
