## 清理掉落物

# 初始化计分板
scoreboard objectives add dfl_scoreboard dummy "DFL"

# 清理非必要掉落物并记录数量
execute store result score item_number dfl_scoreboard \
    run kill @e[type=item,tag=!need]

# 向玩家显示清理结果
tellraw @a \
    {"type": "translatable", "translate": "redstone.kill.item.dfl.entity.clear_with_count", \
        "fallback": "清除了 %s 个掉落物", "color": "gray", "italic": true, \
        "with": [{"score": {"name": "item_number", "objective": "dfl_scoreboard"}}]}
