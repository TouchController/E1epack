data remove storage unif.logger:cache Cache.Logger

# Message
$data modify storage unif.logger:cache Cache.Logger.Message set value "$(msg)"

# Namespace
$data modify storage unif.logger:cache Cache.Logger.Namespace set value $(namespace)

# LevelColor
$data modify storage unif.logger:cache Cache.Logger.LevelColor set value $(levelColor)

# Level
$data modify storage unif.logger:cache Cache.Logger.Level set value $(level)

# Time
execute store result storage unif.logger:cache Cache.Logger.Time int 1 run time query daytime
execute store result storage unif.logger:cache Cache.Logger.Day int 1 run time query day

# 对过大数据进行处理
data modify storage unif.logger:cache Cache.Logger.Namespace set string storage unif.logger:cache Cache.Logger.Namespace 0 64
data modify storage unif.logger:cache Cache.Logger.Message set string storage unif.logger:cache Cache.Logger.Message 0 512

scoreboard objectives remove unif.10000