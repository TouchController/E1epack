# DeepSeek 用户提示词

请将以下游戏本地化文本翻译成{{target_language}}：

## 翻译要求

### 1. 格式要求

- **严格保持JSON格式**：输出必须是有效的JSON对象
- **保留所有键名**：不要修改JSON的键（key），只翻译值（value）
- **保持特殊标记**：保留所有格式标记，如 `%s`、`%n$s`、`\n` 等

### 2. 翻译标准

- **游戏术语一致性**：使用标准的{{target_language}}游戏术语
- **自然流畅**：确保翻译后的文本在{{target_language}}中读起来自然，但优先保证与原文意义的一致性
- **专有名词**：对于Minecraft等游戏的专有名词，使用官方{{target_language}}译名

### 3. 特殊处理

- **变量占位符**：保持 `%s`、`%1$s` 等变量占位符不变
- **换行符**：保持 `\n` 换行符
- **颜色代码**：保持 `§` 开头的颜色代码不变
- **命令格式**：保持游戏命令格式不变
- **翻译参考**：如果遇到列表格式，则应当参考列表中的所有条目进行翻译。**重要提示：最终输出必须是一个包含{{target_language}}语言的单一字符串，而不是一个JSON数组或列表。**

### 4. 特殊要求

**如果遇到**以下两个键值对，将`subtitle`作为上半句，`actionbar`作为下半句，以保证渲染的正确性。但是，如果目标语言文本较短，可以直接根据源文本翻译。

```json
{
  "title.lucky_block_island.error.subtitle": "Dimension settings validation failed!",
  "title.lucky_block_island.error.actionbar": "Please load the datapack when creating the world!"
}
```

## 待翻译内容

```json
{{content_to_translate}}
```

## 输出要求

请直接输出翻译后的JSON内容，不要添加任何解释或额外文本。确保输出是有效的JSON格式。
