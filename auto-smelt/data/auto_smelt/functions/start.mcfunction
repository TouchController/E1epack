tellraw @a "--------------------"
tellraw @a [{"text": "| auto-smelt "},{"type":"translatable","translate":"license.white.elephant.enable","fallback":"数据包加载成功","color":"green","bold":true}]
tellraw @a [{"text": "| "},{"text":"by white_elephant_","color":"blue","underlined":true,"italic":true,"clickEvent":{"action":"open_url","value":"https://modrinth.com/user/white_elephant"},"click_event":{"action":"open_url","url":"https://modrinth.com/user/white_elephant"}}]
tellraw @a "| "
tellraw @a [{"text": "| "},{"type":"translatable","translate":"license.white.elephant.use","fallback":"本数据包使用","bold": true},{"text": " "},{"text":"GNU GPL","color":"blue","underlined":true,"italic":true,"clickEvent":{"action":"open_url","value":"https://www.gnu.org/licenses/gpl-3.0.txt"},"click_event":{"action":"open_url","url":"https://www.gnu.org/licenses/gpl-3.0.txt"}},{"text": " "},{"type":"translatable","translate":"license.white.elephant.open.source","fallback":"协议开源","bold": true}]
tellraw @a {"type":"translatable","translate":"no.resource.pack.white.elephant.a","fallback":"| "}
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"WARNING: No localization","color":"red","bold":true}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"resource package detected.","color":"red","bold":true}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"You can download it"}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"by clicking the link below"}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"| "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"Modrinth","color":"blue","underlined":true,"italic":true,"clickEvent":{"action":"open_url","value":"https://modrinth.com/project/localization-resource-pack"},"click_event":{"action":"open_url","url":"https://modrinth.com/project/localization-resource-pack"}},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":" | "},{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"GitHub","color":"blue","underlined":true,"italic":true,"clickEvent":{"action":"open_url","value":"https://github.com/WhiteElephant-abc/Localization-Resource-Pack"},"click_event":{"action":"open_url","url":"https://github.com/WhiteElephant-abc/Localization-Resource-Pack"}}]
tellraw @a [{"type":"translatable","translate":"no.resource.pack.white.elephant.nothing","fallback":"--------------------"}]

#检测datapackets-functions-LIB数据包是否加载
scoreboard objectives add dfl_enable dummy
scoreboard players set @e dfl_enable 0
#删除dfl_need记分板，确保每次加载数据包时都会重置状态
scoreboard objectives remove dfl_need
scoreboard objectives add dfl_need dummy

scoreboard objectives add xp xp
scoreboard objectives add ore trigger