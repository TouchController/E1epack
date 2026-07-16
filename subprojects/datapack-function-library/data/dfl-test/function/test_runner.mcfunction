scoreboard objectives add testing dummy
function dfl-test:common/load-function-loaded
execute if score result testing matches 1 run say [[TEST][common/load-function-loaded][PASS]]
execute unless score result testing matches 1 run say [[TEST][common/load-function-loaded][FAIL]]
scoreboard objectives remove testing
