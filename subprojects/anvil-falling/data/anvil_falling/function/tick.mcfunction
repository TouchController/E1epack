execute at @a[gamemode=survival] if dimension minecraft:overworld run setblock ~ ~100 ~ minecraft:anvil
execute at @e[nbt={BlockState:{Name:"minecraft:anvil"}}] if dimension minecraft:overworld run fill ~ ~ ~ ~ ~-2 ~ air replace minecraft:stone
execute at @e[nbt={BlockState:{Name:"minecraft:anvil"}}] if dimension minecraft:overworld run fill ~ ~ ~ ~ ~-2 ~ air replace minecraft:grass_block
execute at @e[nbt={BlockState:{Name:"minecraft:anvil"}}] if dimension minecraft:overworld run fill ~ ~ ~ ~ ~-2 ~ air replace minecraft:dirt

execute at @a[gamemode=survival] if dimension minecraft:the_nether run fill ~ 127 ~ ~ 120 ~ air replace minecraft:bedrock
execute at @a[gamemode=survival] if dimension minecraft:the_nether run setblock ~ 130 ~ minecraft:anvil
execute at @e[nbt={BlockState:{Name:"minecraft:anvil"}}] if dimension minecraft:the_nether run fill ~ ~ ~ ~ ~-2 ~ air replace minecraft:netherrack

execute at @a[gamemode=survival] if dimension minecraft:the_end run setblock ~ ~100 ~ minecraft:anvil
execute at @a if dimension minecraft:the_end run fill ~10 ~10 ~10 ~-10 ~-10 ~-10 minecraft:air replace minecraft:anvil
execute at @a if dimension minecraft:the_end run fill ~10 ~10 ~10 ~-10 ~-10 ~-10 minecraft:air replace minecraft:chipped_anvil
execute at @a if dimension minecraft:the_end run fill ~10 ~10 ~10 ~-10 ~-10 ~-10 minecraft:air replace minecraft:damaged_anvil
