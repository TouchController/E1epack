execute as @a run function auto_smelt:smelt {input:"raw_iron",output:"iron_ingot"}
execute as @a run function auto_smelt:smelt {input:"raw_copper",output:"copper_ingot"}
execute as @a run function auto_smelt:smelt {input:"raw_gold",output:"gold_ingot"}
execute as @a run function auto_smelt:smelt {input:"ancient_debris",output:"netherite_scrap"}

execute as @a run function auto_smelt:smelt {input:"porkchop",output:"cooked_porkchop"}
execute as @a run function auto_smelt:smelt {input:"beef",output:"cooked_beef"}
execute as @a run function auto_smelt:smelt {input:"chicken",output:"cooked_chicken"}
execute as @a run function auto_smelt:smelt {input:"cod",output:"cooked_cod"}
execute as @a run function auto_smelt:smelt {input:"salmon",output:"cooked_salmon"}
execute as @a run function auto_smelt:smelt {input:"potato",output:"baked_potato"}
execute as @a run function auto_smelt:smelt {input:"mutton",output:"cooked_mutton"}
execute as @a run function auto_smelt:smelt {input:"rabbit",output:"cooked_rabbit"}
execute as @a run function auto_smelt:smelt {input:"kelp",output:"dried_kelp"}


scoreboard players enable @a ore
execute as @a unless score @s ore matches 1 run scoreboard players set @s ore 0
execute as @a if score @s ore matches 1 run function auto_smelt:ore
