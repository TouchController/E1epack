execute at @a[gamemode=!spectator,gamemode=!creative,scores={health=5..}] run setblock ~ ~-1 ~ tnt
execute at @a[gamemode=!spectator,gamemode=!creative,scores={health=1..4}] run setblock ~ ~-1 ~ redstone_block
execute at @a[gamemode=!spectator,gamemode=!creative,scores={health=1..4}] run setblock ~ ~-2 ~ tnt

execute as @a at @s run function dfl:tick/convert_items_to_xp {name:"tnt",xp:"1"}
function dfl:tick/kill_tnt_by_density {num:"200"}
execute at @a run function dfl:tick/change_block {new:"air",old:"fire",num:"30"}
function dfl:lib/get_entity_count
function dfl:tick/mith
execute as @e[type=tnt] at @s unless entity @a[distance=..20] run kill
