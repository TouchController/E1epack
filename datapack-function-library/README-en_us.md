# Preface

*This datapack is licensed under the [GNU LESSER GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/lgpl-3.0.txt "Go to this open source license page").*

**This datapack provides developers with some practical functions (and some dialogs), compatible with all versions of Minecraft (except for versions that cannot install datapacks).**

**However, due to the large number of commands involved in the datapack, lower versions may not be able to use all functions. The applicable versions of all functions will not be specified below.**

**Please install the resource pack at the same time to use localized content (v3.2+). Otherwise, the datapack language will default to zh_cn.**

**The mod version of this datapack is packaged through Modrinth, and the content is exactly the same as the datapack version, but it is not necessarily the latest version. Please try to use the datapack version.**

**This datapack provides a `dfl:dfl_enable` function, which can set the score of all entities in this scoreboard to 1, which is convenient for datapacks or mods that depend on this datapack to detect whether this datapack is loaded.**

**Example:**

```mcfunction
#Execute when the datapack is loaded:
scoreboard objectives add dfl_scoreboard dummy
scoreboard players set dfl_enable dfl_scoreboard 0
#If not loaded:
function dfl:dfl_enable
execute unless score dfl_enable dfl_scoreboard matches 1
#If loaded:
function dfl:dfl_enable
execute if score dfl_enable dfl_scoreboard matches 1
```

**Note: Some functions have "prerequisite functions" attached to their usage. These functions must be executed once before executing them.**

**Some function usages are followed by `{xx:"xx"}`. These functions are [macro functions](https://zh.minecraft.wiki/w/Java%E7%89%88%E5%87%BD%E6%95%B0#%E5%AE%8F). When using them, you need to pass parameters through `{<parameter name>:"<content>"}` (the parameters in the usage are the recommended parameters tested by the author during development, or the parameters used by the author for testing). The parameter name (such as num) is expressed as: {num} in the text. The parameter format can refer to the function usage, and special formats will be explained.**

If you encounter any problems, please click [here](https://github.com/TouchController/E1epack/issues/new/choose) to give feedback.

---

# Function Description

## Start

<span style="color:red;"><b>Functions in this category are recommended to be executed when the datapack is loaded (reloaded).</b></span>

### Disable Special Damage

Function usage: `/function dfl:start/disable_special_damage`

- Fall damage;
- Fire damage;
- Freeze damage;
- Drowning damage.

### Fix the respawn point to 0 0

Function usage: `/function dfl:start/set_world_spawn`

- Set the world respawn point to 0 0 0;
- Set the respawn point radius to 0;
- At this time, the player will be fixed to respawn on the highest block at coordinate 0 0.

### Enable death leaderboard

Function usage: `/function dfl:start/show/enable_death_scoreboard`

- Create a scoreboard item named death;
- The number of deaths will be displayed on the right side of the screen;
- The number of player deaths is sorted from high to low;
- Note: The death leaderboard will not be displayed when it is first enabled, and it will be displayed only after any player dies.

### Display player health

Function usage: `/function dfl:start/show/display_health_below_name`

- Create a scoreboard item named health;
- The player's health will be displayed below the player's ID;
- It will not be displayed if the distance is slightly far (only the player's ID is displayed);
- Note: When it is first enabled, the health will be displayed as 0, and it will be displayed only after the value is updated (such as being injured).

### Display player experience level

Function usage: `/function dfl:start/show/display_level_in_tab`

- Create a scoreboard item named level;
- The experience level of each player will be displayed in the Tab bar (player list bar);
- Note: When it is first enabled, the experience level will be displayed as 0, and it will be displayed only after the value is updated (such as leveling up).

### Display player health bar

Function usage: `/function dfl:start/show/display_health_in_tab`

- Create a scoreboard item named health;
- The health bar of each player will be displayed in the Tab bar (player list bar).
- The effect is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 1](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/Scoreboard_Display_List_Hearts.gif)

### Quickly create a new team

Function usage: `/function dfl:start/create_teams {team_blue:"blue",team_red:"red",prefix_blue:"blue",prefix_red:"red"}`

- Create two teams named {team_blue} and {team_red};
- The colors are blue and red respectively;
- Disable friendly fire for players in the same team;
- Players can only collide with entities not on the same team;
- The player name prefixes are {prefix_blue}_ and {prefix_red}_ respectively.

## Tick

<span style="color:red;"><b>Functions in this category are recommended to be executed every Tick.</b></span>

### Soft ban player

Function usage: `/function dfl:tick/soft_ban_player {title:"Ban Reason",subtitle:"Note"}`

- Note: The executor of this function must be the player to be **banned**, you can use the `/execute` command;
- Realize a soft ban by continuously tp the player to 0 0 0, setting the mode to adventure, and continuously giving the player negative buffs;
- Must be executed every Tick;
- Title is {title}, subtitle is {subtitle};
- Example: `/execute as @a[tag=ban] run function dfl:tick/soft_ban_player {title:"Ban Reason",subtitle:"Note"}`.

The effect is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 2](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/tick.ban.png)

### Beacon elytra take-off

Function usage: `/function dfl:tick/beacon_fly`

- When there are iron blocks, gold blocks, emerald blocks, diamond blocks or netherite blocks under the beacon, the player will be teleported upwards (spectators will not be teleported);
- The heights are 20, 40, 60, 80, and 100 blocks in order;
- The same blocks can be stacked to increase the height (the highest is 400 blocks, using four netherite blocks). If the blocks are different, the block closest to the beacon will be used.

### One-click negative Buff

Function usage: `/function dfl:tick/apply_debuffs`

Give the **function executor** the following Debuffs:

1. slowness
2. mining_fatigue
3. nausea
4. darkness
5. hunger
6. weakness
7. poison
8. unluck
9. trial_omen

### Iron block elevator

Function usage: `/function dfl:tick/iron_block_elevator`

- Teleport the player upwards when standing between two iron blocks, one above the other;
- The maximum teleportation distance is 6 blocks, that is, the maximum distance between two iron blocks is 5 blocks;
- Will not teleport spectators;
- Will teleport creatures and non-creature entities.

### Clear entities if there are too many

Function usage: `/function dfl:tick/kill_excess_entities {num:"1000"}`

- Clear all non-player entities when the number of non-player entities is greater than {num};
- Will not clear entities with the need tag;
- Entities with the need tag will not be counted in the number of entities here;
- Create a scoreboard item named dfl_scoreboard.
- After execution, a prompt will be displayed in the chat bar, the effect is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 3](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/tick.kill.png)

