## 显示实体数量信息

# 显示标题分隔线
tellraw @a [\
    {"text": "[DFL]---------------", "color": "gray"}\
]

# 显示总实体数量
tellraw @a [\
    {\
        "type": "translatable",\
        "translate": "redstone.show.entity.dfl.entity.entity",\
        "fallback": "实体数量：",\
        "color": "yellow"\
    },\
    {\
        "score": {\
            "name": "entity",\
            "objective": "dfl_scoreboard"\
        },\
        "color": "red"\
    }\
]

# 显示非玩家实体数量
tellraw @a [\
    {\
        "type": "translatable",\
        "translate": "redstone.show.entity.dfl.entity.other.entity",\
        "fallback": "非玩家实体数量：",\
        "color": "yellow"\
    },\
    {\
        "score": {\
            "name": "other_entity",\
            "objective": "dfl_scoreboard"\
        },\
        "color": "red"\
    }\
]

# 显示掉落物数量
tellraw @a [\
    {\
        "type": "translatable",\
        "translate": "redstone.show.entity.dfl.entity.item",\
        "fallback": "掉落物数量：",\
        "color": "yellow"\
    },\
    {\
        "score": {\
            "name": "item",\
            "objective": "dfl_scoreboard"\
        },\
        "color": "red"\
    }\
]
