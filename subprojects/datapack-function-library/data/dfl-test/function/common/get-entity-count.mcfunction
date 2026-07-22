summon creeper
summon creeper

function dfl:lib/get_entity_count

execute if score entity dfl_scoreboard matches 501.. run say [WARNING] [ENTITY_COUNT] >500
execute if score entity dfl_scoreboard matches 2..500 run function dfl:test/pass
