# [RB]方块替换 (ReplaceBlock)

**The English description is below.**

## 简介

此数据包提供了一个强大的 API，可以以完全原版的方式在世界生成后高性能地替换世界中的方块。

## 功能

此数据包以区块为单位遍历并替换方块，每次调用会从目标实体所在区块向远处遍历，直到成功清除一个区块，或者遍历完加载范围内所有区块。遍历范围可以进行配置，见下文。

## 调用

要调用 API，请先在您命令存储的 `{}.replace_block` 中存储 API 配置，可调用 `replace_block:api/reset_settings` 函数并传入 `{storage:"您命令存储的命名空间 ID"}` 生成示例配置，然后调用 `replace_block:api/execute` 函数并传入 `{storage:"您命令存储的命名空间 ID"}`。方块替换将立即开始，并在同一 tick 内结束。请务必确认您的配置包含所有要求的数据，ReplaceBlock 会验证您的配置参数，若缺失参数会导致 API 调用失败。

## 配置

以下为完整的配置列表，另可查看 [reset_settings.mcfunction](https://github.com/TouchController/E1epack/blob/main/ReplaceBlock/data/replace_block/function/api/reset_settings.mcfunction) 中的示例。

- 目标选择器：
  - 路径：`{}.replace_block.selector`
  - 内容：一个目标选择器，可包含参数。
  - 示例：`"@e[type=player]"`
- 替换范围：
  - 路径：`{}.replace_block.search_range`
  - 内容：遍历距离，为 1 即以玩家为中心的 9 个区块。
  - 示例：`3`
- 成功数量：
  - 路径：`{}.replace_block.success_threshold`
  - 内容：一次区块替换视为成功所需的方块替换数量，如果某区块所有方块对成功替换的方块数量总和未达到此数值，则继续遍历下一区块。
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
    - 内容：替换生效的最小高度
    - 示例：`-64`
  - max_y
    - 路径：`{}.replace_block.dimensions[].max_y`
    - 内容：替换生效的最大高度
    - 示例：`319`

---

## Introduction

This datapack provides a powerful API that can replace blocks in the world with high performance in a completely vanilla way after world generation.

## Features

This datapack traverses and replaces blocks chunk by chunk. Each call will traverse from the target entity's current chunk outward until successfully clearing one chunk or traversing all chunks within the loaded range. The traversal range can be configured as described below.

## Usage

To use the API, first store the API configuration in your command storage at `{}.replace_block`. You can call the `replace_block:api/reset_settings` function with `{storage:"your command storage namespace ID"}` to generate example configuration, then call the `replace_block:api/execute` function with `{storage:"your command storage namespace ID"}`. Block replacement will start immediately and end within the same tick. Please ensure your configuration contains all required data. ReplaceBlock will validate your configuration parameters, and missing parameters will cause API calls to fail.

## Configuration

Below is the complete configuration list. You can also view the example in [reset_settings.mcfunction](https://github.com/TouchController/E1epack/blob/main/ReplaceBlock/data/replace_block/function/api/reset_settings.mcfunction).

- Target Selector:
  - Path: `{}.replace_block.selector`
  - Content: A target selector that can include parameters.
  - Example: `"@e[type=player]"`
- Search Range:
  - Path: `{}.replace_block.search_range`
  - Content: Traversal distance, where 1 means 9 chunks centered on the player.
  - Example: `3`
- Success Threshold:
  - Path: `{}.replace_block.success_threshold`
  - Content: Number of block replacements required for a chunk replacement to be considered successful. If the total number of successfully replaced blocks in a chunk does not reach this value, traversal continues to the next chunk.
  - Example: `50`
- Replacement Block Pairs List:
  - target_block
    - Path: `{}.replace_block.replace_pairs[].target_block`
    - Content: Namespace ID of the block to be replaced
    - Example: `"stone"`
  - replace_with
    - Path: `{}.replace_block.replace_pairs[].replace_with`
    - Content: Namespace ID of the new block
    - Example: `"air"`
- Effective Dimensions List:
  - dimension
    - Path: `{}.replace_block.dimensions[].dimension`
    - Content: Namespace ID of the dimension where replacement takes effect
    - Example: `"minecraft:overworld"`
  - min_y
    - Path: `{}.replace_block.dimensions[].min_y`
    - Content: Minimum height where replacement takes effect
    - Example: `-64`
  - max_y
    - Path: `{}.replace_block.dimensions[].max_y`
    - Content: Maximum height where replacement takes effect
    - Example: `319`
