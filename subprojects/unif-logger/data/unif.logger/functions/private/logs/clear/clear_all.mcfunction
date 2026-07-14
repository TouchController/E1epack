data remove storage unif.logger:logs Logs
data remove storage unif.logger:debug_logs Logs
data remove storage unif.logger:info_logs Logs
data remove storage unif.logger:warn_logs Logs
data remove storage unif.logger:error_logs Logs

scoreboard players reset $debug_logs unif.10000
scoreboard players reset $info_logs unif.10000
scoreboard players reset $warn_logs unif.10000
scoreboard players reset $error_logs unif.10000
scoreboard players reset $logs unif.10000