"""Gamerule 名称替换规则。

对 process_mcfunction 产出的 mcfunction 文件进行 gamerule 名称替换。
"""

load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _apply_prefix(dest_path, strip_prefix, prefix):
    if not strip_prefix:
        return dest_path
    if not dest_path.startswith(strip_prefix):
        fail("dest_path '%s' does not start with strip_prefix '%s'" % (dest_path, strip_prefix))
    return prefix + dest_path[len(strip_prefix):]

def _gamerule_replacer_impl(ctx):
    dep = ctx.attr.src
    if PackageFilesInfo not in dep:
        fail("src must provide PackageFilesInfo, got %s" % dep)

    pfi = dep[PackageFilesInfo]
    strip = ctx.attr.strip_prefix
    prefix = ctx.attr.prefix
    reverse_flag = " --reverse" if ctx.attr.reverse else ""

    # 按源文件分组
    file_to_dests = {}
    for dest_path, src_file in pfi.dest_src_map.items():
        if src_file not in file_to_dests:
            file_to_dests[src_file] = []
        file_to_dests[src_file].append(dest_path)

    output_files = []
    new_dest_src_map = {}

    for i, (src_file, dest_paths) in enumerate(file_to_dests.items()):
        base = src_file.basename
        if base.endswith(".processed.mcfunction"):
            base = base.replace(".processed.mcfunction", ".mcfunction")
        # 用序号子目录避免同名冲突
        output_file = ctx.actions.declare_file(str(i) + "/" + base)
        output_files.append(output_file)

        ctx.actions.run_shell(
            inputs = [src_file, ctx.file._mapping, ctx.file._script],
            outputs = [output_file],
            command = "python3 '{script}'{reverse} '{input}' '{output}' '{mapping}'".format(
                script = ctx.file._script.path,
                reverse = reverse_flag,
                input = src_file.path,
                output = output_file.path,
                mapping = ctx.file._mapping.path,
            ),
            mnemonic = "GameruleReplace",
            progress_message = "Replacing gamerules in %s" % src_file.basename,
        )

        for dest_path in dest_paths:
            new_dest_src_map[_apply_prefix(dest_path, strip, prefix)] = output_file

    return [
        PackageFilesInfo(
            attributes = {},
            dest_src_map = new_dest_src_map,
        ),
        DefaultInfo(files = depset(output_files)),
    ]

gamerule_replacer = rule(
    implementation = _gamerule_replacer_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            providers = [PackageFilesInfo],
            doc = "process_mcfunction 的输出",
        ),
        "reverse": attr.bool(
            default = False,
            doc = "True 时反向替换（old→new），用于迁移第三方包到新版",
        ),
        "strip_prefix": attr.string(
            default = "",
            doc = "从目标路径中移除的前缀",
        ),
        "prefix": attr.string(
            default = "",
            doc = "替换 strip_prefix 的前缀",
        ),
        "_script": attr.label(
            default = Label("//rule:gamerule_replacer.py"),
            allow_single_file = True,
            cfg = "exec",
        ),
        "_mapping": attr.label(
            default = Label("//rule/mcfunction_processor:gamerule_mapping.json"),
            allow_single_file = True,
        ),
    },
    doc = "将 mcfunction 中的 gamerule 名替换为另一版本",
)
