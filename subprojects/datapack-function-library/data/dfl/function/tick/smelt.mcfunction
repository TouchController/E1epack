## 使用三种煤冶炼物品

# 使用煤炭块作为燃料（9个输入物品）
$function dfl:child/smelt {\
    input:"$(input)",\
    fuel:"coal_block",\
    output:"$(output)",\
    amount:"9"\
}

# 使用煤炭作为燃料（1个输入物品）
$function dfl:child/smelt {\
    input:"$(input)",\
    fuel:"coal",\
    output:"$(output)",\
    amount:"1"\
}

# 使用木炭作为燃料（1个输入物品）
$function dfl:child/smelt {\
    input:"$(input)",\
    fuel:"charcoal",\
    output:"$(output)",\
    amount:"1"\
}
