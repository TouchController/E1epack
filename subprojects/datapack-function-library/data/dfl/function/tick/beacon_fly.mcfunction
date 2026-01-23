## 信标鞘翅起飞，根据信标下方方块类型传送玩家

#四级
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:iron_block \
    if block ~ ~-3 ~ minecraft:iron_block \
    if block ~ ~-4 ~ minecraft:iron_block \
    if block ~ ~-5 ~ minecraft:iron_block \
    run tp @s ~ ~80 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:gold_block \
    if block ~ ~-3 ~ minecraft:gold_block \
    if block ~ ~-4 ~ minecraft:gold_block \
    if block ~ ~-5 ~ minecraft:gold_block \
    run tp @s ~ ~160 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:emerald_block \
    if block ~ ~-3 ~ minecraft:emerald_block \
    if block ~ ~-4 ~ minecraft:emerald_block \
    if block ~ ~-5 ~ minecraft:emerald_block \
    run tp @s ~ ~240 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:diamond_block \
    if block ~ ~-3 ~ minecraft:diamond_block \
    if block ~ ~-4 ~ minecraft:diamond_block \
    if block ~ ~-5 ~ minecraft:diamond_block \
    run tp @s ~ ~320 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:netherite_block \
    if block ~ ~-3 ~ minecraft:netherite_block \
    if block ~ ~-4 ~ minecraft:netherite_block \
    if block ~ ~-5 ~ minecraft:netherite_block \
    run tp @s ~ ~400 ~

#三级
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:iron_block \
    if block ~ ~-3 ~ minecraft:iron_block \
    if block ~ ~-4 ~ minecraft:iron_block \
    run tp @s ~ ~60 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:gold_block \
    if block ~ ~-3 ~ minecraft:gold_block \
    if block ~ ~-4 ~ minecraft:gold_block \
    run tp @s ~ ~120 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:emerald_block \
    if block ~ ~-3 ~ minecraft:emerald_block \
    if block ~ ~-4 ~ minecraft:emerald_block \
    run tp @s ~ ~180 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:diamond_block \
    if block ~ ~-3 ~ minecraft:diamond_block \
    if block ~ ~-4 ~ minecraft:diamond_block \
    run tp @s ~ ~240 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:netherite_block \
    if block ~ ~-3 ~ minecraft:netherite_block \
    if block ~ ~-4 ~ minecraft:netherite_block \
    run tp @s ~ ~300 ~

#二级
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:iron_block \
    if block ~ ~-3 ~ minecraft:iron_block \
    run tp @s ~ ~40 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:gold_block \
    if block ~ ~-3 ~ minecraft:gold_block \
    run tp @s ~ ~80 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:emerald_block \
    if block ~ ~-3 ~ minecraft:emerald_block \
    run tp @s ~ ~120 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:diamond_block \
    if block ~ ~-3 ~ minecraft:diamond_block \
    run tp @s ~ ~160 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:netherite_block \
    if block ~ ~-3 ~ minecraft:netherite_block \
    run tp @s ~ ~200 ~

#一级
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:iron_block run tp @s ~ ~20 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:gold_block run tp @s ~ ~40 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:emerald_block run tp @s ~ ~60 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:diamond_block run tp @s ~ ~80 ~
execute as @a[gamemode=!spectator] at @s if block ~ ~-1 ~ minecraft:beacon \
    if block ~ ~-2 ~ minecraft:netherite_block run tp @s ~ ~100 ~
