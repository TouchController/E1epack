# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

E1epack 是一个 Minecraft 数据包集合仓库，使用 Bazel 构建系统管理多个独立的数据包子项目。每个子项目都是一个完整的 Minecraft 数据包，支持从 1.13 到最新版本的跨版本兼容。

## 构建系统架构

### 核心文件

- **MODULE.bazel**: 定义 Bazel 依赖（Skylib、rules_pkg、rules_java 等）、Maven 依赖（Jackson、Methanol 等）、以及 Minecraft JAR 下载配置
- **rule/datapack.bzl**: 核心构建宏 `complete_datapack_config`，生成完整的数据包构建 pipeline
- **rule/version.bzl**: 版本范围获取 `minecraft_versions_range()` 和版本段拆分 `version_segments()`
- **rule/minecraft_versions.bzl**: `ALL_MINECRAFT_VERSIONS` 列表（1.13 到 26.2）
- **rule/test_system.bzl**: 测试系统，生成按版本拆分的测试目标

### complete_datapack_config 宏

这是子项目 BUILD.bazel 中使用的核心宏，它会自动：

1. **验证输入**: 验证 `pack_version`（SemVer 2.0.0）、`pack_id`（Minecraft 命名空间 ID）、`game_versions`
2. **拆分版本段**: 按 `COMMAND_BOUNDARIES` 拆分版本列表，每段生成独立的构建目标
3. **处理函数文件**: 调用 `process_mcfunction` 处理 .mcfunction 文件（行连续符、路径映射）
4. **压缩 JSON**: 调用 `process_json` 压缩 JSON 文件为单行格式
5. **合并标签**: 合并来自依赖的 `minecraft/tags/function/*.json` 文件
6. **命令替换**: 对旧版本段应用 `command_replacer`，将新语法替换为旧语法
7. **打包**: 生成 `.zip` 数据包文件
8. **生成测试目标**: 调用 `setup_tests` 生成测试服务器和测试套件

### 生成的构建目标

`complete_datapack_config` 会自动生成以下目标：

- **`<range_name>`**: 版本段数据包 zip（如 `1.13-1.21.10`、`1.21.11-26.2`）
- **`release_<range_name>`**: 带版本号的发布 zip（如 `release_1.13-1.21.10`，输出 `target_name_v1.0.0_range.zip`）
- **`<target_name>`**: filegroup，包含所有 release zip（默认为包目录名，如 `datapack-function-library`）
- **`<pack_id>`**: pkg_filegroup，供其他子项目通过 `deps` 引用
- **`<pack_id>_segment_<N>`**: 版本段变体，供其他子项目的对应版本段引用
- **`server`**: 别名，指向最新版本段的测试服务器
- **`test`、`test_all`、`test_major` 等**: 测试套件

### 版本段拆分机制

`COMMAND_BOUNDARIES` 定义了命令语法变更的版本点：

```python
COMMAND_BOUNDARIES = [
    ("1.21.11", "//rule:data/gamerule_mapping.json"),  # gamerule 命令语法变更
    ("26.1", "//rule:data/time_query_mapping.json"),    # time query 命令语法变更
]
```

`version_segments()` 按这些边界拆分版本列表，每段返回 `(range_name, versions, mapping_labels)`：

- `range_name`: 版本范围名称（如 "1.13-1.21.10"、"1.21.11-26.2"）
- `versions`: 该段包含的版本列表
- `mapping_labels`: 需要应用的命令替换映射文件列表（空表示使用最新语法）

### 命令替换系统

- **rule/command_replacer.bzl**: 对 mcfunction 文件执行基于正则的命令替换
- **rule/scripts/command_replacer.py**: 替换脚本，按 key 长度降序应用替换
- **rule/data/gamerule_mapping.json**: 将 `gamerule minecraft:xxx` 替换为 `gamerule doXxx`
- **rule/data/time_query_mapping.json**: 将 `time query minecraft:xxx` 替换为旧语法

### mcfunction 处理

`rule/process_mcfunction.bzl` 中的 `process_mcfunction` 规则：

- 处理行连续符（`\` 结尾的行）
- 自动映射 `function/` 到 `functions/` 目录（如果没有 functions 目录）
- 使用 Worker 协议提高构建性能
- 提供 `DataPackInfo` provider 用于跨包函数解析
- 检测循环依赖

### 依赖系统

子项目通过 `deps` 参数声明依赖：

- `//subprojects/datapack-function-library`: 依赖 DFL 库（通过 pack_id 目标）
- `//:license_gpl`: 依赖根目录的 LICENSE 文件

