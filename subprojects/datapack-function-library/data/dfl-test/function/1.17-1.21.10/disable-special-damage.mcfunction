# 测试 disable_special_damage 函数
function dfl:start/disable_special_damage

# 验证游戏规则已设置
execute store result score drowning testing run gamerule drowningDamage
execute store result score fall testing run gamerule fallDamage
execute store result score fire testing run gamerule fireDamage
execute store result score freeze testing run gamerule freezeDamage
execute if score drowning testing matches 0 if score fall testing matches 0 if score fire testing matches 0 if score freeze testing matches 0 run function dfl:test/pass
