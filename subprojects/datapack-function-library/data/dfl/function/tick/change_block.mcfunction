## 大范围替换方块

# 解除命令修改限制，允许大范围操作
gamerule commandModificationBlockLimit 2147483647

# 以玩家为中心替换指定范围内的方块
$fill ~$(num) ~$(num) ~$(num) ~-$(num) ~-$(num) ~-$(num) $(new) \
    replace $(old)
