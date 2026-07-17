execute store result score zero.when.not.found testing run function dfl:load
execute if score zero.when.not.found testing matches 0 run function dfl:test/fail
execute unless score zero.when.not.found testing matches 0 run function dfl:test/pass