### Clear entities if the entity density is too high

Function usage: `/function dfl:tick/kill_by_density {num:"50"}`

Prerequisite function: `/function dfl:lib/get_entity_density`

- Make all entities clear these entities when the number of entities within 10 blocks is greater than {num};
- Will not kill players;
- Will not kill villagers;
- Will not kill entities with the need tag;
- Will not leave traces in the chat bar.

### Minecraft is too hard

Function usage: `/function dfl:tick/mith`

- Enable keep inventory on death;
- Give the executor night vision;
- Give the executor glowing;
- Remove the executor's darkness effect.

### Display the number of entities

Function usage: `/function dfl:tick/display_entity_count`

Prerequisite function: `/function dfl:lib/get_entity_count`

- Display the real-time number of entities in the player's action bar (above the shortcut bar).
- The effect is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 4](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/tick.show_entity.png)

### Disable player friendly fire and collision

Function usage: `/function dfl:tick/disable_friendly_fire`

- Add a team named dfl and add all players to this team;
- Note: Since the same entity cannot join multiple teams, please do not enable this function if you want to use the player team function;
- Disable team friendly fire;
- Disable collision within the team;
- If this function is not run every Tick, please make sure to run this function once after each new player joins.

### Clear TNT if the TNT entity density is too high

Function usage: `/function dfl:tick/kill_tnt_by_density {num:"200"}`

- Clear these TNT entities when the number of TNT entities within five blocks of the TNT is greater than {num};
- Create a scoreboard item named dfl_tntdensity.

### Suicide for players without permission

Function usage: `/function dfl:tick/trigger_suicide`

- Create a scoreboard item named kill;
- Enter `/trigger kill` to commit suicide (this command does not require any permission).

