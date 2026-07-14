"""命令替换规则。

对 process_mcfunction 产出的 mcfunction 文件进行基于正则的命令替换，
用于生成兼容旧版 Minecraft 的 zip。支持传入多个 mapping JSON 文件。
"""

load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _apply_prefix(dest_path, strip_prefix, prefix):
    if not strip_prefix:
        return dest_path
    if not dest_path.startswith(strip_prefix):
        fail("dest_path '%s' does not start with strip_prefix '%s'" % (dest_path, strip_prefix))
    return prefix + dest_path[len(strip_prefix):]

def _command_replacer_impl(ctx):
    dep = ctx.attr.src
    if PackageFilesInfo not in dep:
        fail("src must provide PackageFilesInfo, got %s" % dep)

    pfi = dep[PackageFilesInfo]
    strip = ctx.attr.strip_prefix
    prefix = ctx.attr.prefix

    file_to_dests = {}
    for dest_path, src_file in pfi.dest_src_map.items():
        if src_file not in file_to_dests:
            file_to_dests[src_file] = []
        file_to_dests[src_file].append(dest_path)

    output_files = []
    new_dest_src_map = {}

    mapping_files = ctx.files.mappings

    for i, (src_file, dest_paths) in enumerate(file_to_dests.items()):
        base = src_file.basename
        if base.endswith(".processed.mcfunction"):
            base = base.replace(".processed.mcfunction", ".mcfunction")
        output_file = ctx.actions.declare_file(ctx.label.name + "/" + str(i) + "/" + base)
        output_files.append(output_file)

        args = ctx.actions.args()
        args.add(src_file.path)
        args.add(output_file.path)
        args.add_all([f.path for f in mapping_files])

        ctx.actions.run(
            inputs = [src_file] + mapping_files,
            outputs = [output_file],
            executable = ctx.executable._script,
            arguments = [args],
            mnemonic = "CommandReplace",
            progress_message = "Replacing commands in %s" % src_file.basename,
        )

        for dest_path in dest_paths:
            new_dest_src_map[_apply_prefix(dest_path, strip, prefix)] = output_file

    return [
        PackageFilesInfo(
            attributes = pfi.attributes,
            dest_src_map = new_dest_src_map,
        ),
        DefaultInfo(files = depset(output_files)),
    ]

command_replacer = rule(
    implementation = _command_replacer_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            providers = [PackageFilesInfo],
            doc = "process_mcfunction 的输出",
        ),
        "mappings": attr.label_list(
            allow_files = True,
            doc = "mapping JSON 文件列表，合并后按 key 长度降序应用替换",
        ),
        "strip_prefix": attr.string(default = ""),
        "prefix": attr.string(default = ""),
        "_script": attr.label(
            default = Label("//rule:command_replacer"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "对 mcfunction 文件执行基于正则的命令替换，用于旧版兼容",
)
