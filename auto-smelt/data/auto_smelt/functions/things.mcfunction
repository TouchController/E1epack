#检测datapackets-functions-LIB数据包是否加载

#如果未加载：
function dfl:dfl_enable
execute unless score @r dfl_enable matches 1 as @a unless score @s dfl_need matches 1 run tellraw @s [{"type":"translatable","translate":"need.dfl.white.elephant.no","fallback":"缺少前置","color":"red","bold":true},{"text":" !","color":"red","bold":true}]
execute unless score @r dfl_enable matches 1 as @a unless score @s dfl_need matches 1 run tellraw @s [{"type":"translatable","translate":"need.dfl.white.elephant.please.install","fallback":"请安装数据包: ","color":"gray"},{"text":"datapackets functions LIB","color":"blue","underlined":true,"italic":true,"click_event":{"action":"open_url","url":"https://modrinth.com/datapack/datapackets-functions-lib"},"clickEvent":{"action":"open_url","value":"https://modrinth.com/datapack/datapackets-functions-lib"}}]
execute unless score @r dfl_enable matches 1 as @a unless score @s dfl_need matches 1 at @s run playsound entity.item.break player @s
execute unless score @r dfl_enable matches 1 as @a unless score @s dfl_need matches 1 at @s run playsound entity.villager.no player @s
execute unless score @r dfl_enable matches 1 as @a unless score @s dfl_need matches 1 run scoreboard players set @s dfl_need 1
execute unless score @r dfl_enable matches 1 run return fail

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