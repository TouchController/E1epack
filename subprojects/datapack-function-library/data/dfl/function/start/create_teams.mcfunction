## 快速新建队伍，禁用友伤和碰撞

# 创建队伍
$team add $(team_blue)
$team add $(team_red)

# 配置蓝队属性
$team modify $(team_blue) color blue
$team modify $(team_blue) friendlyFire false
$team modify $(team_blue) collisionRule pushOwnTeam
$team modify $(team_blue) prefix "$(prefix_blue)_"

# 配置红队属性
$team modify $(team_red) color red
$team modify $(team_red) friendlyFire false
$team modify $(team_red) collisionRule pushOwnTeam
$team modify $(team_red) prefix "$(prefix_red)_"
#选项为displayName时：
#<displayName>：component - 指定队伍被显示时的名称。必须为文本组件。
#选项为color时：
#<value>：color - 必须为文本组件。
#默认为reset。若为reset，名称将以默认颜色与格式显示。
#选项为friendlyFire时：
#<allowed>：boolean - 必须为文本组件。
#true - （默认）启用同队伍玩家互伤。
#false - 禁用同队伍玩家互伤。
#选项为seeFriendlyInvisibles时：
#<allowed>：boolean - 必须为文本组件。
#true - （默认）玩家观察同队伍的隐身玩家时显示为半透明。
#false - 玩家无法看到同队伍的隐身玩家。
#选项为nametagVisibility时：
#never - 玩家头上的名称不被任何玩家看见。
#hideForOtherTeams - 玩家头上的名称只被同队伍玩家看见。
#hideForOwnTeam - 玩家头上的名称只被非同队玩家看见。
#always - （默认）玩家头上的名称能被任何玩家看见。
#选项为deathMessageVisibility时：
#never - 对所有玩家隐藏死亡消息。
#hideForOtherTeams - 对非同队玩家隐藏死亡消息。
#hideForOwnTeam - 对同队伍玩家隐藏死亡消息。
#always - （默认）死亡消息对所有玩家可见。
#选项为collisionRule时：
#always - （默认）正常碰撞。
#never - 该队伍中的实体不可碰撞。
#pushOtherTeams - 该队伍中的实体只能与同队伍中的实体碰撞，与字面意义相反。[1]
#pushOwnTeam - 该队伍中的实体只能与非同队的实体碰撞，与字面意义相反。[1]
#选项为prefix时：
#<prefix>：component - 指定将显示的前缀。必须为文本组件。
#选项为suffix时：
#<suffix>：component - 指定将显示的后缀。必须为文本组件。
