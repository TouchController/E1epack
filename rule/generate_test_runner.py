"""从模板生成 test runner mcfunction。"""

import argparse
import sys


def main():
    parser = argparse.ArgumentParser(description="Generate test runner mcfunction from template")
    parser.add_argument("--template", required=True, help="Template file path")
    parser.add_argument("--namespace", required=True, help="Test namespace")
    parser.add_argument("--out", required=True, help="Output file path")
    parser.add_argument("names", nargs="*", help="Test names")
    args = parser.parse_args()

    with open(args.template) as f:
        template = f.read()

    with open(args.out, "w") as out:
        out.write("say [[TESTING_STARTED]]\n")
        for name in args.names:
            out.write(template.replace("{{namespace}}", args.namespace).replace("{{test-name}}", name))
        out.write("stop\n")


if __name__ == "__main__":
    main()
