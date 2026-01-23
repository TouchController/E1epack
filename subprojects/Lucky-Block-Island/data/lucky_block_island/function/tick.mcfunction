execute unless biome 0 10 0 minecraft:the_void run \
    title @a actionbar \
        {\
            "translate":"title.lucky_block_island.error.actionbar",\
            "bold":true,\
            "color":"red",\
            "fallback":"维度设置验证失败，请在创建世界时加载数据包！"\
        }
execute unless biome 0 10 0 minecraft:the_void run \
    return 0

# 启用trigger
scoreboard players enable @a minecraft.is.too.hard
scoreboard players enable @a no.friendly.fire.and.collision
scoreboard players enable @a clear.offhand

# 处理trigger值
execute as @a unless score @s minecraft.is.too.hard matches 1 run \
    scoreboard players set @s minecraft.is.too.hard 0
execute as @a unless score @s no.friendly.fire.and.collision matches 1 run \
    scoreboard players set @s no.friendly.fire.and.collision 0
execute as @a unless score @s clear.offhand matches 1 run \
    scoreboard players set @s clear.offhand 0

# 禁用功能
execute unless entity @a[scores={minecraft.is.too.hard=1}] run \
    function lucky_block_island:disable/minecraft.is.too.hard
execute unless entity @a[scores={no.friendly.fire.and.collision=1}] run \
    function lucky_block_island:disable/no.friendly.fire.and.collision

# minecraft is too hard
execute as @a[scores={minecraft.is.too.hard=1}] run \
    function dfl:tick/mith
execute if entity @a[scores={minecraft.is.too.hard=1}] run \
    function lucky_block_island:mith
# no friendly fire and collision
execute if entity @a[scores={no.friendly.fire.and.collision=1}] run \
    function dfl:tick/team
# 垃圾桶
execute as @a[scores={clear.offhand=1}] run \
    item replace entity @s weapon.offhand with air

# 放置lucky_block
setblock 0 0 0 lucky:lucky_block keep

# 掉落物传送
execute positioned 0 0 0 as @e[distance=..3,type=item] \
    unless data entity @s Thrower run tp 0 1 0

# 防掉虚空
execute as @e store result score @s pos run data get entity @s Pos[1]
execute as @e[scores={pos=..-64},type=!item] run tp @s 0 20 0

# 禁止下界
execute as @a at @s if dimension minecraft:the_nether \
    in minecraft:overworld run tp @s 0 1 0
