---
name: release
description: 生成发布信息和更新版本号
argument-hint: 输入要发布的项目名称
tools: ['execute', 'read', 'edit', 'search', 'web', 'todo']
---

运行`git tag --list ${selection}_*" | grep -E "${selection}_v[0-9]+\\.[0-9]+\\.[0-9]+$" | sort -V | tail -1`获取最新标签，比对`/${selection}`目录从最新标签到最新commit之间的差异，总结然后执行以下步骤：

- 询问用户此次更新的级别，更新 `/${selection}/BUILD.bazel` 的pack_version，确保符合SemVer规范：请阅读 `/SemVer.md` 以了解命名规范。注意：如果当前pack_version从来没有发布过，则不修改版本号
- 完全覆盖 `/${selection}/NEWS.md` 先添加中文更新日志（格式为无序列表），然后空一行添加分割线，再空一行添加英文翻译。准确传达改动即可，不要添加过多赘述
- 检查 `/${selection}/README.md` ，如果有陈旧描述，更新它
- 提供一个总结报告
- 询问用户是否满意，获得意见后进行改进
- 如果用户表示满意，添加一个包含此次更改的commit，等待用户最终发布新版本。请**务必**阅读 `.claude/commands/commit.md` 以了解commit规范