依赖会自动：

- 传播 `test_ignore_errors_from`（测试时忽略的命名空间加载错误）
- 合并 `minecraft/tags/function/*.json` 标签文件
- 验证版本范围兼容性（`validate_dep_compatibility`）

## 常用命令

### 构建

```bash
# 构建所有数据包
bazel build //...

# 构建单个子项目（所有版本段的 release zip）
bazel build //subprojects/datapack-function-library

# 构建指定版本段的数据包
bazel build //subprojects/datapack-function-library:1.13-1.21.10

# 构建带版本号的发布包
bazel build //subprojects/datapack-function-library:release_1.13-1.21.10
```

### 测试

```bash
# 测试数据包（最新版本，流式输出）
./test datapack-function-library

# 测试指定版本
./test datapack-function-library --version 1.21.5

# 测试所有版本（仅错误输出）
./test datapack-function-library --version all

# 测试主要版本（每个大版本 + 最新版本）
./test datapack-function-library --version major

# 启动测试服务器（需要指定版本）
./test datapack-function-library --server --version 1.21.5

# 二分查找版本分界点
./test datapack-function-library --bisect 1.19 1.20.4

# 禁用缓存测试
./test datapack-function-library --version 1.21.5 --no-cache
```

### 测试目标命名

测试目标遵循以下模式：

- `test`: 测试最新版本（verbose）
- `test_verbose_<version>`: 测试指定版本（流式输出服务器日志）
- `test_quiet_<version>`: 测试指定版本（仅错误输出）
- `test_all`: 测试所有版本（quiet）
- `test_major`: 测试主要版本（每个 X.Y + 最新版本）
- `test_server_<version>`: 启动测试服务器

## 子项目结构

每个子项目位于 `subprojects/` 目录下：

```text
subprojects/<name>/
├── BUILD.bazel              # 使用 complete_datapack_config 宏
├── data/
│   ├── <pack_id>/           # 数据包内容
│   │   ├── function/        # mcfunction 函数文件
│   │   ├── tags/function/   # 函数标签（load.json、tick.json 等）
│   │   └── *.json           # 其他数据文件
│   ├── <pack_id>-test/      # 测试命名空间
│   │   └── function/
│   │       ├── common/      # 所有版本通用的测试
│   │       ├── 1.21-26.2/   # 版本范围特定的测试
│   │       └── test_runner.mcfunction  # 自动生成的测试入口
│   └── minecraft/           # minecraft 命名空间覆盖
├── pack.png
├── README.md
└── NEWS.md                  # 更新日志（Modrinth changelog）
```

## 测试系统

### 测试目录结构

测试文件位于 `data/<pack_id>-test/function/` 目录，版本目录路由仅适用于测试：

- `common/`: 所有版本通用的测试
- `<version>/`: 特定版本的测试（如 `1.21.5/`）
- `<lo>-<hi>/`: 版本范围的测试（如 `1.21-26.2/`）
- `helper/`: 辅助函数（不作为顶层测试运行，但会被打包供其他测试调用）

### 测试函数约定

测试函数名称是文件路径（不含 `.mcfunction` 后缀），例如：

- `common/count-entity`
- `1.21-26.2/load-function-loaded`

测试函数使用 `function <ns>:test/pass` 标记通过，不调用则自动失败（除非需要覆盖已设置的 pass 标志才显式调用 fail）：

```mcfunction
# 测试函数示例
# ... 测试逻辑 ...
execute if <条件> run function dfl:test/pass
```

测试运行器会自动：

1. 创建 `testing` scoreboard
2. 调用测试函数
3. 检查 `result testing` 的值
4. 输出 `[[TEST][<name>][PASS]]` 或 `[[TEST][<name>][FAIL]]`
5. 移除 `testing` scoreboard

### 测试运行器

- **rule/tools/test_runner/TestRunner.java**: 通过 RCON 与测试服务器通信
- **rule/tools/test_runner/run_test.sh**: 启动服务器并管道输出到 TestRunner
- **rule/tools/dev_launch_wrapper/DevLaunchWrapper.java**: 启动 Minecraft 服务器的包装器

测试流程：

1. 启动 Minecraft 服务器（指定版本）
2. 复制数据包到 `world/datapacks/`
3. 通过 RCON 执行 `function <test_ns>:_test_runner`
4. 解析服务器输出中的测试结果标记

### 测试端口分配

每个版本使用独立的端口：

