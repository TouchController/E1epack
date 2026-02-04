---
name: release
description: 发布新版本，更新版本号、更新日志和README
argument-hint: [数据包目录]
disable-model-invocation: true
---

比对`!`pwd`/subprojects/$ARGUMENTS`目录从最新标签（若无名称可能此项目尚未发布或版本号格式不正确：!`git tag --list "$ARGUMENTS_*" | grep -E "$ARGUMENTS_v[0-9]+\\.[0-9]+\\.[0-9]$" | sort -V | tail -1`）到最新commit之间的差异，总结然后执行以下步骤：

- 询问用户此次更新的级别，更新 `!`pwd`/subprojects/$ARGUMENTS/BUILD.bazel` 的pack_version，确保符合SemVer规范：请阅读 `!`pwd`/SemVer.md` 以了解命名规范。注意：如果当前pack_version从来没有发布过，则不修改版本号
- 完全覆盖 `!`pwd`/subprojects/$ARGUMENTS/NEWS.md` 先添加中文更新日志（格式为无序列表），然后空一行添加分割线，再空一行添加英文翻译。准确传达改动即可，不要添加过多赘述
- 检查 `!`pwd`/subprojects/$ARGUMENTS/README.md` ，如果有陈旧描述，更新它
- 提供一个总结报告
- 询问用户是否满意，获得意见后进行改进
- 如果用户表示满意，添加一个包含此次更改的commit，等待用户最终发布新版本。请**务必**阅读 `!`pwd`/.claude/skills/commit/SKILL.md` 以了解commit规范
