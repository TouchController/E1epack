"""Minecraft function tag 合并规则。

合并来自多个数据包的 minecraft function tag 文件（如 load.json、tick.json），
按文件名分组后合并 values 数组。
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _owner(file):
    if file.owner == None:
        fail("File {} ({}) has no owner attribute".format(file, file.path))
    return file.owner

def _relative_workspace_root(label):
    return paths.join("..", label.workspace_name) if label.workspace_name else ""

def _path_relative_to_package(file):
    owner = _owner(file)
    return paths.relativize(
        file.short_path,
        paths.join(_relative_workspace_root(owner), owner.package),
    )

def _merge_tags_impl(ctx):
    file_groups = {}
    for src in ctx.files.srcs:
        basename = src.basename
        if basename not in file_groups:
            file_groups[basename] = []
        file_groups[basename].append(src)

    output_files = []
    dest_src_map = {}
    for basename, files in file_groups.items():
        files = sorted(files, key = lambda f: f.path)
        rel_path = _path_relative_to_package(files[0])
        output_file = ctx.actions.declare_file(rel_path)
        output_files.append(output_file)
        dest_src_map[rel_path] = output_file

        args = ctx.actions.args()
        args.add(output_file.path)
        args.add_all([f.path for f in files])
        args.use_param_file("@%s", use_always = True)

        ctx.actions.run(
            inputs = files,
            outputs = [output_file],
            executable = ctx.executable._merger,
            arguments = [args],
            mnemonic = "MergeTags",
            progress_message = "Merging function tags into %s" % basename,
        )

    return [
        PackageFilesInfo(attributes = {}, dest_src_map = dest_src_map),
        DefaultInfo(files = depset(output_files)),
    ]

merge_function_tags = rule(
    implementation = _merge_tags_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".json"],
            mandatory = True,
            doc = "要合并的 tag JSON 文件，同文件名自动分组",
        ),
        "_merger": attr.label(
            default = Label("//rule:merge_tags"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "按文件名合并 Minecraft function tag JSON 文件",
)
