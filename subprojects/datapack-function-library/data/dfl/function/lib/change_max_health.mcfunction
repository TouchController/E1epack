## 修改最大生命值
# 为所有玩家设置基础最大生命值
$execute as @a \
    run attribute @s generic.max_health base set $(num)
