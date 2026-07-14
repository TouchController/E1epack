# 数据处理
function unif.logger:private/cache/remove_outdated
$function unif.logger:private/cache/message_process {"namespace":"$(namespace)","msg":"$(msg)","level":"DEBUG","levelColor":"yellow"}

# 写入游戏 Logs 内
data modify storage unif.logger:debug_logs Logs append from storage unif.logger:cache Cache.Logger

# 打印
execute as @a[tag=unif.debug] if score $level unif.logger matches ..1 run function unif.logger:private/logger/_printer with storage unif.logger:debug_logs Logs[-1]