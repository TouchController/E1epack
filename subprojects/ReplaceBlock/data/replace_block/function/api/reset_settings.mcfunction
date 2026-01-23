## 设置初始化

# 重置设置
$data modify storage $(storage) replace_block set value \
    {\
        selector:"@e[type=player]",\
        replace_pairs:[\
            {\
                target_block:"stone",\
                replace_with:"air"\
            },\
            {\
                target_block:"sand",\
                replace_with:"glass"\
            },\
            {\
                target_block:"red_sand",\
                replace_with:"glass"\
            },\
            {\
                target_block:"gravel",\
                replace_with:"glass"\
            },\
        ],\
        dimensions:[\
            {\
                dimension:"minecraft:overworld",\
                min_y:-64,\
                max_y:319\
            },\
            {\
                dimension:"minecraft:the_nether",\
                min_y:0,\
                max_y:255\
            },\
                {\
                dimension:"minecraft:the_end",\
                min_y:0,\
                max_y:255\
            }\
        ],\
        search_range:3,\
        success_threshold:50\
    }
