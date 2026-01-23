## 仓库内通用数据包加载成功提示模板

tellraw @a "--------------------"
$tellraw @a [\
    "| ",\
    {\
        "translate":"banner.white.elephant.enabled",\
        "fallback":"%s 数据包加载成功",\
        "with":[{"text":"$(name)"}],\
        "color":"green",\
        "bold":true\
    }]
$tellraw @a [\
    "| ",\
    {\
        "translate":"banner.white.elephant.author",\
        "fallback":"作者：%s",\
        "with":[{\
                "text":"$(author)",\
                "color":"blue",\
                "underlined":true,\
                "italic":true,\
                "click_event":{\
                    "action":"open_url",\
                    "url":"$(author_url)"\
                },\
                "hover_event":{\
                    "action":"show_text",\
                    "value":{\
                        "text":"$(author_url)"\
                    }\
                }\
            }],\
        "bold":true\
    }]
tellraw @a "| "
$tellraw @a [\
    "| ",\
    {\
        "translate":"banner.white.elephant.license",\
        "fallback":"本数据包使用 %s 协议开源",\
        "with":[\
            {\
                "text":"$(license_name)",\
                "color":"blue",\
                "underlined":true,\
                "italic":true,\
                "click_event":{\
                    "action":"open_url",\
                    "url":"$(license_url)"\
                },\
                "hover_event":{\
                    "action":"show_text",\
                    "value":{\
                        "text":"$(license_url)"\
                    }\
                }\
            }\
        ],\
        "bold":true\
    }]
tellraw @a "| "
$tellraw @a [\
    "| ",\
    {\
        "translate":"banner.white.elephant.official",\
        "fallback":"数据包官网",\
        "color":"blue",\
        "underlined":true,\
        "italic":true,\
        "click_event":{\
            "action":"open_url",\
            "url":"$(official_url)"\
        },\
        "hover_event":{\
            "action":"show_text",\
            "value":{\
                "text":"$(official_url)"\
            }\
        }\
    }]
tellraw @a {"type":"translatable","translate":"no.resource.pack.white.elephant.a","fallback":"| "}
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing",\
    "fallback":"WARNING: No localization","color":"red","bold":true}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing",\
    "fallback":"resource package detected.","color":"red","bold":true}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing",\
    "fallback":"You can download it"}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing",\
    "fallback":"by clicking the link below"}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"Modrinth",\
        "color":"blue","underlined":true,"italic":true,\
        "click_event":{"action":"open_url","url":"https://modrinth.com/project/localization-resource-pack"},\
        "hover_event":{"action":"show_text","value":"https://modrinth.com/project/localization-resource-pack"}},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":" | "},\
    {"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"GitHub",\
        "color":"blue","underlined":true,"italic":true,\
        "click_event":{"action":"open_url","url":"https://github.com/WhiteElephant-abc/Localization-Resource-Pack"},\
        "hover_event":{"action":"show_text","value":"https://github.com/WhiteElephant-abc/Localization-Resource-Pack"}}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"--------------------"}]
