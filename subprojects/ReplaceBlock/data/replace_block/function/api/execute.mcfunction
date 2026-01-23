tag @s add unif.debug
$data modify storage replace_block:data settings set from storage $(storage) replace_block
function replace_block:api/check_config
execute if score check.fail rb.return matches 1 run return fail
function replace_block:api/call_main with storage replace_block:data settings
