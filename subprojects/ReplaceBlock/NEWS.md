- 支持的 Minecraft 版本范围由 1.20.3-1.21.10 扩展至 1.20.3-26.3
- 移除配置项 `selector`，遍历起点改为 `replace_block:api/execute` 的命令执行位置（由 `at` 更新）
- `replace_block:api/execute` 现在会返回替换成功的方块总数，未成功替换任何区块时返回 fail
- 内部函数统一移入 `private/` 目录，外部只需依赖 `api/` 下的入口
- 更新 README 中的调用示例与配置说明，并补充返回值文档

---

- Expanded the supported Minecraft version range from 1.20.3-1.21.10 to 1.20.3-26.3
- Removed the `selector` configuration option; traversal now starts from the command execution position (updated by `at`) of `replace_block:api/execute`
- `replace_block:api/execute` now returns the total number of blocks successfully replaced, or fail when no chunk was replaced
- Internal functions are now grouped under `private/`, so external callers only need the entry points under `api/`
- Updated the usage examples and configuration description in the README, and documented the return value