### Replace blocks in a large area

Function usage: `/function dfl:tick/change_block {new:"glass",old:"stone",num:"30"}`

- Replace {old} with {new} in a {num}3 *8 range around the player;
- Change the game rule commandModificationBlockLimit to 2147483647.

### Always day + always sunny

Function usage: `/function dfl:tick/always_sunny`

- Turn off the day-night cycle;
- Turn off weather changes;
- Set the time to day;
- Set the weather to clear.

### Clear a single item and execute a command

Function usage: `/function dfl:tick/clear_and_execute_single {name:"stone",run:"tp ~ 100 ~"}`

- Clear one {name} from all players and execute {run};
- Note: There should be no extra spaces at the beginning and end of the command in the run parameter, and there should be no slash before the command.

### Clear specified items and execute commands multiple times

Function usage: `/function dfl:tick/clear_and_execute_multiple {name:"sand",run:"give @s anvil"}`

- Clear all {name} of the function executor and execute the corresponding number of {run} **(within the same tick)**;
- Note: There should be no extra spaces at the beginning and end of the command in the run parameter, and there should be no slash before the command.

### Keep having an item

Function usage: `/function dfl:tick/maintain_item_count {name:"slime_block",num:"64"}`

- Let the command executor have exactly the specified number of items.

### Self-rescue platform

Function usage: `/function dfl:tick/create_rescue_platform`

Prerequisite function: `/function dfl:lib/get_game_time`

- Create a scoreboard item named dfl_slime_marker_temp to store the time when the slime platform is generated;
- Generate a 3*3 slime platform under the player with the dfl_slime tag and remove the tag. The slime platform can only cover air blocks;
- The slime blocks at the slime platform position will be cleared after `<slime_time's dfl_scoreboard scoreboard item>` ticks;
- The dfl_scoreboard scoreboard item of slime_time will be set to 200 when it is not assigned, which is 10s;
- The slime block drops within 2 blocks of the player's position when the platform is generated will be cleared.

### Convert items to experience

Function usage: `/function dfl:tick/things_to_xp {name:"tnt",xp:"1"}`

- Convert each {name} on the function executor into {xp} experience points.

### tpa

Function usage: `/function dfl:tick/tpa`

Prerequisite function: `/function dfl:lib/generate_player_id`

- Create scoreboard items named tpa and tpa_enable;
- Enter `/trigger tpa set <player's id in the dfl_playerid scoreboard, which can be viewed through Tab>` to teleport to the corresponding player;
- Enter `/trigger tpa_enable` to allow other players to teleport to themselves, which cannot be revoked (if this command is not executed, all other players cannot teleport to this player). If set is used in this command to set other values, there will be no effect (other players will not be allowed to teleport to themselves). You can still set it to 1 again through set to allow other players to teleport to themselves;
- If the player to be teleported does not exist or has not allowed other players to teleport to themselves, they will be teleported to the corresponding player after the corresponding player id can be teleported. During this period, the tpa object can still be changed at will.

### Auto-smelting

Function usage: `/function auto_smelt:smelt {input:"raw_iron",output:"iron_ingot"}`

- Consume {input} and give the function executor the corresponding amount of {output};
- Smelting an item consumes 1 experience point. If the player has no experience, the item will not be smelted;
- If the backpack has three supported fuels at the same time, these fuels will be consumed at the same time;
- After consuming a coal block, 9 items can be smelted at the same time, and 9 experience points will be deducted.

## Timer

