#!/usr/bin/env python3
"""Command replacer for Minecraft .mcfunction files.

Applies regex-based text replacements from one or more mapping JSON files.
Each mapping file is a dict of {regex_pattern: replacement_string}.
Patterns are applied in descending key-length order to avoid partial matches.
"""

import json
import re
import sys


def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <input> <output> <mapping...>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path = sys.argv[1], sys.argv[2]
    mapping_paths = sys.argv[3:]

    mapping = {}
    for path in mapping_paths:
        with open(path, "r", encoding="utf-8") as f:
            mapping.update(json.load(f))

    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    for pattern, replacement in sorted(mapping.items(), key=lambda kv: -len(kv[0])):
        content = re.sub(pattern, replacement, content)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)


if __name__ == "__main__":
    main()
