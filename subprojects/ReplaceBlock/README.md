# [RB]方块替换 (ReplaceBlock)

**The English description is below.**

## 简介

此数据包提供了一个强大的 API，可以以完全原版的方式在世界生成后高性能地替换世界中的方块。

## 功能

此数据包以区块为单位遍历并替换方块，每次调用会从当前所在区块向远处遍历，直到成功清除一个区块，或者遍历完加载范围内所有区块。遍历范围可以进行配置，见下文。

## 调用

下文会以 {{storage}} 作为占位符，代指您命令存储的命名空间 ID，例如 `test:test`。

- 准备配置：请在您命令存储的 `{}.replace_block` 中存储 API 配置，可调用 `replace_block:api/reset_settings` 函数并传入 `{storage:"{{storage}}"}` 生成示例配置。完整配置格式见下文。
- 调用函数：调用 `replace_block:api/execute` 函数并传入 `{storage:"{{storage}}"}`，ReplaceBlock 会检测配置并开始遍历和替换。
- 函数返回：如果成功替换了一个或多个区块，`replace_block:api/execute` 函数会返回替换成功的方块总数，如果配置解析错误、维度未加载、遍历范围到达上限等原因并没有成功执行过一次方块替换，函数会返回 fail。

## 配置

以下为完整的配置列表，缺一不可，ReplaceBlock 不会自动回退到某个默认值。

某些字符串会被展开进宏函数，如果提供的值非法，ReplaceBlock 可能会产生一些错误的行为而不一定有明确的报错。

另可查看 [reset_settings.mcfunction](https://github.com/TouchController/E1epack/blob/main/subprojects%2FReplaceBlock%2Fdata%2Freplace_block%2Ffunction%2Fapi%2Freset_settings.mcfunction) 中的示例。

- 替换范围：
  - 路径：`{}.replace_block.search_range`
  - 内容：遍历距离，为 1 即以玩家为中心的 9 个区块。
  - 示例：`3`
- 成功数量：
  - 路径：`{}.replace_block.success_threshold`
  - 内容：一次或多次区块替换视为成功所需的方块替换数量，如果某区块所有方块对成功替换的方块数量总和未达到此数值，则继续遍历下一区块。
  - 示例：`50`
- 要替换的方块对列表：
  - target_block
    - 路径：`{}.replace_block.replace_pairs[].target_block`
    - 内容：将被替换方块的命名空间 ID
    - 示例：`"stone"`
  - replace_with
    - 路径：`{}.replace_block.replace_pairs[].replace_with`
    - 内容：新方块的命名空间 ID
    - 示例：`"air"`
- 替换生效维度列表：
  - dimension
    - 路径：`{}.replace_block.dimensions[].dimension`
    - 内容：替换生效维度的命名空间 ID
    - 示例：`"minecraft:overworld"`
  - min_y
    - 路径：`{}.replace_block.dimensions[].min_y`
    - 内容：替换生效的最小高度，配置错误会导致 fill 命令失败
    - 示例：`-64`
  - max_y
    - 路径：`{}.replace_block.dimensions[].max_y`
    - 内容：替换生效的最大高度，配置错误会导致 fill 命令失败
    - 示例：`319`

---

## Introduction

This datapack provides a powerful API that can replace blocks in the world after world generation in a completely vanilla way with high performance.

## Features

This datapack traverses and replaces blocks chunk by chunk. Each call traverses outward from the current chunk until it successfully clears one chunk, or until it has traversed all loaded chunks in range. The traversal range is configurable, see below.

## Usage

Below, {{storage}} is used as a placeholder for the namespaced ID of your command storage, for example `test:test`.

- Prepare the configuration: Store the API configuration in `{}.replace_block` of your command storage. You can call the `replace_block:api/reset_settings` function and pass `{storage:"{{storage}}"}` to generate a sample configuration. See below for the full configuration format.
- Call the function: Call the `replace_block:api/execute` function and pass `{storage:"{{storage}}"}`. ReplaceBlock will check the configuration and start traversing and replacing.
- Return value: If one or more chunks were successfully replaced, the `replace_block:api/execute` function returns the total number of blocks successfully replaced. If no block replacement was successfully performed due to a configuration parsing error, an unloaded dimension, the traversal range reaching its limit, etc., the function returns fail.

## Configuration

The following is the complete list of configuration options. None of them may be omitted; ReplaceBlock does not automatically fall back to any default value.

Some values are inserted into macro functions. If an invalid value is provided, ReplaceBlock may behave incorrectly, possibly without a clear error message.

You can also see the example in [reset_settings.mcfunction](https://github.com/TouchController/E1epack/blob/main/subprojects%2FReplaceBlock%2Fdata%2Freplace_block%2Ffunction%2Fapi%2Freset_settings.mcfunction).

- Search range:
  - Path: `{}.replace_block.search_range`
  - Description: Traversal distance; a value of 1 means the 9 chunks centered on the player.
  - Example: `3`
- Success threshold:
  - Path: `{}.replace_block.success_threshold`
  - Description: The number of block replacements required for one or more chunk replacements to count as successful. If the total number of successfully replaced blocks for all block pairs in a chunk does not reach this value, traversal continues to the next chunk.
  - Example: `50`
- List of block pairs to replace:
  - target_block
    - Path: `{}.replace_block.replace_pairs[].target_block`
    - Description: Namespaced ID of the block to be replaced
    - Example: `"stone"`
  - replace_with
    - Path: `{}.replace_block.replace_pairs[].replace_with`
    - Description: Namespaced ID of the new block
    - Example: `"air"`
- List of dimensions where replacement takes effect:
  - dimension
    - Path: `{}.replace_block.dimensions[].dimension`
    - Description: Namespaced ID of the dimension where replacement takes effect
    - Example: `"minecraft:overworld"`
  - min_y
    - Path: `{}.replace_block.dimensions[].min_y`
    - Description: Minimum height where replacement takes effect; an incorrect configuration will cause the fill command to fail
    - Example: `-64`
  - max_y
    - Path: `{}.replace_block.dimensions[].max_y`
    - Description: Maximum height where replacement takes effect; an incorrect configuration will cause the fill command to fail
    - Example: `319`
