## 设置初始化

# 重置设置
data modify storage stone_disappearance:data settings set value \
    {\
        overworld_block:"glass",\
        nether_block:"glass",\
        end_block:"glass",\
\
        overworld_min:-64,\
        overworld_max:319,\
        nether_min:0,\
        nether_max:255,\
        end_min:0,\
        end_max:255,\
\
        n:1,\
        tick:20,\
        success_num:50,\
\
        fill_falling_block:true,\
        fill_falling_block_with:"glass",\
\
        tick_fill:true,\
    }
# 标记为已重置
scoreboard players set loaded sd.settings 1

#用于dialog
#{overworld_block:'glass',nether_block:'glass',end_block:'glass',overworld_min:-64,overworld_max:319,nether_min:0,nether_max:255,end_min:0,end_max:255,n:1,tick:20,success_num:50,fill_falling_block:true,fill_falling_block_with:'glass',tick_fill:true}