- 游戏端口: `49152 + version_index * 2`
- RCON 端口: `49152 + version_index * 2 + 1`

### 辅助测试脚本

除了 `./test` 便捷脚本外，`scripts/` 目录下还有额外的测试工具：

- **`scripts/test_loop.sh`**: 循环运行测试 N 次，统计失败率。用法：`./scripts/test_loop.sh <数据包名> <版本> [次数]`
- **`scripts/bisect_tests.py`**: 通过二分查找定位测试失败的版本分界点。由 `./test --bisect` 调用，也可直接使用

`./test` 脚本本身是指向 `scripts/run_test.sh` 的符号链接，封装了 Bazel 目标选择和参数解析逻辑。

## game 目录与 Fabric 模组支持

### game/ 目录

`game/BUILD.bazel` 为每个 Minecraft 版本的 server JAR 提供构建目标，处理不同版本的 JAR 格式差异：

- **1.18+（bundler JAR）**: 使用 `extract_jar` 从多版本 JAR 中提取内嵌的 `server-<version>.jar`
- **pre-1.18（plain JAR）**: 直接使用原始 server JAR
- **pre-1.14.3**: 额外应用 `patch_funcman` 工具修补 FunctionManager 权限（`gameRuleType` 2 → 4）
- **1.21.9+**: 额外需要 Fabric Loader 和 Mixin 依赖（通过 `game/<version>/` 子目录的 `maven_install_fabric.json` 锁定）

每个版本生成 `//game:server_<version>` java_import 目标（版本号中的 `.` 替换为 `_`），供子项目引用。`//game:ops_json` 提供测试服务器的管理员配置。

### JAR 重映射系统

对于需要反混淆的 Minecraft 版本（1.21.9-1.21.11），项目使用 Tiny Remapper 进行 JAR 重映射：

- **`rule/remap_jar.bzl`**: JAR 重映射规则，基于 tiny 格式的映射文件，支持 mixin 处理、access widener 重映射、refmap 内联、Jar-in-Jar 移除等
- **`rule/merge_mapping.bzl`**: 映射文件合并/转换规则，将 ProGuard 格式的 mapping 转换为 tiny 格式
- **`rule/mapping_merger/`**: MappingMerger Java 工具，执行映射文件的合并和命名空间操作（如 `changeSrc`）
- **`rule/tiny_remapper_worker/`**: Tiny Remapper Worker，使用 Bazel Worker 协议高效执行重映射，包含 `MixinRefmapInliner`、`AccessWidenerRemapper`、`JarInJarRemover` 等组件

### 非数据包子项目

部分子项目不是传统的数据包，而是 Fabric 模组：

- **`spawn-chunk-fix`**: Fabric 模组，通过 Mixin 修改 Minecraft 服务器行为。需要先编译为 named namespace 的 JAR（依赖反混淆后的 server），再重映射回 official namespace 用于部署。源代码在 `src/main/java/`（26.1+ 使用）和 `src/main/v21/java/`（1.21.9-1.21.11 使用）两个目录中，对应不同的 Minecraft 版本 API

### Fabric 依赖管理

`MODULE.bazel` 中为每个需要 Fabric 的版本配置了独立的 `maven_fabric_<version>` 仓库，锁定 Fabric Loader 和 Mixin 版本。使用 `scripts/repin_fabric.sh` 更新这些 Maven 依赖的 lock 文件。

## 映射与版本兼容性

### 映射类型

不同 Minecraft 版本使用不同的映射：

- **1.13-1.21.8**: 使用 ProGuard mapping（MoJang 提供的混淆映射），需要 `mapping = True` 下载
- **1.21.9-1.21.11**: 同样使用 ProGuard mapping，但通过 Tiny Remapper 转换为 tiny 格式用于 Fabric 模组开发
- **26.1+**: Mojang 已公开官方映射，不再需要 ProGuard mapping（`repo/minecraft_jar.bzl` 中 mapping 下载失败时仅为警告，不再报错）

### 版本段与 Fabric 测试

从 1.21.9 开始，测试服务器使用 Fabric Loader（`KnotServer`）而非 vanilla 主类启动，并自动加载 `spawn-chunk-fix` 模组。测试系统（`rule/test_system.bzl`）自动检测版本是否需要 Fabric 运行时。

## CI/CD

项目在 `.github/workflows/` 下配置了 4 个 GitHub Actions 工作流：

### build.yml

