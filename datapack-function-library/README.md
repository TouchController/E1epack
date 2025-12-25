**Click [here](https://github.com/TouchController/E1epack/blob/main/datapack-function-library/README-en_us.md) to view the English version.**

# 前言

_本数据包遵循开源协议 [GNU LESSER GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/lgpl-3.0.txt "跳转到此开源协议页面")。_

**本数据包为开发者提供了一些实用的函数（还有一些对话框），兼容 Minecraft 所有版本（除了无法安装数据包的版本）。**

**但由于数据包涉及命令较多，所以较低版本可能无法使用所有函数，下文将不会分别注明所有函数的适用版本。**

**请同时安装资源包以使用本地化内容（v3.2+版本）。否则，数据包语言将默认为 zh_cn。**

**本数据包的模组版本是通过 Modrinth 打包的，内容与数据包版本完全一致，但不一定是最新版，请尽量使用数据包版本。**

**本数据包提供一个 dfl:dfl_enable 函数，可以将所有实体在此记分项中的分数设为 1，便于依赖于本数据包的数据包或模组检测本数据包是否加载。**

**范例：**

```mcfunction
#在数据包加载时执行：
scoreboard objectives add dfl_scoreboard dummy
scoreboard players set dfl_enable dfl_scoreboard 0
#如果未加载：
function dfl:dfl_enable
execute unless score dfl_enable dfl_scoreboard matches 1
#如果加载：
function dfl:dfl_enable
execute if score dfl_enable dfl_scoreboard matches 1
```

**注意：有些函数的用法下附有“前置函数”，这些函数执行前必须执行一次前置函数。**

**有些函数用法后带有 {xx:"xx"} 这些函数为[宏函数](https://zh.minecraft.wiki/w/Java%E7%89%88%E5%87%BD%E6%95%B0#%E5%AE%8F)，在使用时需通过 {<参数名>:"<内容>"} 传入参数（用法中的参数为作者开发时测试过的推荐参数，或作者测试使用的参数），参数名（如 num）在正文中表现为：{num}。参数格式可参考函数用法，特殊格式会说明。**

如果遇到任何问题，请点击 [这里](https://github.com/TouchController/E1epack/issues/new/choose) 反馈。

# 函数说明

## Start

<span style="color:red;"><b>此分类中的函数建议在数据包加载（重载）时执行。</b></span>

### 关闭特殊伤害

函数用法：`/function dfl:start/disable_special_damage`

- 摔落伤害；
- 火焰伤害；
- 冰冻伤害；
- 溺水伤害。

### 固定重生点为 0 0

函数用法：`/function dfl:start/set_world_spawn`

- 将世界重生点设为 0 0 0；
- 将重生点半径设为 0；
- 此时玩家会固定重生在坐标 0 0 的最高方块上。

### 开启死亡榜

函数用法：`/function dfl:start/show/enable_death_scoreboard`

- 创建名为 death 的记分项；
- 会在屏幕右侧显示死亡次数；
- 玩家死亡次数从高到低排序；
- 注意：首次开启时不会显示死亡榜，在任意玩家死亡后方可显示。

### 显示玩家血量

函数用法：`/function dfl:start/show/display_health_below_name`

- 创建名为 health 的记分项；
- 会在玩家 ID 下方显示玩家血量；
- 距离稍远会不显示（只显示玩家 ID）；
- 注意：首次开启时会显示血量为 0，在数值更新（如受伤）后方可显示。

### 显示玩家经验等级

函数用法：`/function dfl:start/show/display_level_in_tab`

- 创建名为 level 的记分项；
- 会在 Tab 栏（玩家列表栏）显示每名玩家的经验等级；
- 注意：首次开启时会显示经验等级为 0，在数值更新（如升级）后方可显示。

### 显示玩家血条

函数用法：`/function dfl:start/show/display_health_in_tab`

- 创建名为 health 的记分项；
- 会在 Tab 栏（玩家列表栏）显示每名玩家的血条。
- 效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第1张图片](https://zh.minecraft.wiki/images/Scoreboard_Display_List_Hearts.gif)

### 快速新建队伍

函数用法：`/function dfl:start/create_teams {team_blue:"blue",team_red:"red",prefix_blue:"blue",prefix_red:"red"}`

- 创建两个队伍，名称为 {team_blue} 和 {team_red}；
- 颜色分别为 blue 和 red；
- 禁用同队伍玩家互伤；
- 玩家只能与非同队的实体碰撞；
- 玩家名称前缀分别为 {prefix_blue}_ 和 {prefix_red}_。

## Tick

<span style="color:red;"><b>此分类中的函数建议每 Tick 执行一次。</b></span>

### 软封禁玩家

函数用法：`/function dfl:tick/soft_ban_player {title:"封禁理由",subtitle:"备注"}`

- 注意：此函数执行者必须为要**被封禁**的玩家，可以使用 `/execute` 命令；
- 通过不断 tp 玩家到 0 0 0，将模式设为冒险以及不断给予玩家负面 Buff 来实现软封禁；
- 必须每 Tick 执行一次；
- 标题为 {title}，副标题为 {subtitle}；
- 范例：`/execute as @a[tag=ban] run function dfl:tick/soft_ban_player {title:"封禁理由",subtitle:"备注"}`。

效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第2张图片](https://i.mcmod.cn/editor/upload/20241124/1732460069_829263_PTUj.webp)

### 信标鞘翅起飞

函数用法：`/function dfl:tick/beacon_fly`

- 信标下有铁块、金块、绿宝石块、钻石块或下界合金块时会将玩家向上传送（不传送旁观者）；
- 高度依次为 20、40、60、80、100 格；
- 相同的方块可以叠加高度（最高为 400 格，使用四个下界合金块），如果方块不同，将以距离信标最近的方块为准。

### 一键负面 Buff

函数用法：`/function dfl:tick/apply_debuffs`

给予**函数执行者**以下 Debuff：

1. slowness
2. mining_fatigue
3. nausea
4. darkness
5. hunger
6. weakness
7. poison
8. unluck
9. trial_omen

### 铁块电梯

函数用法：`/function dfl:tick/iron_block_elevator`

- 玩家站在上下两个铁块之间时向上传送；
- 最远传送距离为 6 格，即两个铁块的最大间距为 5 格；
- 不会传送旁观者；
- 会传送生物及非生物实体。

### 实体过多清除实体

函数用法：`/function dfl:tick/kill_excess_entities {num:"1000"}`

- 在非玩家实体数大于 {num} 时清除所有非玩家实体；
- 不会清理带有 need 标签的实体；
- 带有 need 标签的实体不会计入此处的实体数；
- 创建名为 dfl_scoreboard 的记分项。
- 执行后会在聊天栏提示，效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第3张图片](https://i.mcmod.cn/editor/upload/20241128/1732782965_829263_DgBT.webp)

### 实体密度过大清除实体

函数用法：`/function dfl:tick/kill_by_density {num:"50"}`

前置函数：`/function dfl:lib/get_entity_density`

- 令所有实体在附近 10 格内实体数大于 {num} 时清除这些实体；
- 不会杀死玩家；
- 不会杀死村民；
- 不会杀死带有 need 标签的实体；
- 不会在聊天栏留下痕迹。

### Minecraft is too hard

函数用法：`/function dfl:tick/mith`

- 开启死亡不掉落；
- 给予执行者夜视；
- 给予执行者发光；
- 移除执行者的黑暗效果。

### 显示实体数

函数用法：`/function dfl:tick/display_entity_count`

前置函数：`/function dfl:lib/get_entity_count`

- 在玩家动作栏（快捷栏上方）显示实时实体数量。
- 效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第4张图片](https://i.mcmod.cn/editor/upload/20241124/1732462874_829263_RoxS.webp)

### 关闭玩家友伤及碰撞

函数用法：`/function dfl:tick/disable_friendly_fire`

- 添加名为 dfl 的队伍，并将所有玩家加入此队伍；
- 注意：由于同一实体无法加入多个队伍，如果想要使用玩家组队功能请勿启用此函数；
- 关闭队伍友伤；
- 关闭队伍内碰撞；
- 如果不是每 Tick 运行一次此函数，请确保在每位新玩家加入后运行一次此函数。

### TNT 实体密度过大清除 TNT

函数用法：`/function dfl:tick/kill_tnt_by_density {num:"200"}`

- TNT 附近五格内的 TNT 实体数大于 {num} 时清除这些 TNT 实体；
- 创建名为 dfl_tntdensity 的记分项。

### 无权限玩家自杀

函数用法：`/function dfl:tick/trigger_suicide`

- 创建名为 kill 的记分项；
- 输入 `/trigger kill` 以自杀（此指令不需要任何权限）。

### 大范围替换方块

函数用法：`/function dfl:tick/change_block {new:"glass",old:"stone",num:"30"}`

- 将玩家附近 {num}3 *8 范围内的 {old} 替换为 {new}；
- 将游戏规则 commandModificationBlockLimit 修改为 2147483647。

### 永昼+永晴

函数用法：`/function dfl:tick/always_sunny`

- 关闭昼夜更替；
- 关闭天气更替；
- 将时间设为白天；
- 将天气设为晴朗。

### 清除单个物品并执行命令

函数用法：`/function dfl:tick/clear_and_execute_single {name:"stone",run:"tp ~ 100 ~"}`

- 清除所有玩家的一个 {name} 并执行 {run}；
- 注意：参数 run 中的命令首尾不能有多余的空格，命令前不能有斜杠。

### 清除指定物品并执行多次命令

函数用法：`/function dfl:tick/clear_and_execute_multiple {name:"sand",run:"give @s anvil"}`

- 清除函数执行者的所有 {name} 并执行对应次数的 {run}**（在同一 tick 之内）**；
- 注意：参数 run 中的命令首尾不能有多余的空格，命令前不能有斜杠。

### 保持拥有某物品

函数用法：`/function dfl:tick/maintain_item_count {name:"slime_block",num:"64"}`

- 让命令执行者刚好拥有指定数量的物品。

### 自救平台

函数用法：`/function dfl:tick/create_rescue_platform`

前置函数：`/function dfl:lib/get_game_time`

- 创建名为 dfl_slime_marker_temp 的记分项，用于储存史莱姆平台生成时的时间；
- 在拥有 dfl_slime 标签的玩家脚下生成一个 3*3 的史莱姆平台并移除标签，史莱姆平台只能覆盖掉空气方块；
- 会在 `<slime_time 的 dfl_scoreboard 记分项>` tick 后清除史莱姆平台位置上的史莱姆方块；
- slime_time 的 dfl_scoreboard 记分项会在没有赋值时被设为 200，即 10s；
- 在玩家生成平台时的位置附近 2 格内的史莱姆方块掉落物会被清除。

### 物品转化为经验

函数用法：`/function dfl:tick/convert_items_to_xp {name:"tnt",xp:"1"}`

- 将函数执行者身上的每个 {name} 转化为 {xp} 点经验值。

### tpa

函数用法：`/function dfl:tick/teleport_request`

前置函数：`/function dfl:lib/generate_player_id`

- 创建名为 tpa 和 tpa_enable 的记分项；
- 输入 `/trigger tpa set <玩家在 dfl_playerid 记分项中的 id，可以通过 Tab 查看>` 以传送到对应玩家；
- 输入 `/trigger tpa_enable` 以允许其他玩家传送到自己，无法撤销（如不执行此命令则其他所有玩家均无法传送到此玩家），如果在此命令中使用了 set 设为其他值，则不会有任何效果（不会允许其他玩家传送到自己），仍然可以再次通过 set 来设为 1 以允许其他玩家传送到自己；
- 如果要传送的玩家不存在或未允许其他玩家传送到自己，则会在对应玩家 id 可被传送后传送到对应玩家，期间仍可随意更改 tpa 对象。

### 自动冶炼

函数用法：`/function auto_smelt:smelt {input:"raw_iron",output:"iron_ingot"}`

- 消耗 {input} 并给予函数执行者对应数量的 {output}；
- 烧炼一个物品会消耗 1 点经验，如果玩家没有经验则不会烧炼物品；
- 如果背包中同时拥有三种支持的燃料，会同时消耗这些燃料；
- 消耗煤炭块后可以同时烧炼 9 个物品，并扣除 9 点经验。

## Timer

<span style="color:red;"><b>此分类中的函数建议每间隔一段时间后执行。（可以使用 [/schedule](https://zh.minecraft.wiki/w/%E5%91%BD%E4%BB%A4/schedule "跳转到wiki查看此命令用法") 命令）</b></span>

### 清理掉落物

函数用法：`/function dfl:timer/clear_items`

- 创建名为 dfl_scoreboard 的记分项；
- 清除所有掉落物并通过 `/tellraw` 输出清除的掉落物数量；
- 不会清除带有 need 标签的掉落物。
- 效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第5张图片](https://i.mcmod.cn/editor/upload/20241125/1732464116_829263_BxRx.webp)

### 显示实体数量信息

函数用法：`/function dfl:timer/display_entity_info`

前置函数：

`/function dfl:lib/get_entity_count`

`/function dfl:lib/get_item_count`

`/function dfl:lib/non_player_entities`

此函数效果如下：

![[DFL]数据包函数支持库 (datapack function library)-第6张图片](https://i.mcmod.cn/editor/upload/20241125/1732464350_829263_dYNP.webp)

## Lib

<span style="color:red;"><b>此分类中的函数单独执行没有任何效果或不符合上述分类。</b></span>

### 强制死亡掉落

函数用法：`/function dfl:lib/force_death_drops`

1. 关闭死亡不掉落。
2. 杀死函数执行者。
3. 开启死亡不掉落。

### 获取实体数

函数用法：`/function dfl:lib/get_entity_count`

- 创建名为 dfl_scoreboard 的记分项；
- 将实体数量写入 entity 的 dfl_scoreboard 记分项。

### 获取实体密度

函数用法：`/function dfl:lib/get_entity_density`

- 创建名为 dfl_density 的记分项；
- 将所有实体附近 10 格内的实体数写入此实体的记分项。

### 获取掉落物数

函数用法：`/function dfl:lib/get_item_count`

- 创建名为 dfl_scoreboard 的记分项；
- 将掉落物数量写入 item 的 dfl_scoreboard 记分项。

### 获取非玩家实体数

函数用法：`/function dfl:lib/non_player_entities`

- 创建名为 dfl_scoreboard 的记分项；
- 将非玩家实体数量写入 other_entity 的 dfl_scoreboard 记分项。

### 获取游戏天数

函数用法：`/function dfl:lib/get_game_day`

- 创建名为 dfl_scoreboard 的记分项；
- 将游戏天数写入 day 的 dfl_scoreboard 记分项；
- 游戏天数 - 昼夜更替时已流逝的游戏天数，为昼夜更替时间除以 24000 取其整数商的结果。

### 获取当日时间

函数用法：`/function dfl:lib/get_day_time`

- 创建名为 dfl_scoreboard 的记分项；
- 将当日时间写入 daytime 的 dfl_scoreboard 记分项；
- 当日时间 - 自当天日出后流逝的游戏刻数，为昼夜更替时间除以 24000 取余数的结果。

### 用玻璃包围玩家

函数用法：`/function dfl:lib/create_glass_box`

- 在命令执行者处生成 5*5 的空心玻璃立方体。

### 获取游戏时间

函数用法：`/function dfl:lib/get_game_time`

- 创建名为 dfl_scoreboard 的记分项；
- 将游戏时间写入 gametime 的 dfl_scoreboard 记分项；
- 游戏时间 - 世界总共流逝的游戏刻数。

### 获取玩家数

函数用法：`/function dfl:lib/get_player_count`

- 创建名为 dfl_scoreboard 的记分项；
- 将玩家数量写入 players 的 dfl_scoreboard 记分项。

### 修改最大生命值

函数用法：`/function dfl:lib/change_max_health {num:"100"}`

- 将所有玩家的最大生命值设为 {num}。

### 生成 UID

函数用法：`/function dfl:lib/generate_player_id`

- 创建名为 dfl_playerid 和 dfl_scoreboard 的记分项；
- 在 playerid_temp 的 dfl_scoreboard 记分项中储存 UID 使用进度；
- 为所有玩家在 dfl_playerid 记分项中设置唯一且不变的 UID；
- UID 为 1 及以上的数字，最早进入服务器的玩家数字最小，以此类推；
- 如果函数执行时服务器内玩家大于一位，则这些玩家的 UID 生成顺序随机。

### 检测物品数量

函数用法：`/function dfl:lib/count_items {name:"stone"}`

- 创建名为 dfl\_{name}\_num 的记分项；
- 将所有玩家的 {name} 数量写入各自的此记分项。

### 批量生成假人

函数用法：`/function dfl:lib/spawn_dummies`

- 以玩家为坐标基准生成 100 个 Carpet 假人。

# 对话框说明

## GNU GPL 协议原文

对话框用法：`/dialog show dfl:gpl`

- 此对话框包含 GNU GPL v3.0 协议原文。

## GNU LGPL 协议原文

对话框用法：`/dialog show dfl:lgpl`

- 此对话框包含 GNU LGPL v3.0 协议原文。
