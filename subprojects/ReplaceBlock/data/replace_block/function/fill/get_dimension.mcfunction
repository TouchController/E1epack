$execute unless data storage replace_block:data settings.dimensions[{dimension:"$(Dimension)"}] run return run scoreboard players set dimension.not.found rb.return 1
$data modify storage replace_block:data temp.fill_chunk merge from storage replace_block:data settings.dimensions[{dimension:"$(Dimension)"}]
