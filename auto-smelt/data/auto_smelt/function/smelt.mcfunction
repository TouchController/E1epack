$function dfl:lib/things_count {name:"$(input)"}
function dfl:lib/things_count {name:"coal_block"}
$execute \
    if score @s dfl_$(input)_num matches 9.. \
    if score @s dfl_coal_block_num matches 1.. \
    if score @s xp matches 9.. run \
    tag @s add $(input)_coal_block
$give @s[tag=$(input)_coal_block] $(output) 9
$clear @s[tag=$(input)_coal_block] $(input) 9
$clear @s[tag=$(input)_coal_block] coal_block 1
$xp add @s[tag=$(input)_coal_block] -9
$tag @s remove $(input)_coal_block


$function dfl:lib/things_count {name:"$(input)"}
function dfl:lib/things_count {name:"coal"}
$execute \
    if score @s dfl_$(input)_num matches 1.. \
    if score @s dfl_coal_num matches 1.. \
    if score @s xp matches 1.. run \
    tag @s add $(input)_coal
$give @s[tag=$(input)_coal] $(output)
$clear @s[tag=$(input)_coal] $(input) 1
$clear @s[tag=$(input)_coal] coal 1
$xp add @s[tag=$(input)_coal] -1
$tag @s remove $(input)_coal


$function dfl:lib/things_count {name:"$(input)"}
function dfl:lib/things_count {name:"charcoal"}
$execute \
    if score @s dfl_$(input)_num matches 1.. \
    if score @s dfl_charcoal_num matches 1.. \
    if score @s xp matches 1.. run \
    tag @s add $(input)_charcoal
$give @s[tag=$(input)_charcoal] $(output)
$clear @s[tag=$(input)_charcoal] $(input) 1
$clear @s[tag=$(input)_charcoal] charcoal 1
$xp add @s[tag=$(input)_charcoal] -1
$tag @s remove $(input)_charcoal