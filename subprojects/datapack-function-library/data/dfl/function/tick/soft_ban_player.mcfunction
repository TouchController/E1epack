## 软封禁玩家，不断传送并给予负面效果

# 将玩家传送到世界原点
   # 限制玩家移动位置
tp 0.0 0.0 0.0

# 切换为冒险模式
   # 防止玩家破坏方块或与方块交互
gamemode adventure

# 设置标题显示时间
   # 淡入0刻，显示70刻，淡出20刻
title @s times 0 70 20

# 显示主标题
   # 告知玩家已被封禁，使用红色粗体
$title @s title \
    {"text":"$(title)","color":"red","bold":true}

# 显示副标题
   # 显示封禁来源信息
$title @s subtitle \
    [{"text":"$(subtitle)","color":"gray"},\
    {"text":" datapack function library","color":"gray"}]

# 给予负面效果
   # 失明效果，限制视野
effect give @s blindness 60 255
   # 缓慢效果，限制移动速度
effect give @s slowness 60 255
   # 挖掘疲劳效果，防止破坏方块
effect give @s mining_fatigue 60 255
   # 抗性提升效果，防止玩家受到伤害
effect give @s resistance 60 255
   # 生命恢复效果，防止玩家死亡
effect give @s regeneration 60 255
   # 霉运效果，影响战利品获取
effect give @s unluck 60 255
   # 发光效果，使玩家在黑暗中可见
effect give @s glowing 60 255
   # 虚弱效果，降低攻击伤害
effect give @s weakness 60 255
