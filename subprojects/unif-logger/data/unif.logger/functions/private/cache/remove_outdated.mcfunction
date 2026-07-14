# 删除过时数据
scoreboard objectives add unif.10000 dummy "Cache"

## Debug
execute store result score $debug_logs unif.10000 run data get storage unif.logger:debug_logs Logs
execute if score $debug_logs unif.10000 matches 512.. run data remove storage unif.logger:debug_logs Logs[0]

## Info
execute store result score $info_logs unif.10000 run data get storage unif.logger:info_logs Logs
execute if score $info_logs unif.10000 matches 512.. run data remove storage unif.logger:info_logs Logs[0]

## Warn
execute store result score $warn_logs unif.10000 run data get storage unif.logger:warn_logs Logs
execute if score $warn_logs unif.10000 matches 512.. run data remove storage unif.logger:warn_logs Logs[0]

## Error
execute store result score $error_logs unif.10000 run data get storage unif.logger:error_logs Logs
execute if score $error_logs unif.10000 matches 512.. run data remove storage unif.logger:error_logs Logs[0]

## All
execute store result score $logs unif.10000 run data get storage unif.logger:logs Logs
execute if score $logs unif.10000 matches 1024.. run data remove storage unif.logger:logs Logs[0]