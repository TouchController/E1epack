fill 0 1 0 0 255 0 minecraft:air destroy
execute unless block 0 0 0 lucky:lucky_block run setblock 0 0 0 lucky:lucky_block destroy
schedule function lucky_block_island:redstone 10s
