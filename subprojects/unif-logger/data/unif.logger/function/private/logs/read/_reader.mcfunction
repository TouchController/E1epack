function unif.logger:private/logger/_printer with storage unif.logger:cache Cache.Logs[0]
function unif.logger:private/injected_logger/_injected_printer with storage unif.logger:cache Cache.Logs[0]

data remove storage unif.logger:cache Cache.Logs[0]

execute store result score $logs unif.10000 run data get storage unif.logger:cache Cache.Logs

execute if score $logs unif.10000 matches 1.. run function unif.logger:private/logs/read/_reader