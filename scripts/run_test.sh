#!/bin/bash
set -e

# 用法: ./test <数据包名> [--version X.Y.Z|all|major] [--server] [--bisect LO HI]

# 检查参数
if [[ $# -lt 1 ]]; then
    echo "用法: ./test <数据包名> [--version X.Y.Z|all|major] [--server] [--no-cache] [--bisect LO HI]"
    echo "示例:"
    echo "  ./test datapack-function-library                    # 测试最新版本"
    echo "  ./test datapack-function-library --version 1.21.5   # 测试指定版本"
    echo "  ./test datapack-function-library --version all      # 测试所有版本"
    echo "  ./test datapack-function-library --version major    # 测试主要版本"
    echo "  ./test datapack-function-library --server --version 1.21.5  # 启动测试服务器"
    echo "  ./test datapack-function-library --version 1.21.5 --no-cache  # 禁用缓存测试"
    echo "  ./test datapack-function-library --bisect 1.19 1.20.4  # 二分查找分界点"
    exit 1
fi

PACK_DIR="$1"
shift

# 默认值
VERSION=""
SERVER=false
NO_CACHE=false
BISECT_LO=""
BISECT_HI=""

# 解析剩余参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --server)
            SERVER=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --bisect)
            BISECT_LO="$2"
            BISECT_HI="$3"
            shift 3
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"

# 检查数据包目录是否存在
if [[ ! -d "$REPO_ROOT/subprojects/$PACK_DIR" ]]; then
    echo "错误: 数据包目录不存在: subprojects/$PACK_DIR"
    echo "可用数据包:"
    ls -1 subprojects/ | grep -v '^$'
    exit 1
fi

# 二分查找模式
if [[ -n "$BISECT_LO" && -n "$BISECT_HI" ]]; then
    if [[ -n "$VERSION" || "$SERVER" == true ]]; then
        echo "错误: --bisect 不能与 --version 或 --server 同时使用"
        exit 1
    fi
    BISECT_ARGS=""
    if [[ "$NO_CACHE" == true ]]; then
        BISECT_ARGS="--no-cache"
    fi
    echo "二分查找: subprojects/$PACK_DIR ($BISECT_LO -> $BISECT_HI)"
    python3 $REPO_ROOT/scripts/bisect_tests.py "//subprojects/$PACK_DIR" "$BISECT_LO" "$BISECT_HI" $BISECT_ARGS
    exit $?
fi

# 确定 bazel 命令和目标
BAZEL_CMD=""
TARGET=""
EXTRA_ARGS=""

if [[ "$SERVER" == true ]]; then
    # 启动测试服务器
    if [[ -z "$VERSION" ]]; then
        echo "错误: --server 需要指定 --version"
        exit 1
    fi
    if [[ "$VERSION" == "all" || "$VERSION" == "major" ]]; then
        echo "错误: --server 不支持 --version $VERSION"
        exit 1
    fi
    if [[ "$NO_CACHE" == true ]]; then
        echo "错误: --no-cache 不支持 --server"
        exit 1
    fi
    BAZEL_CMD="run"
    TARGET="test_server_$VERSION"
    echo "启动测试服务器: $PACK_DIR $VERSION"
else
    # 运行测试
    BAZEL_CMD="test"
    if [[ -z "$VERSION" ]]; then
        # 默认测试最新版本
        TARGET="test"
        EXTRA_ARGS="--test_output=streamed"
        echo "测试最新版本: $PACK_DIR"
    elif [[ "$VERSION" == "all" ]]; then
        TARGET="test_all"
        EXTRA_ARGS="--test_output=errors"
        echo "测试所有版本: $PACK_DIR"
    elif [[ "$VERSION" == "major" ]]; then
        TARGET="test_major"
        EXTRA_ARGS="--test_output=errors"
        echo "测试主要版本: $PACK_DIR"
    else
        # 测试指定版本
        # 验证版本格式
        if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
            echo "错误: 版本格式无效，应为 X.Y 或 X.Y.Z"
            exit 1
        fi
        TARGET="test_verbose_$VERSION"
        EXTRA_ARGS="--test_output=streamed"
        echo "测试版本: $PACK_DIR $VERSION"
    fi

    # 添加 --no-cache 参数
    if [[ "$NO_CACHE" == true ]]; then
        EXTRA_ARGS="$EXTRA_ARGS --cache_test_results=no"
    fi
fi

# 执行 bazel 命令
bazel $BAZEL_CMD "//subprojects/$PACK_DIR:$TARGET" $EXTRA_ARGS
