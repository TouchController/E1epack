# 测试 always_sunny 函数
function dfl:tick/always_sunny

# 验证游戏规则已设置
execute store result score advance_time testing run gamerule minecraft:advance_time
execute store result score advance_weather testing run gamerule minecraft:advance_weather
execute if score advance_time testing matches 0 if score advance_weather testing matches 0 run function dfl:test/pass
