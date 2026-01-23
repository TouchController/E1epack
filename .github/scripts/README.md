# 自动翻译系统

基于DeepSeek-V3.2 API的多语言自动翻译系统，支持18种目标语言的高质量游戏本地化翻译。

## 🌟 功能特性

### 🤖 智能翻译引擎

- **DeepSeek-V3.2 API** - 最新的AI模型，同时兼具思考与非思考能力
- **双模式支持**：
  - **思考模式**（默认）：深度推理，翻译质量更高
  - **非思考模式**：快速响应，适合测试和快速验证
- **专业游戏本地化** - 针对Minecraft内容优化的提示词
- **温度1.3设置** - 平衡准确性与自然度

### 🌍 多语言支持

- 目标语言从 `subprojects/Localization-Resource-Pack/languages.json` 动态加载。默认包含 19 种语言（含 `zh_cn`）。
- 如需增删语言，请编辑 `subprojects/Localization-Resource-Pack/languages.json` 并提交 PR；本地运行直接修改该文件即可。

当前默认语言：

- `en_us` - English (US)
- `pt_br` - Portuguese (Brazil)
- `ru_ru` - Russian
- `de_de` - German
- `es_es` - Spanish (Spain)
- `es_mx` - Spanish (Mexico)
- `fr_fr` - French (France)
- `fr_ca` - French (Canada)
- `tr_tr` - Turkish
- `ja_jp` - Japanese
- `ko_kr` - Korean
- `pl_pl` - Polish
- `nl_nl` - Dutch
- `it_it` - Italian
- `id_id` - Indonesian
- `vi_vn` - Vietnamese
- `zh_tw` - Traditional Chinese (Taiwan)
- `zh_hk` - Traditional Chinese (Hong Kong)
- `zh_cn` - Simplified Chinese (China)

### 🔍 质量保证

- **占位符验证** - 自动检查格式化占位符（%s、%n$s等）一致性
- **JSON完整性检查** - 验证翻译结果的键完整性和值类型
- **智能重试机制** - 区分API失败和验证失败，各自独立重试（最多10次），并结合温度调整和思考模式切换策略，确保翻译成功率。
- **详细日志记录** - 记录翻译失败的详细信息、错误原因、模型、温度、命名空间和目标语言。

### ⚙️ 并发与重试优化

- **并发批处理** - 使用线程池并发执行请求，默认每批 `40` 个键；超出将自动分批并保留上下文片段以提高一致性。
- **独立重试计数** - 对 API 失败与验证失败分别计数，单类失败最多重试 `10` 次，失败总览会在日志中汇总显示。
- **自适应温度与模式** - 验证失败前 `1–5` 次按温度序列 `[1.3, 1.3, 1.2, 1.0, 0.7]` 保持当前模式；之后按同温度序列交替切换思考/非思考模式，帮助稳定结果。
- **进度与批次日志** - 输出批次规模与总进度，失败时记录尝试次数、失败类型与等待回退时间。

### ⚡ 自动化工作流

- **智能触发** - 监听源文件变更自动执行翻译
- **增量翻译** - 只翻译缺失或新增的内容
- **文件保护** - 保留现有高质量翻译，避免覆盖
- **自动提交** - 翻译完成后自动提交到仓库

## 📁 系统架构

```text
源文件 (zh_cn.json) → DeepSeek-V3.2 API → translate/ 目录 → 自动提交
```

### 核心组件

- **`translate.py`** - 主翻译脚本
- **`../workflows/translate.yml`** - GitHub Actions工作流
- **提示词模板** - 系统和用户提示词模板

### 目录结构

