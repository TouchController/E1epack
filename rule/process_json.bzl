"""JSON 文件压缩处理规则。

此模块定义了用于压缩 JSON 文件的 Bazel 规则。
主要功能包括：
- 压缩 JSON 文件为单行格式
- 支持批量处理多个 JSON 文件
- 提供包文件信息用于后续打包
- 使用 Worker 协议提高构建性能

提供 process_json 规则，用于在构建过程中压缩 JSON 文件，
减少数据包的文件大小并提高加载性能。
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _owner(file):
    if file.owner == None:
        fail("File {} ({}) has no owner attribute; cannot continue".format(file, file.path))
    return file.owner

def _relative_workspace_root(label):
    return paths.join("..", label.workspace_name) if label.workspace_name else ""

def _path_relative_to_package(file):
    owner = _owner(file)
    return paths.relativize(
        file.short_path,
        paths.join(_relative_workspace_root(owner), owner.package),
    )

def _process_json_impl(ctx):
    """Implementation of the process_json rule."""
    output_files = []
    dest_src_map = {}

    for src in ctx.files.srcs:
        output_file = ctx.actions.declare_file(src.basename, sibling = src)
        output_files.append(output_file)

        src_path = _path_relative_to_package(src)
        dest_src_map[src_path] = output_file
        # 如果需要路径替换，可以在这里添加类似 function 的逻辑

        args = ctx.actions.args()
        args.add(src)
        args.add(output_file)

        args.use_param_file("@%s", use_always = True)

        ctx.actions.run(
            inputs = [src],
            outputs = [output_file],
            executable = ctx.executable._json_compressor,
            arguments = [args],
            mnemonic = "ProcessJson",
            progress_message = "Compressing JSON file %s" % src.short_path,
            execution_requirements = {
                "supports-workers": "1",
                "requires-worker-protocol": "json",
            },
        )

    return [
        PackageFilesInfo(
            attributes = {},
            dest_src_map = dest_src_map,
        ),
        DefaultInfo(files = depset(output_files)),
    ]

process_json = rule(
    implementation = _process_json_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".json", ".mcmeta"],
            mandatory = True,
            doc = "List of .json files to compress",
        ),
        "_json_compressor": attr.label(
            default = Label("//rule/tools/json_compressor"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Compresses .json files to single line",
)
