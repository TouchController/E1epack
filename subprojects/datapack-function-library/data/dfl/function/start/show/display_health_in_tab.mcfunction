## 显示玩家血条

# 创建基于生命值的记分板目标
scoreboard objectives add health health
# 在玩家列表显示生命值
scoreboard objectives setdisplay list health
# 设置生命值显示为心形图标
scoreboard objectives modify health rendertype hearts
