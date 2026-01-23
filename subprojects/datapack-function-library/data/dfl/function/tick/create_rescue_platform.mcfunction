## 自救平台 - 生成史莱姆平台
# 为带有 dfl_slime 标签的玩家生成临时史莱姆平台，持续10秒后自动清除

# 初始化记分板 - 如果不存在则创建主记分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 初始化史莱姆平台持续时间（200游戏刻 = 10秒）
# 如果 slime_time 记分板值未设置（不在整数范围内），则设置为200
# 这确保每个平台持续10秒
execute unless score slime_time dfl_scoreboard matches -2147483648..2147483647 \
    run scoreboard players set slime_time dfl_scoreboard 200

# 计算平台过期时间点
# 将当前游戏时间复制到临时变量 slime_temp
scoreboard players operation slime_temp dfl_scoreboard = gametime dfl_scoreboard
# 计算过期时间：当前时间 - 平台持续时间 = 过期时间点
# 任何生成时间早于此时间点的平台都应该被清除
scoreboard players operation slime_temp dfl_scoreboard -= slime_time dfl_scoreboard

# 创建临时记分板用于标记实体的时间记录
# 每个标记实体将存储自己的生成时间
scoreboard objectives add dfl_slime_marker_temp dummy

# 为所有带有 dfl_slime 标签的玩家生成史莱姆平台
# 在玩家脚下生成 3x3 的史莱姆块区域（玩家位置为中心，Y轴向下1格）
# 只替换空气，不破坏现有方块
execute as @a[tag=dfl_slime] at @s \
    run fill ~-1 ~-1 ~-1 ~1 ~-1 ~1 minecraft:slime_block replace minecraft:air

# 为每个平台生成标记实体
# 标记实体用于跟踪平台的位置和生成时间
# 使用 minecraft:marker 实体，这是一种轻量级的不可见实体
execute as @a[tag=dfl_slime] at @s \
    run summon minecraft:marker ~ ~ ~ {Tags:[dfl_slime_marker_temp]}

# 为标记实体记录生成时间
# 如果标记实体还没有设置时间（不在整数范围内），则记录当前游戏时间
# 这样每个标记实体都知道自己是什么时候生成的
execute as @e[type=marker,tag=dfl_slime_marker_temp] \
    unless score @s dfl_slime_marker_temp matches -2147483648..2147483647 \
    run scoreboard players operation @s dfl_slime_marker_temp = gametime dfl_scoreboard

# 检查并清除过期平台
# 如果标记实体的生成时间早于过期时间点，说明平台已经过期
# 清除对应的史莱姆平台（将史莱姆块替换为空气）
execute as @e[type=marker,tag=dfl_slime_marker_temp] at @s \
    if score @s dfl_slime_marker_temp < slime_temp dfl_scoreboard \
    run fill ~-1 ~-1 ~-1 ~1 ~-1 ~1 minecraft:air replace minecraft:slime_block

# 清除过期的标记实体
# 与平台清除同步，删除对应的标记实体，防止内存泄漏
execute as @e[type=marker,tag=dfl_slime_marker_temp] \
    if score @s dfl_slime_marker_temp < slime_temp dfl_scoreboard \
    run kill

# 清除掉落的史莱姆块物品
# 当平台被破坏时，可能会掉落史莱姆块物品
# 清理平台位置周围2格内的史莱姆块掉落物，保持游戏整洁
execute as @e[type=marker,tag=dfl_slime_marker_temp] at @s \
    run kill @e[type=item,distance=..2,nbt={Item:{id:"minecraft:slime_block"}}]

# 移除玩家标签，防止重复处理
# 确保每个玩家只被处理一次，避免在下一tick重复生成平台
tag @a remove dfl_slime
