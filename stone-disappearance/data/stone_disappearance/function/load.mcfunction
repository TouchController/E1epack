function dfl:lib/datapack_banner {\
    name:"Stone Disappearance",\
    author:"white_elephant_",\
    author_url:"https://modrinth.com/user/white_elephant",\
    license_name:"GNU GPL",\
    license_url:"https://www.gnu.org/licenses/gpl-3.0.txt",\
    official_url:"https://github.com/TouchController/E1epack/tree/main/stone-disappearance"}

gamerule commandModificationBlockLimit 2147483647

scoreboard objectives add sd.debug dummy
scoreboard objectives add sd.settings dummy

execute as @a run \
    function #unif.logger:logger/v1/tips \
    {"msg":'初始化成功',"namespace":"Stone-Disappearance"}
