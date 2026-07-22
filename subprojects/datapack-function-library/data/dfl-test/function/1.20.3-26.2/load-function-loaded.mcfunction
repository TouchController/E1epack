execute store success score founded.load testing run function dfl:load
execute if score founded.load testing matches 0 run function dfl:test/fail
execute unless score founded.load testing matches 0 run function dfl:test/pass
