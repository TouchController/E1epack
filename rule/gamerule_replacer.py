#!/usr/bin/env python3
"""Gamerule name replacer.

Converts new-format gamerule names (minecraft:snake_case) to old format
(camelCase) for backward compatibility with Minecraft < 1.21.11.
"""

import json
import re
import sys


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input> <output> <mapping.json>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path, mapping_path = sys.argv[1:]

    with open(mapping_path, "r", encoding="utf-8") as f:
        mapping = json.load(f)

    with open(input_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

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