- 触发条件：PR 和 push
- 运行 `bazel build --verbose_failures //...`
- 收集所有 release zip 作为 artifact
- **失败时自动创建 issue**：包含失败 commit 信息和构建日志片段（防止重复创建）

### check.yml

- 触发条件：PR 和 push
- 扫描所有 `BUILD.bazel` 文件，检查 `modrinth_project_id` 和 `pack_id` 是否重复
- **失败时自动创建 issue**：包含重复 ID 和涉及的文件列表

### release.yml

- 触发条件：推送 tag（格式 `<项目名>_v<版本>`，如 `datapack-function-library_v1.0.0`）
- 从 tag 提取项目名和版本号
- 从项目的 `NEWS.md` 读取发布说明
- 构建该项目并创建 GitHub Release（含 Discussion）

### translate.yml

- 触发条件：`Localization-Resource-Pack` 相关文件变更或手动触发
- 使用 DeepSeek API（`deepseek-v4-pro`）自动翻译资源包语言文件
- 支持强制翻译、debug 日志等选项

## 开发流程

### 添加新数据包

1. 在 `subprojects/` 下创建新目录
2. 创建 `BUILD.bazel`：

    ```python
    load("@//rule:datapack.bzl", "complete_datapack_config")
    load("@//rule:version.bzl", "minecraft_versions_range")

    pack_version = "1.0.0"

    complete_datapack_config(
        game_versions = minecraft_versions_range("1.20"),
        modrinth_project_id = "xxx",  # 可选
        pack_id = "my_pack",
        pack_version = pack_version,
        deps = [
            "README.md",
            "pack.png",
            "//:license_gpl",
            "//subprojects/datapack-function-library",  # 可选依赖
        ],
    )
    ```

3. 在 `data/<pack_id>/` 下添加数据包内容
4. 在 `data/<pack_id>-test/function/` 下添加测试
5. 运行 `./test <pack_name>` 验证

### 编写测试

测试文件放在 `data/<pack_id>-test/function/` 下：

- `common/` 目录：所有版本通用
- `<version>/` 或 `<lo>-<hi>/` 目录：特定版本或范围

测试函数命名应类似陈述句（如 `load-function-loaded`、`datapack-banner-working`），示例：

```mcfunction
# 文件: data/my_pack-test/function/common/load-function-loaded.mcfunction
# ... 测试逻辑 ...
execute if <条件> run function dfl:test/pass
```

如果需要为不同版本编写不同测试逻辑：

1. 将通用测试放在 `common/` 目录
2. 将版本特定测试放在对应版本目录
3. 使用 `function <ns>:common/helper` 调用辅助函数

## 构建工具

### Java 工具

- **rule/tools/mcfunction_processor/**: mcfunction 文件处理器（Worker 协议）
- **rule/tools/json_compressor/**: JSON 压缩器（Worker 协议）
- **rule/tools/extract/**: JAR 文件提取器
- **rule/tools/patch_funcman/**: FunctionManager 权限补丁（1.14.3 之前版本）
- **rule/tools/modrinth_uploader/**: Modrinth 上传工具

### Python 脚本

- **rule/scripts/command_replacer.py**: 命令替换脚本
- **rule/scripts/merge_tags.py**: 标签合并脚本
- **rule/scripts/generate_test_runner.py**: 测试运行器生成脚本
- **bisect_tests.py**: 二分查找版本分界点

## 版本兼容性

### 支持的版本

`ALL_MINECRAFT_VERSIONS` 包含从 1.13 到 26.2 的所有版本。新版本需要在 `rule/minecraft_versions.bzl` 中添加。

### 命令语法变更

当 Minecraft 更新命令语法时：

1. 在 `rule/data/` 添加新的 mapping JSON 文件
2. 在 `rule/version.bzl` 的 `COMMAND_BOUNDARIES` 添加边界
3. 构建系统会自动为旧版本段应用替换

### 版本段选择

子项目通过 `game_versions` 参数选择支持的版本范围：

- `minecraft_versions_range("1.20")`: 从 1.20 到最新版本
- `minecraft_versions_range("1.13.2", "1.20.2")`: 指定范围

## 注意事项

- 使用 Java 21 进行构建（`.bazelrc` 配置）
- 测试服务器使用动态分配端口（从 49152 开始）
- 测试超时默认 300 秒（`timeout = "moderate"`）
- 版本号必须符合 SemVer 2.0.0 规范
- pack_id 必须符合 Minecraft 命名空间 ID 规范（小写字母、数字、下划线、连字符、点）
- target_name 不能与 pack_id 相同（会导致目标名冲突）
