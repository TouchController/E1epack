## 铁块电梯，玩家站在铁块之间时向上传送

# 玩家电梯逻辑
execute as @a[gamemode=!spectator] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~5 ~ minecraft:iron_block \
    run tp @s ~ ~6 ~

execute as @a[gamemode=!spectator] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~4 ~ minecraft:iron_block \
    run tp @s ~ ~5 ~

execute as @a[gamemode=!spectator] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~3 ~ minecraft:iron_block \
    run tp @s ~ ~4 ~

execute as @a[gamemode=!spectator] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~2 ~ minecraft:iron_block \
    run tp @s ~ ~3 ~

# 实体电梯逻辑
execute as @e[type=!player] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~5 ~ minecraft:iron_block \
    run tp @s ~ ~6 ~

execute as @e[type=!player] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~4 ~ minecraft:iron_block \
    run tp @s ~ ~5 ~

execute as @e[type=!player] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~3 ~ minecraft:iron_block \
    run tp @s ~ ~4 ~

execute as @e[type=!player] at @s \
    if block ~ ~-1 ~ minecraft:iron_block \
    if block ~ ~2 ~ minecraft:iron_block \
    run tp @s ~ ~3 ~
