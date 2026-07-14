scoreboard objectives add unif.10000 dummy "Cache"
gamerule minecraft:max_command_sequence_length 2147483647

data remove storage unif.logger:cache Cache.Logs

data modify storage unif.logger:cache Cache.Logs set from storage unif.logger:logs Logs

function unif.logger:private/logs/read/_reader

scoreboard objectives remove unif.10000
gamerule minecraft:max_command_sequence_length 65536