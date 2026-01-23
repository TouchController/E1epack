## 被调用时修改记分板，便于其他项目检测数据包是否启用

# 添加记分板
scoreboard objectives add dfl_scoreboard dummy
# 设置dfl_enable
scoreboard players set dfl_enable dfl_scoreboard 1
