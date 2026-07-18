"""JSON 文件合并规则。

此模块定义了用于合并多个JSON文件的Bazel规则。
主要功能包括：
- 深度合并多个JSON文件的键值对
- 后面的文件会覆盖前面文件的相同键
- 自动压缩输出为单行格式
- 支持批量处理多个文件组

提供 merge_json 规则，用于在构建过程中合并JSON文件，
实现键值对级别的合并而不是文件级别的覆盖。
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

def _merge_json_impl(ctx):
    """Implementation of the merge_json rule."""
    output_files = []
    dest_src_map = {}

    # 按文件名和命名空间分组输入文件
    file_groups = {}
    for src in ctx.files.srcs:
        basename = src.basename
        rel_path = _path_relative_to_package(src)

        # 提取命名空间信息
        namespace = None
        if "assets/" in rel_path:
            # assets/namespace/lang/file.json
            parts = rel_path.split("/")
            if len(parts) >= 4 and parts[0] == "assets" and parts[2] == "lang":
                namespace = parts[1]
        elif "translate/" in rel_path:
            # translate/namespace/lang/file.json
            parts = rel_path.split("/")
            if len(parts) >= 4 and parts[0] == "translate" and parts[2] == "lang":
                namespace = parts[1]

        # 使用 namespace/basename 作为分组键
        group_key = namespace + "/" + basename if namespace else basename
        if group_key not in file_groups:
            file_groups[group_key] = []
        file_groups[group_key].append(src)

    # 为每个文件组创建合并后的输出文件
    for group_key, files in file_groups.items():
        # 排序规则：translate 在前，assets 在后；保证 assets 的键覆盖 translate
        # 说明：JsonMerger 按输入顺序深度合并，后面的文件覆盖前面的相同键
        files = sorted(
            files,
            key = lambda f: (
                0 if "translate/" in _path_relative_to_package(f) else 1,
                _path_relative_to_package(f),
            ),
        )

        # 智能选择目标路径：优先使用assets目录中的路径结构
        target_path = None
        for file in files:
            rel_path = _path_relative_to_package(file)
            if "assets/" in rel_path:
                target_path = rel_path
                break

        # 如果没有找到assets路径，将translate路径转换为assets路径
        if target_path == None:
            translate_path = _path_relative_to_package(files[0])
            if "translate/" in translate_path:
                # 将 translate/namespace/lang/file.json 转换为 assets/namespace/lang/file.json
                target_path = translate_path.replace("translate/", "assets/")
            else:
                target_path = translate_path

        # 使用目标路径作为输出文件路径
        output_file = ctx.actions.declare_file(target_path)
        output_files.append(output_file)
        dest_src_map[target_path] = output_file

        args = ctx.actions.args()
        args.add(output_file)  # 输出文件
        args.add_all([f.path for f in files])  # 输入文件列表

        args.use_param_file("@%s", use_always = True)

        ctx.actions.run(
            inputs = files,
            outputs = [output_file],
            executable = ctx.executable._json_merger,
            arguments = [args],
            mnemonic = "MergeJson",
            progress_message = "Merging JSON files into %s" % group_key,
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

merge_json = rule(
    implementation = _merge_json_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".json"],
            mandatory = True,
            doc = "List of .json files to merge. Files with the same name will be merged together.",
        ),
        "_json_merger": attr.label(
            default = Label("//rule/tools/json_merger"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Merges .json files with the same name at key-value level",
)
