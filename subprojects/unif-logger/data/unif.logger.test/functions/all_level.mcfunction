execute as @a run function #unif.logger:logger/v1/debug {"msg":'Debug Test',"namespace":"UniF-Logger"}
execute as @a run function #unif.logger:logger/v1/info {"msg":'Info Test',"namespace":"UniF-Logger"}
execute as @a run function #unif.logger:logger/v1/warn {"msg":'Warn Test',"namespace":"UniF-Logger"}
execute as @a run function #unif.logger:logger/v1/error {"msg":'Error Test',"namespace":"UniF-Logger"}

execute as @a run function #unif.logger:logger/v1/debug {"msg":'-------------------',"namespace":"UniF-Logger"}

execute as @a run function #unif.logger:injected_logger/v1/debug {"msg":"{\"text\":\"Injected Debug Test\",\"hoverEvent\":{\"action\":\"show_text\",\"contents\":\"It\\'s a message.\"}}","namespace":"UniF-Logger"}
execute as @a run function #unif.logger:injected_logger/v1/info {"msg":"{\"text\":\"Injected Info Test\",\"hoverEvent\":{\"action\":\"show_text\",\"contents\":\"It\\'s a message.\"}}","namespace":"UniF-Logger"}
execute as @a run function #unif.logger:injected_logger/v1/warn {"msg":"{\"text\":\"Injected Warn Test\",\"hoverEvent\":{\"action\":\"show_text\",\"contents\":\"It\\'s a message.\"}}","namespace":"UniF-Logger"}
execute as @a run function #unif.logger:injected_logger/v1/error {"msg":"{\"text\":\"Injected Error Test\",\"hoverEvent\":{\"action\":\"show_text\",\"contents\":\"It\\'s a message.\"}}","namespace":"UniF-Logger"}