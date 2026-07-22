#!/bin/bash
# 循环测试并统计失败概率

NAME=${1}
VERSION=${2}
RUNS=${3:-20}
PASS=0
FAIL=0
INTERRUPTED=0

interrupt() {
    INTERRUPTED=1
}

trap interrupt INT TERM

echo "开始在 $VERSION 版本测试 $NAME $RUNS 次"

for i in $(seq 1 $RUNS); do
    ./test $NAME --version $VERSION --no-cache
    ret=$?
    if [ $INTERRUPTED -eq 1 ]; then
        echo ""
        echo "===================="
        echo "[$i/$RUNS] 中断"
        echo "===================="
        echo ""
        break
    fi
    if [ $ret -eq 0 ]; then
        PASS=$((PASS + 1))
        echo ""
        echo "===================="
        echo "[$i/$RUNS] PASS (pass=$PASS, fail=$FAIL)"
        echo "===================="
        echo ""
    else
        FAIL=$((FAIL + 1))
        echo ""
        echo "===================="
        echo "[$i/$RUNS] FAIL (pass=$PASS, fail=$FAIL)"
        echo "===================="
        echo ""
    fi
done

echo ""
echo "=== 结果 ==="
echo "总次数: $i"
echo "通过: $PASS"
echo "失败: $FAIL"
echo "失败率: $(echo "scale=1; $FAIL * 100 / $i" | bc)%"