<span style="color:red;"><b>Functions in this category are recommended to be executed after a period of time. (You can use the [/schedule](https://zh.minecraft.wiki/w/%E5%91%BD%E4%BB%A4/schedule "Go to the wiki to see the usage of this command") command)</b></span>

### Clean up dropped items

Function usage: `/function dfl:timer/clear_items`

- Create a scoreboard item named dfl_scoreboard;
- Clear all dropped items and output the number of cleared dropped items through `/tellraw`;
- Will not clear dropped items with the need tag.
- The effect is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 5](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/redstone.kill_item.png)

### Display entity quantity information

Function usage: `/function dfl:timer/display_entity_info`

Prerequisite functions:

`/function dfl:lib/get_entity_count`

`/function dfl:lib/get_item_count`

`/function dfl:lib/non_player_entities`

The effect of this function is as follows:

![[DFL] Datapack Function Support Library (datapack function library)-Image 6](https://raw.githubusercontent.com/TouchController/E1epack/main/datapack-function-library/README/redstone.show_entity.png)

## Lib

<span style="color:red;"><b>Functions in this category have no effect when executed alone or do not fit into the above categories.</b></span>

### Force death drop

Function usage: `/function dfl:lib/force_death_drops`

1. Turn off keep inventory on death.
2. Kill the function executor.
3. Turn on keep inventory on death.

### Get the number of entities

Function usage: `/function dfl:lib/get_entity_count`

- Create a scoreboard item named dfl_scoreboard;
- Write the number of entities to the dfl_scoreboard scoreboard item of entity.

### Get entity density

Function usage: `/function dfl:lib/get_entity_density`

- Create a scoreboard item named dfl_density;
- Write the number of entities within 10 blocks of all entities to the scoreboard item of this entity.

### Get the number of dropped items

Function usage: `/function dfl:lib/get_item_count`

- Create a scoreboard item named dfl_scoreboard;
- Write the number of dropped items to the dfl_scoreboard scoreboard item of item.

### Get the number of non-player entities

Function usage: `/function dfl:lib/non_player_entities`

- Create a scoreboard item named dfl_scoreboard;
- Write the number of non-player entities to the dfl_scoreboard scoreboard item of other_entity.

### Get the number of game days

Function usage: `/function dfl:lib/get_game_day`

- Create a scoreboard item named dfl_scoreboard;
- Write the number of game days to the dfl_scoreboard scoreboard item of day;
- Game days - the number of game days that have passed during the day-night cycle, which is the result of dividing the day-night cycle time by 24000 and taking the integer quotient.

### Get the time of day

Function usage: `/function dfl:lib/get_day_time`

- Create a scoreboard item named dfl_scoreboard;
- Write the time of day to the dfl_scoreboard scoreboard item of daytime;
- Time of day - the number of game ticks that have passed since sunrise on that day, which is the result of dividing the day-night cycle time by 24000 and taking the remainder.

### Surround the player with glass

Function usage: `/function dfl:lib/create_glass_box`

- Generate a 5*5 hollow glass cube at the command executor.

### Get game time

Function usage: `/function dfl:lib/get_game_time`

- Create a scoreboard item named dfl_scoreboard;
- Write the game time to the dfl_scoreboard scoreboard item of gametime;
- Game time - the total number of game ticks that have passed in the world.

### Get the number of players

Function usage: `/function dfl:lib/get_player_count`

- Create a scoreboard item named dfl_scoreboard;
- Write the number of players to the dfl_scoreboard scoreboard item of players.

### Modify maximum health

Function usage: `/function dfl:lib/change_max_health {num:"100"}`

- Set the maximum health of all players to {num}.

### Generate UID

Function usage: `/function dfl:lib/generate_player_id`

- Create scoreboard items named dfl_playerid and dfl_scoreboard;
- Store the UID usage progress in the dfl_scoreboard scoreboard item of playerid_temp;
- Set a unique and immutable UID for all players in the dfl_playerid scoreboard;
- The UID is a number of 1 and above. The player who enters the server earliest has the smallest number, and so on;
- If there is more than one player in the server when the function is executed, the UID generation order of these players is random.

### Detect the number of items

Function usage: `/function dfl:lib/count_items {name:"stone"}`

- Create a scoreboard item named dfl\_{name}\_num;
- Write the number of {name} of all players to their respective scoreboard items.

### Batch generate dummies

Function usage: `/function dfl:lib/spawn_dummies`

- Generate 100 Carpet dummies based on the player's coordinates.

# Dialog Description

## GNU GPL License Text

Dialog usage: `/dialog show dfl:gpl`

- This dialog contains the original text of the GNU GPL v3.0 license.

## GNU LGPL License Text

Dialog usage: `/dialog show dfl:lgpl`

- This dialog contains the original text of the GNU LGPL v3.0 license.
