"""合并 Minecraft function tag JSON 文件。

用于合并来自多个数据包的同一 tag 文件（如 load.json、tick.json）。
正确处理 values 数组中的字符串和对象格式，按 id 去重。
"""

import json
import sys


def merge_tags(output_path, input_paths):
    merged = {"values": []}
    seen_ids = {}  # key -> entry, 保留对象形式（含 required: false 元数据）

    for path in sorted(input_paths):
        try:
            with open(path) as f:
                data = json.load(f)
        except FileNotFoundError:
            print("Error: input file not found: %s" % path, file=sys.stderr)
            continue
        except json.JSONDecodeError as e:
            print("Error: skipping %s: invalid JSON: %s" % (path, e), file=sys.stderr)
            continue

        if not isinstance(data, dict):
            print("Warning: skipping %s: not a JSON object" % path, file=sys.stderr)
            continue

        values = data.get("values")
        if not isinstance(values, list):
            print("Warning: skipping %s: 'values' is not a list" % path, file=sys.stderr)
            continue

        if data.get("replace", False):
            merged["values"] = []
            seen_ids.clear()

        for entry in values:
            if isinstance(entry, str):
                key = entry
                is_object = False
            elif isinstance(entry, dict):
                key = entry.get("id", "")
                is_object = True
            else:
                continue

            if not key:
                continue

            if key in seen_ids:
                # 对象形式比字符串携带更多信息，保留对象形式
                if is_object and not isinstance(seen_ids[key], dict):
                    merged["values"] = [
                        entry if (v if isinstance(v, str) else v.get("id", "")) == key else v
                        for v in merged["values"]
                    ]
                    seen_ids[key] = entry
            else:
                seen_ids[key] = entry
                merged["values"].append(entry)

    merged["replace"] = False

    with open(output_path, "w") as f:
        json.dump(merged, f, separators=(",", ":"))


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0].startswith("@"):
        with open(args[0][1:]) as f:
            args = [line.strip() for line in f if line.strip()]
    if len(args) < 2:
        print("Usage: merge_tags.py <output> <input1> [input2] ...", file=sys.stderr)
        sys.exit(1)
    merge_tags(args[0], args[1:])
