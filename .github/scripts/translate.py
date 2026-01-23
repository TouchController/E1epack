#!/usr/bin/env python3
"""
自动翻译脚本 - 使用DeepSeek API进行多语言翻译

重构版本：模块化结构，将2000+行代码拆分为多个模块
模块结构：
- translator/config.py: 配置常量、数据类
- translator/logging.py: 日志函数、进度跟踪器
- translator/translator.py: DeepSeekTranslator类（核心翻译逻辑）
- translator/git_changes.py: Git变更检测
- translator/file_ops.py: 文件操作函数
- translator/translation_flow.py: 主流程函数
"""

import sys
import os

# 将translator目录添加到模块搜索路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from translator.translation_flow import main
from translator.logging import flush_logs, close_logs

if __name__ == "__main__":
    try:
        main()
    finally:
        # 确保日志文件被正确关闭
        flush_logs()
        close_logs()