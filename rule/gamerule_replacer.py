#!/usr/bin/env python3
"""Gamerule 名称替换工具。

默认方向：new→old（minecraft:snake_case → camelCase）用于旧版兼容。
--reverse：old→new，用于迁移第三方包到新版。
"""

import json
import re
import sys


def main():
    reverse = False
    args = sys.argv[1:]

    if args and args[0] == "--reverse":
        reverse = True
        args = args[1:]

    if len(args) != 3:
        print(f"Usage: {sys.argv[0]} [--reverse] <input> <output> <mapping.json>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path, mapping_path = args

    with open(mapping_path, "r", encoding="utf-8") as f:
        mapping = json.load(f)

    with open(input_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if reverse:
        old_to_new = {v: k for k, v in mapping.items()}
        old_names = sorted(old_to_new.keys(), key=len, reverse=True)
        pattern = re.compile(r"\bgamerule\s+(" + "|".join(re.escape(n) for n in old_names) + r")\b")

        result = []
        for line in lines:
            line = pattern.sub(
                lambda m: "gamerule " + old_to_new[m.group(1)],
                line,
            )
            result.append(line)
    else:
        pattern = re.compile(r"\bgamerule\s+(minecraft:[a-z_]+)\b")

        result = []
        for line in lines:
            line = pattern.sub(
                lambda m, mapp=mapping: "gamerule " + mapp[m.group(1)]
                if m.group(1) in mapp
                else m.group(0),
                line,
            )
            result.append(line)

    with open(output_path, "w", encoding="utf-8") as f:
        f.writelines(result)


if __name__ == "__main__":
    main()
