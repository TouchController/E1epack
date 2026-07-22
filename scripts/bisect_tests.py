#!/usr/bin/env python3
"""二分查找测试分界点（独立运行）。

用法:
  python3 bisect_tests.py <package> <lo> <hi> [--no-cache]

示例:
  python3 bisect_tests.py //subprojects/datapack-function-library 1.19 1.20.4
  python3 bisect_tests.py //subprojects/datapack-function-library 1.19 1.20.4 --no-cache
"""

import subprocess
import sys


def get_versions(package: str, lo: str, hi: str) -> list[str]:
    """通过 bazel query 获取版本列表。"""
    result = subprocess.run(
        ["bazel", "query", f"tests({package}:test_all)", "--output=label"],
        capture_output=True, text=True, check=True
    )

    versions = []
    for line in result.stdout.strip().split('\n'):
        if 'test_quiet_' in line:
            ver = line.split('test_quiet_')[-1]
            if ver.replace('.', '').isdigit():
                versions.append(ver)

    versions.sort(key=lambda v: [int(x) for x in v.split('.')])

    if not versions:
        print(f"错误：未找到任何测试版本", file=sys.stderr)
        sys.exit(1)

    # 检查范围是否有效
    if lo not in versions:
        print(f"错误：起始版本 {lo} 不在支持的版本列表中", file=sys.stderr)
        print(f"可用版本: {', '.join(versions)}", file=sys.stderr)
        sys.exit(1)
    if hi not in versions:
        print(f"错误：结束版本 {hi} 不在支持的版本列表中", file=sys.stderr)
        print(f"可用版本: {', '.join(versions)}", file=sys.stderr)
        sys.exit(1)

    return [v for v in versions if lo <= v <= hi]


def run_test(package: str, version: str, no_cache: bool = False) -> bool:
    """运行测试，返回是否成功。"""
    cmd = ["bazel", "test", f"{package}:test_quiet_{version}"]
    if no_cache:
        cmd.append("--cache_test_results=no")
    result = subprocess.run(cmd, capture_output=True)
    return result.returncode == 0


def bisect(package: str, versions: list[str], no_cache: bool = False) -> tuple[str, str]:
    """二分查找分界点。"""
    lo, hi = 0, len(versions) - 1

    # 检查边界单调性
    print(f"范围: {versions[0]} → {versions[-1]} ({len(versions)} 版本)")

    print(f"  {versions[lo]} ", end="", flush=True)
    lo_ok = run_test(package, versions[lo], no_cache)
    print("✓" if lo_ok else "✗")

    print(f"  {versions[hi]} ", end="", flush=True)
    hi_ok = run_test(package, versions[hi], no_cache)
    print("✓" if hi_ok else "✗")

    if lo_ok == hi_ok:
        print(f"\n错误：两端结果相同（{'✓' if lo_ok else '✗'}），无法二分", file=sys.stderr)
        sys.exit(1)

    if not lo_ok:
        lo, hi = hi, lo

    print()

    while hi - lo > 1:
        mid = (lo + hi) // 2
        ver = versions[mid]
        print(f"  {ver} ", end="", flush=True)

        if run_test(package, ver, no_cache):
            print("✓")
            lo = mid
        else:
            print("✗")
            hi = mid

    return versions[lo], versions[hi]


def main():
    if len(sys.argv) < 4:
        print(f"用法: {sys.argv[0]} <package> <lo> <hi> [--no-cache]", file=sys.stderr)
        sys.exit(1)

    package, lo, hi = sys.argv[1], sys.argv[2], sys.argv[3]
    no_cache = "--no-cache" in sys.argv

    versions = get_versions(package, lo, hi)

    last_pass, first_fail = bisect(package, versions, no_cache)

    print(f"\n{'='*40}")
    print(f"最后成功: {last_pass}")
    print(f"第一失败: {first_fail}")


if __name__ == "__main__":
    main()
