execute store result score zero.when.not.found testing run function dfl:private/datapack_banner {\
    name:"datapack function library",\
    author:"white_elephant_",\
    author_url:"https://modrinth.com/user/white_elephant",\
    license_name:"GNU LGPL",\
    license_url:"https://www.gnu.org/licenses/lgpl-3.0.txt",\
    official_url:"https://github.com/TouchController/E1epack/tree/main/subprojects/datapack-function-library"}
execute if score zero.when.not.found testing matches 0 run function dfl:test/fail
execute unless score zero.when.not.found testing matches 0 run function dfl:test/pass
