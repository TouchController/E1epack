## ReplaceBlock 配置参数验证函数

scoreboard objectives remove rb.temp
scoreboard objectives add rb.temp dummy

# 检查基础配置参数
   # 验证 settings 存储是否存在
execute unless data storage replace_block:data settings run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到调用参数',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings run \
    scoreboard players set check.fail rb.return 1
execute unless data storage replace_block:data settings run \
    return fail

   # 验证必需参数是否存在
execute unless data storage replace_block:data settings.selector run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 selector',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.selector run \
    scoreboard players set check.fail rb.return 1
execute unless data storage replace_block:data settings.replace_pairs run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 replace_pairs',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.replace_pairs run \
    scoreboard players set check.fail rb.return 1
execute unless data storage replace_block:data settings.dimensions run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 dimensions',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.dimensions run \
    scoreboard players set check.fail rb.return 1
execute unless data storage replace_block:data settings.search_range run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 search_range',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.search_range run \
    scoreboard players set check.fail rb.return 1
execute unless data storage replace_block:data settings.success_threshold run \
    function #unif.logger:logger/v1/error \
    {"msg":'未找到参数 success_threshold',"namespace":"ReplaceBlock"}
execute unless data storage replace_block:data settings.success_threshold run \
    scoreboard players set check.fail rb.return 1

# 验证替换对数组参数
   # 检查 replace_pairs 数组及其字段
execute store result score check_config.replace_pairs rb.temp \
    if data storage replace_block:data settings.replace_pairs[]
execute store result score check_config.target_block rb.temp \
    if data storage replace_block:data settings.replace_pairs[].target_block
execute store result score check_config.replace_with rb.temp \
    if data storage replace_block:data settings.replace_pairs[].replace_with

   # 验证替换对数组完整性
execute unless score check_config.replace_pairs rb.temp = check_config.target_block rb.temp run \
    function #unif.logger:logger/v1/error \
    {"msg":'replace_pairs 中缺少参数 target_block',"namespace":"ReplaceBlock"}
execute unless score check_config.replace_pairs rb.temp = check_config.replace_with rb.temp run \
    function #unif.logger:logger/v1/error \
    {"msg":'replace_pairs 中缺少参数 replace_with',"namespace":"ReplaceBlock"}
execute unless score check_config.replace_pairs rb.temp = check_config.replace_pairs rb.temp run \
    scoreboard players set check.fail rb.return 1
execute unless score check_config.replace_pairs rb.temp = check_config.replace_with rb.temp run \
    scoreboard players set check.fail rb.return 1

# 验证维度配置参数
   # 检查 dimensions 数组及其字段
execute store result score check_config.dimensions rb.temp \
    if data storage replace_block:data settings.dimensions[]
execute store result score check_config.dimension rb.temp \
    if data storage replace_block:data settings.dimensions[].dimension
execute store result score check_config.min_y rb.temp \
    if data storage replace_block:data settings.dimensions[].min_y
execute store result score check_config.max_y rb.temp \
    if data storage replace_block:data settings.dimensions[].max_y

   # 验证维度配置完整性
execute unless score check_config.dimensions rb.temp = check_config.dimension rb.temp run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 dimension',"namespace":"ReplaceBlock"}
execute unless score check_config.dimensions rb.temp = check_config.min_y rb.temp run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 min_y',"namespace":"ReplaceBlock"}
execute unless score check_config.dimensions rb.temp = check_config.max_y rb.temp run \
    function #unif.logger:logger/v1/error \
    {"msg":'dimensions 中缺少参数 max_y',"namespace":"ReplaceBlock"}
execute unless score check_config.dimensions rb.temp = check_config.dimension rb.temp run \
    scoreboard players set check.fail rb.return 1
execute unless score check_config.dimensions rb.temp = check_config.min_y rb.temp run \
    scoreboard players set check.fail rb.return 1
execute unless score check_config.dimensions rb.temp = check_config.max_y rb.temp run \
    scoreboard players set check.fail rb.return 1

# 移除临时记分板
scoreboard objectives remove rb.temp
