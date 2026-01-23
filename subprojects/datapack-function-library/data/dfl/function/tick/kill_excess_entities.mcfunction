## 实体过多时清除非玩家实体

# 创建计分板目标，用于统计实体数量
scoreboard objectives add dfl_scoreboard dummy "DFL"
# 统计非玩家且无need标签的实体数量
execute store result score entitynum dfl_scoreboard \
    if entity @e[type=!minecraft:player,tag=!need]
# 实体数量超限时发送清除通知
$execute if score entitynum dfl_scoreboard matches $(num).. run tellraw @a [\
    {\
        "type": "translatable",\
        "translate": "tick.kill.dfl.entity.clear.notification",\
        "fallback": "实体过多，已清除 %s 个实体",\
        "color": "gray",\
        "italic": true,\
        "with": [\
            {\
                "score": {\
                    "name": "entitynum",\
                    "objective": "dfl_scoreboard"\
                },\
                "color": "red"\
            }\
        ]\
    }\
]
# 发送如何保护实体的提示信息
$execute if score entitynum dfl_scoreboard matches $(num).. run tellraw @a [\
    {\
        "type": "translatable",\
        "translate": "tick.kill.dfl.protection.hint",\
        "fallback": "想要防止实体被清除可以为实体添加 '%s' 标签",\
        "color": "gray",\
        "italic": true,\
        "with": [\
            {\
                "text": "need",\
                "color": "blue",\
                "underlined": true,\
                "italic": true,\
                "clickEvent": {\
                    "action": "suggest_command",\
                    "value": "/tag @s add need"\
                },\
                "click_event": {\
                    "action": "suggest_command",\
                    "command": "/tag @s add need"\
                }\
            }\
        ]\
    }\
]
# 清除非玩家且无need标签的实体
$execute if score entitynum dfl_scoreboard matches $(num).. \
    run kill @e[type=!minecraft:player,tag=!need]
