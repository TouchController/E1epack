$data modify storage replace_block:data temp.test_dimension \
    merge from storage replace_block:data settings.dimensions[$(dimension_index)]
return run function replace_block:private/fill/traversal/if_dimension \
    with storage replace_block:data temp.test_dimension
