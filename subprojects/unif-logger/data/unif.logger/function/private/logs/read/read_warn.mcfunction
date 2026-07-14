scoreboard objectives add unif.10000 dummy "Cache"
gamerule maxCommandChainLength 2147483647

data remove storage unif.logger:cache Cache.Logs

data modify storage unif.logger:cache Cache.Logs set from storage unif.logger:warn_logs Logs

function unif.logger:private/logs/read/_reader

scoreboard objectives remove unif.10000
gamerule maxCommandChainLength 65536