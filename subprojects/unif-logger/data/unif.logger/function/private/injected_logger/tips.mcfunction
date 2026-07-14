data remove storage unif.logger:cache Cache.Logger

# Message, 放在这而不是 message_process 中为了防止过度转义
$data modify storage unif.logger:cache Cache.Logger.Message set value '$(msg)'

# 数据处理
$function unif.logger:private/cache/injected_message_process {"namespace":"$(namespace)","level":"TIPS","levelColor":"gray"}

# 打印
function unif.logger:private/injected_logger/_injected_printer with storage unif.logger:cache Cache.Logger