#!/usr/bin/env python3
"""
配置模块 - 包含翻译脚本的常量、路径和配置函数
"""

import os
import json
from typing import Dict, Optional
from dataclasses import dataclass
from enum import Enum


# 检测是否在GitHub Actions环境中运行
IS_GITHUB_ACTIONS = os.getenv('GITHUB_ACTIONS') == 'true'

@dataclass
class KeyChange:
    """键值对变更信息"""
    key: str
    old_value: Optional[str]
    new_value: Optional[str]
    operation: str  # 'added', 'deleted', 'modified'

@dataclass
class FileChanges:
    """文件变更信息"""
    namespace: str
    file_path: str
    added_keys: list[KeyChange]
    deleted_keys: list[KeyChange]
    modified_keys: list[KeyChange]

class ChangeType(Enum):
    """变更类型枚举"""
    ADDED = "added"
    DELETED = "deleted"
    MODIFIED = "modified"

# 配置
DEEPSEEK_API_URL = "https://api.deepseek.com/chat/completions"
ASSETS_DIR = "subprojects/Localization-Resource-Pack/assets"
TRANSLATE_DIR = "translate"
SYSTEM_PROMPT_FILE = "subprojects/Localization-Resource-Pack/assets/system_prompt.md"
USER_PROMPT_FILE = "subprojects/Localization-Resource-Pack/assets/user_prompt.md"
LANGUAGES_FILE = "subprojects/Localization-Resource-Pack/languages.json"

# 默认目标语言列表（当外部文件不存在或无效时使用）
DEFAULT_TARGET_LANGUAGES = {
    "en_us": "English (US)",
    "pt_br": "Portuguese (Brazil)",
    "ru_ru": "Russian",
    "de_de": "German",
    "es_es": "Spanish (Spain)",
    "es_mx": "Spanish (Mexico)",
    "fr_fr": "French (France)",
    "fr_ca": "French (Canada)",
    "tr_tr": "Turkish",
    "ja_jp": "Japanese",
    "ko_kr": "Korean",
    "pl_pl": "Polish",
    "nl_nl": "Dutch",
    "it_it": "Italian",
    "id_id": "Indonesian",
    "vi_vn": "Vietnamese",
    "zh_tw": "Traditional Chinese (Taiwan)",
    "zh_hk": "Traditional Chinese (Hong Kong)",
    "zh_cn": "Simplified Chinese (China)"
}

def load_target_languages(file_path: str = LANGUAGES_FILE) -> dict:
    """从文件加载目标语言列表，失败则回退到默认列表"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if isinstance(data, dict) and all(isinstance(k, str) and isinstance(v, str) for k, v in data.items()):
            return data
        else:
            print(f"语言列表文件格式无效，使用默认列表")
            return DEFAULT_TARGET_LANGUAGES
    except FileNotFoundError:
        print(f"未找到语言列表文件 {file_path}，使用默认列表")
        return DEFAULT_TARGET_LANGUAGES
    except Exception as e:
        print(f"加载语言列表失败：{e}，使用默认列表")
        return DEFAULT_TARGET_LANGUAGES

# 在导入时加载一次语言列表，提供常量以兼容旧用法
TARGET_LANGUAGES = load_target_languages()

def get_all_target_languages() -> dict:
    """获取所有目标语言（从文件或默认值）"""
    return TARGET_LANGUAGES


# 翻译配置常量
BATCH_SIZE = 40
MAX_CONTEXT = 10
MAX_INDIVIDUAL_RETRIES = 10
CONTEXT_SIZE = 4
DEFAULT_TEMPERATURE = 1.3
TEMPERATURE_ADJUSTMENTS = [1.3, 1.3, 1.2, 1.0, 0.7]
API_TIMEOUT = 60
MIN_KEYS_FOR_CONTEXT = 10