scoreboard objectives add testing dummy
function dfl-test:1.21-26.2/load-function-loaded
execute if score result testing matches 1 run say [[TEST][1.21-26.2/load-function-loaded][PASS]]
execute unless score result testing matches 1 run say [[TEST][1.21-26.2/load-function-loaded][FAIL]]
scoreboard objectives remove testing
