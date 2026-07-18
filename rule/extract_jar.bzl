"""JAR 文件提取规则。

此模块定义了用于从 JAR 或 ZIP 归档文件中提取单个文件的 Bazel 规则。
主要功能包括：
- 从 JAR/ZIP 文件中提取指定路径的文件
- 支持自定义输出文件名
- 提供进度信息显示

提供 extract_jar 规则，用于在构建过程中从归档文件中提取所需的文件。
"""

def _extract_jar_impl(ctx):
    output_file = ctx.actions.declare_file(ctx.attr.filename)
    args = ctx.actions.args()

    args.add_all([
        ctx.file.input.path,
        ctx.attr.entry_path,
        output_file.path,
    ])

    ctx.actions.run(
        inputs = [ctx.file.input],
        outputs = [output_file],
        executable = ctx.executable._extract_bin,
        arguments = [args],
        progress_message = "Extracting %s" % ctx.label.name,
    )

    return [DefaultInfo(files = depset([output_file]))]

extract_jar = rule(
    implementation = _extract_jar_impl,
    attrs = {
        "input": attr.label(
            allow_single_file = [".jar", ".zip"],
            mandatory = True,
            doc = "Input JAR file",
        ),
        "entry_path": attr.string(
            mandatory = True,
            doc = "Path of the entry to be extracted",
        ),
        "filename": attr.string(
            mandatory = True,
            doc = "Output file name",
        ),
        "_extract_bin": attr.label(
            default = Label("//rule/tools/extract"),
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Extract single file from a JAR archive.",
)
