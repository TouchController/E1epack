# 初始化设置
execute unless score loaded alb.settings matches 1 run scoreboard players set countdown alb.settings 600
execute unless score loaded alb.settings matches 1 run scoreboard players set loaded alb.settings 1

scoreboard objectives add alb.temp dummy
    # 获取游戏时间
function dfl:lib/get_game_time
    # 写入临时记分板
scoreboard players operation gametime alb.temp = gametime dfl_scoreboard
    # 计算游戏时间与countdown的余数
scoreboard players operation gametime alb.temp %= countdown alb.settings
    # 如果余数为0，则执行主函数
execute if score gametime alb.temp matches 0 as @a at @s run function auto_lucky_block:setblock
    # 移除临时记分板
scoreboard objectives remove alb.temp