```text
.github/
├── workflows/translate.yml     # GitHub Actions工作流
└── scripts/
    ├── translate.py           # 主翻译脚本
    └── README.md             # 本文档

translate/                     # 翻译输出目录
├── localization_resource_pack/
│   └── lang/
│       ├── en_us.json
│       ├── pt_br.json
│       └── ...
└── white_elephant/
    └── lang/
        ├── en_us.json
        └── ...

subprojects/Localization-Resource-Pack/
└── assets/
    ├── localization_resource_pack/
    │   └── lang/
    │       └── zh_cn.json     # 语言文件
    └── white_elephant/
        └── lang/
            └── zh_cn.json     # 语言文件
```

## 🚀 使用方法

### 自动触发

1. 修改 `subprojects/Localization-Resource-Pack/assets/` 目录中的源文件
2. 推送到GitHub仓库
3. 工作流自动执行翻译

### 手动触发

1. 访问GitHub仓库的Actions页面
2. 选择"Auto Translate"工作流
3. 点击"Run workflow"
4. 可选择以下选项：
   - **强制重新翻译所有文件** - 忽略现有翻译，重新翻译所有内容
   - **使用非思考模式翻译** - 使用快速模式，适合测试和快速验证

### 本地测试

```bash
# 设置API密钥
export DEEPSEEK_API_KEY="your_api_key_here"

# 运行翻译脚本
python .github/scripts/translate.py
```

## ⚙️ 配置说明

### 环境变量

- `DEEPSEEK_API_KEY` - DeepSeek API密钥（在GitHub Secrets中配置）
- `FORCE_TRANSLATE` - 强制重新翻译所有文件（可选，默认为false）
- `NON_THINKING_MODE` - 使用非思考模式翻译（可选，默认为false）
- `TRANSLATION_DEBUG` - 开启详细请求/响应记录（可选，默认为false）
- `GITHUB_ACTIONS` - CI环境标识，启用日志分组与提示格式（自动）

### 提示词模板变量

提示词模板支持以下变量替换：

- `{{target_language}}` - 目标语言名称
- `{{content_to_translate}}` - 待翻译的JSON内容

### API参数

- **模型**: DeepSeek-V3.2（同时兼具思考与非思考能力）
- **温度**: 1.3（提高翻译的创造性和自然度）
- **批处理**: 每次最多翻译40个键值对

## 🛠️ 故障排除

### 常见问题

1. **API调用失败**
   - 检查 `DEEPSEEK_API_KEY` 是否正确配置
   - 确认API密钥有足够的额度
   - 检查网络连接

2. **翻译质量问题**
   - 可以手动编辑翻译文件
   - 手动翻译在下次合并时会保持不变

3. **文件格式问题**
   - 检查JSON格式是否正确
   - 确认文件编码为UTF-8

### 日志查看

- **GitHub Actions日志** - 查看工作流运行的详细过程
- **本地主日志** - 在仓库根目录生成 `translation.log`
- **详细失败日志** - 在 `.github/scripts/logs/` 目录生成失败明细于 `error_summary.log`

## 📈 更新历史

- **v1.4** - 添加质量保证功能：占位符验证、JSON完整性检查、重试机制
- **v1.5** - 支持DeepSeek-V3.2双模式，添加非思考模式选项
- **v1.6** - 优化工作流，移除冗余步骤，完善日志系统
- **v1.7** - 优化重试机制（独立计数、智能调整）、完善日志记录（模型、温度、命名空间、目标语言）、优化提示词。
- **v1.8** - 新增环境变量（`TRANSLATION_DEBUG`、改进 `FORCE_TRANSLATE` 行为）、完善并发批处理与自适应重试（API/验证各自最多10次），目标语言包含 `zh_cn`，缺失/清理逻辑以 `translate/` 为准并在构建时与 `assets/` 合并。

## 🤝 贡献指南

如需修改翻译逻辑或添加新语言支持：

1. 修改 `translate.py` 中的 `TARGET_LANGUAGES` 字典
2. 调整翻译提示以提高质量
3. 测试新的语言支持
4. 提交Pull Request

---

本翻译系统使用DeepSeek-V3.2 API自动完成多语言翻译任务，为Minecraft数据包提供高质量的本地化支持。
