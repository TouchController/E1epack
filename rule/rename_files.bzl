"""文件重命名规则。

此模块定义了用于重命名文件的 Bazel 规则。
主要功能包括：
- 重命名处理过的 mcfunction 文件
- 移除文件名中的处理标记（如 _processed、.raw）
- 支持批量文件重命名操作
- 保持文件内容不变，仅修改文件名

提供 rename_files 规则，用于在构建过程中清理文件名，
将临时处理文件名恢复为标准的 Minecraft 函数文件名。
"""

def _rename_files_impl(ctx):
    """Implementation of the rename_files rule."""
    output_files = []
    
    # 检测当前平台是否为 Windows
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])
    
    for src in ctx.files.srcs:
        # 创建重命名后的输出文件
        if "_processed.mcfunction" in src.basename:
            output_name = src.basename.replace("_processed.mcfunction", ".mcfunction")
        elif ".raw.mcfunction" in src.basename:
            output_name = src.basename.replace(".raw.mcfunction", ".mcfunction")
        else:
            output_name = src.basename
        
        output_file = ctx.actions.declare_file(output_name, sibling = src)
        output_files.append(output_file)
        
        # 跨平台复制文件并重命名
        if is_windows:
            # Windows 使用 cmd copy 命令
            ctx.actions.run_shell(
                inputs = [src],
                outputs = [output_file],
                command = "copy \"{}\" \"{}\"".format(src.path.replace("/", "\\"), output_file.path.replace("/", "\\")),
                mnemonic = "RenameFile",
                progress_message = "Renaming %s to %s" % (src.basename, output_name),
            )
        else:
            # Unix-like 系统使用 cp 命令
            ctx.actions.run_shell(
                inputs = [src],
                outputs = [output_file],
                command = "cp \"{}\" \"{}\"".format(src.path, output_file.path),
                mnemonic = "RenameFile",
                progress_message = "Renaming %s to %s" % (src.basename, output_name),
            )
    
    return [DefaultInfo(files = depset(output_files))]

rename_files = rule(
    implementation = _rename_files_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_empty = True,
            allow_files = [".mcfunction", ".raw.mcfunction"],
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
)