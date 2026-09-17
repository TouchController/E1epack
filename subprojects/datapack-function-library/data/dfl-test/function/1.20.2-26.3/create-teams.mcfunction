# 测试 create_teams 函数
function dfl:start/create_teams {team_blue:"test_blue",team_red:"test_red",prefix_blue:"[B]",prefix_red:"[R]"}

# 召唤测试实体并加入队伍
summon minecraft:armor_stand ~ ~ ~ {NoGravity:1b,Tags:["team_test"]}
team join test_blue @e[tag=team_test]

# 验证实体已在队伍中
execute if entity @e[tag=team_test,team=test_blue] run function dfl:test/pass
