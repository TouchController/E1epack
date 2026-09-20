$data modify storage replace_block:data settings set from storage $(storage) replace_block
# 配置检测成功就透传call_main返回值
execute if function replace_block:api/private/check_config \
    summon marker run return run \
    function replace_block:api/private/call_main with storage replace_block:data settings
# 配置无效，清理并退出
data remove storage replace_block:data temp
data remove storage replace_block:data settings
scoreboard objectives remove rb.tmp.config_check
return fail
