$data modify storage replace_block:data temp.fill_chunk merge from storage replace_block:data settings.replace_pairs[$(pair_index)]
function replace_block:private/fill/exec/command with storage replace_block:data temp.fill_chunk
