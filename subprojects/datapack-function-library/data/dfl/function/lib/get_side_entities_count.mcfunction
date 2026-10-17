## 此文件用于监测任意实体上、下、左、右、前、后侧实体计数
# 原理：半径足够大的圆可以近似看做一条直线
# 传参：as 实体、side宏（0=左,1=右,2=上,3=下,4=前,5=后）

scoreboard objectives add dfl_scoreboard dummy
scoreboard objectives add entities_side dummy
$scoreboard players set #lib_get_side_entities_side dfl_scoreboard $(side)

## 校验
# 显示校验失败
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches -2147483647..-1 \
  run tellraw @s {\
    "text":"执行失败!side宏应为0(左)/1(右)/2(上)/3(下)/4(前)/5(后)!",\
    "color":"red"\
  }
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 4..2147483647 \
  run tellraw @s {\
    "text":"执行失败!side宏应为0(左)/1(右)/2(上)/3(下)/4(前)/5(后)!",\
    "color":"red"\
  }
# 校验成功与执行
#左
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 0 \
  rotated as @s \
  positioned ^1024 ^ ^ \
  store result score @s entities_side \
  if entity @e[distance=0..1024]
#右
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 1 \
  rotated as @s \
  positioned ^1024 ^ ^ \
  store result score @s entities_side \
  if entity @e[distance=0..1024]
#上
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 2 \
  rotated as @s \
  positioned ^ ^1024 ^ \
  store result score @s entities_side \
  if entity @e[distance=0..1024]
#下
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 3 \
  rotated as @s \
  positioned ^ ^-1024 ^ \
  store result score @s entities_side \
  if entity @e[distance=0..1024]
#前
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 4 \
  rotated as @s \
  positioned ^ ^ ^1024 \
  store result score @s entities_side \
  if entity @e[distance=0..1024]

#后
execute \
  if score #lib_get_side_entities_side dfl_scoreboard matches 5 \
  rotated as @s \
  positioned ^ ^ ^-1024 \
  store result score @s entities_side \
  if entity @e[distance=0..1024]
