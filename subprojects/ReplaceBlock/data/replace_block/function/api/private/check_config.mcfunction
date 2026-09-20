## ReplaceBlock 配置参数验证函数

scoreboard objectives remove rb.tmp.config_check
scoreboard objectives add rb.tmp.config_check dummy

# 检查基础配置参数
   # 验证 settings 存储是否存在
execute unless data storage replace_block:data settings run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到调用参数',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings run \
    return fail

   # 验证必需参数是否存在
execute unless data storage replace_block:data settings.replace_pairs run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 replace_pairs',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.replace_pairs run \
    return fail

execute unless data storage replace_block:data settings.dimensions run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 dimensions',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.dimensions run \
    return fail

execute unless data storage replace_block:data settings.search_range run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 search_range',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.search_range run \
    return fail

execute unless data storage replace_block:data settings.success_threshold run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 success_threshold',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.success_threshold run \
    return fail

# 验证替换对数组参数
   # 对 replace_pairs 数组计数，并对包含指定字段的元素计数
execute store result score check_config.replace_pairs rb.tmp.config_check \
    if data storage replace_block:data settings.replace_pairs[]

    # replace_pairs 为空报错
execute if score check_config.replace_pairs rb.tmp.config_check matches 0 run \
    function #unif.logger:logger/v1/error \
    {"msg":'replace_pairs 为空',"namespace":"ReplaceBlock"}
execute if score check_config.replace_pairs rb.tmp.config_check matches 0 run \
    return fail

execute store result score check_config.target_block rb.tmp.config_check \
    if data storage replace_block:data settings.replace_pairs[].target_block
execute store result score check_config.replace_with rb.tmp.config_check \
    if data storage replace_block:data settings.replace_pairs[].replace_with

   # 验证包含字段的元素数量等于数组长度
execute unless score check_config.replace_pairs rb.tmp.config_check = check_config.target_block rb.tmp.config_check run \
    function #unif.logger:logger/v1/error \
    {"msg":'replace_pairs 中缺少参数 target_block',"namespace":"ReplaceBlock"}
execute unless score check_config.replace_pairs rb.tmp.config_check = check_config.replace_with rb.tmp.config_check run \
    function #unif.logger:logger/v1/error \
    {"msg":'replace_pairs 中缺少参数 replace_with',"namespace":"ReplaceBlock"}

execute unless score check_config.replace_pairs rb.tmp.config_check = check_config.target_block rb.tmp.config_check run \
    return fail
execute unless score check_config.replace_pairs rb.tmp.config_check = check_config.replace_with rb.tmp.config_check run \
    return fail

# 验证维度配置参数
   # 对 dimensions 数组计数，并对包含指定字段的元素计数
execute store result score check_config.dimensions rb.tmp.config_check \
    if data storage replace_block:data settings.dimensions[]

    # dimensions 为空报错
execute if score check_config.dimensions rb.tmp.config_check matches 0 run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 为空',"namespace":"ReplaceBlock"}
execute if score check_config.dimensions rb.tmp.config_check matches 0 run \
    return fail

execute store result score check_config.dimension rb.tmp.config_check \
    if data storage replace_block:data settings.dimensions[].dimension
execute store result score check_config.min_y rb.tmp.config_check \
    if data storage replace_block:data settings.dimensions[].min_y
execute store result score check_config.max_y rb.tmp.config_check \
    if data storage replace_block:data settings.dimensions[].max_y

   # 验证包含字段的元素数量等于数组长度
execute unless score check_config.dimensions rb.tmp.config_check = check_config.dimension rb.tmp.config_check run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 dimension',"namespace":"ReplaceBlock"}
execute unless score check_config.dimensions rb.tmp.config_check = check_config.min_y rb.tmp.config_check run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 min_y',"namespace":"ReplaceBlock"}
execute unless score check_config.dimensions rb.tmp.config_check = check_config.max_y rb.tmp.config_check run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 max_y',"namespace":"ReplaceBlock"}

execute unless score check_config.dimensions rb.tmp.config_check = check_config.dimension rb.tmp.config_check run \
    return fail
execute unless score check_config.dimensions rb.tmp.config_check = check_config.min_y rb.tmp.config_check run \
    return fail
execute unless score check_config.dimensions rb.tmp.config_check = check_config.max_y rb.tmp.config_check run \
    return fail

# 移除临时记分板
scoreboard objectives remove rb.tmp.config_check

# 校验通过
return 1
