#!/usr/bin/env python3
"""
文件操作模块 - 包含JSON文件加载、保存和合并函数
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional, Any

from translator.config import ASSETS_DIR, TRANSLATE_DIR, MAX_CONTEXT
from translator.logging import log_progress


def load_json_file(file_path: str) -> Optional[Dict[str, str]]:
    """加载JSON文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        log_progress(f"文件不存在: {file_path}", "warning")
        return None
    except json.JSONDecodeError as e:
        log_progress(f"JSON解析错误 {file_path}: {e}", "error")
        return None


def save_json_file(file_path: str, data: Dict[str, str]) -> bool:
    """保存JSON文件"""
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        log_progress(f"保存文件失败 {file_path}: {e}", "error")
        return False


def merge_translations(base_dict: Dict[str, str], override_dict: Dict[str, str]) -> Dict[str, str]:
    """合并翻译，override_dict中的内容会覆盖base_dict中的对应内容"""
    result = base_dict.copy()
    result.update(override_dict)
    return result


def get_namespace_list() -> List[str]:
    """获取所有命名空间列表"""
    namespaces = []
    assets_dir = Path(ASSETS_DIR)
    if assets_dir.exists():
        for namespace_dir in assets_dir.iterdir():
            if namespace_dir.is_dir() and namespace_dir.name not in ['system_prompt.md', 'user_prompt.md']:
                lang_dir = namespace_dir / "lang"
                if lang_dir.exists():
                    namespaces.append(namespace_dir.name)
    return namespaces


def load_namespace_translations(namespace: str, lang_code: str) -> Dict[str, str]:
    """加载指定命名空间的翻译"""
    # 先尝试从assets目录加载
    assets_file = Path(ASSETS_DIR) / namespace / "lang" / f"{lang_code}.json"
    if assets_file.exists():
        return load_json_file(str(assets_file)) or {}

    # 再尝试从translate目录加载
    translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
    if translate_file.exists():
        return load_json_file(str(translate_file)) or {}

    return {}


def load_namespace_translations_from_translate(namespace: str, lang_code: str) -> Dict[str, str]:
    """仅从 translate 目录加载指定命名空间的翻译。

    用途：
    - 缺失键扫描与冗余清理仅针对工作目录（translate）
    - assets 目录在构建阶段参与合并，不参与完整性约束
    """
    translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
    if translate_file.exists():
        return load_json_file(str(translate_file)) or {}
    return {}


def save_namespace_translations(namespace: str, lang_code: str, translations: Dict[str, str]) -> bool:
    """保存指定命名空间的翻译到translate目录"""
    translate_dir = Path(TRANSLATE_DIR) / namespace / "lang"
    translate_dir.mkdir(parents=True, exist_ok=True)

    translate_file = translate_dir / f"{lang_code}.json"
    return save_json_file(str(translate_file), translations)


def merge_namespace_translations(namespace: str, lang_code: str) -> Dict[str, any]:
    """合并同命名空间的所有键值对，包括重复键处理

    Args:
        namespace: 命名空间名称
        lang_code: 语言代码

    Returns:
        Dict[str, any]: 合并后的翻译字典，重复键的值为列表
    """
    merged_translations = {}

    # 收集所有可能的翻译文件路径
    file_paths = []

    # assets目录中的文件
    assets_file = Path(ASSETS_DIR) / namespace / "lang" / f"{lang_code}.json"
    if assets_file.exists():
        file_paths.append(assets_file)

    # translate目录中的文件
    translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
    if translate_file.exists():
        file_paths.append(translate_file)

    # 合并所有文件的内容
    for file_path in file_paths:
        translations = load_json_file(str(file_path))
        if not translations:
            continue

        for key, value in translations.items():
            if key in merged_translations:
                # 处理重复键：转换为列表形式
                existing_value = merged_translations[key]
                if isinstance(existing_value, list):
                    # 如果已经是列表，添加新值
                    if value not in existing_value:
                        existing_value.append(value)
                else:
                    # 如果不是列表，创建新列表
                    if existing_value != value:
                        merged_translations[key] = [existing_value, value]
            else:
                merged_translations[key] = value

    return merged_translations


def get_merged_reference_translations(namespace: str) -> Dict[str, any]:
    """获取合并后的参考翻译，包含所有语言文件中的键值对

    Args:
        namespace: 命名空间名称

    Returns:
        Dict[str, any]: 合并后的参考翻译字典，重复键的值为列表
    """
    merged_dict = {}
    namespace_lang_dir = Path(ASSETS_DIR) / namespace / "lang"

    if not namespace_lang_dir.exists():
        return merged_dict

    # 遍历所有语言文件，合并所有键值对
    for lang_file in namespace_lang_dir.glob('*.json'):
        try:
            with open(lang_file, 'r', encoding='utf-8') as f:
                lang_data = json.load(f)
                # 合并键值对，处理重复键转换为列表
                for key, value in lang_data.items():
                    if key in merged_dict:
                        # 处理重复键：转换为列表形式
                        existing_value = merged_dict[key]
                        if isinstance(existing_value, list):
                            # 如果已经是列表，添加新值
                            if value not in existing_value:
                                existing_value.append(value)
                        else:
                            # 如果不是列表，创建新列表
                            if existing_value != value:
                                merged_dict[key] = [existing_value, value]
                    else:
                        merged_dict[key] = value
        except (json.JSONDecodeError, IOError) as e:
            log_progress(f"警告：无法读取语言文件 {lang_file}: {e}", "warning")
            continue

    return merged_dict


def find_existing_translations(lang_code: str) -> Dict[str, str]:
    """查找现有的翻译文件"""
    existing_translations = {}

    # 动态查找assets目录中的所有命名空间
    for namespace in get_namespace_list():
        namespace_translations = load_namespace_translations(namespace, lang_code)
        existing_translations.update(namespace_translations)

    return existing_translations


def get_context_for_keys(source_dict: Dict[str, str], target_keys: List[str], max_context: int = MAX_CONTEXT, force_context: bool = False) -> Dict[str, any]:
    """为目标键获取上下文键值对，并统一使用核心键标记

    两步模型对齐：
    - 第一步（本函数）：在"源语言文件合并后"的字典上工作，若目标数不足上限则按从上到下的分块迭代补前后文；
      另外，若合并后总键数 < max_context，则直接将整个文件纳入请求范围。
    - 第二步：当最终数量超过每批上限，由 split_texts_with_context_guarantee 在分批时添加边界上下文。

    统一标记：
    - 始终添加 `__core_keys__` 标记，列出需要写回的核心键，与第二步保持一致。

    Args:
        source_dict: 合并后的源字典（必须在合并后传入）
        target_keys: 目标键列表（按源顺序）
        max_context: 第一步的上下文上限（通常为 10）
        force_context: 强制上下文模式；在此模式下直接将整个文件纳入范围
    """
    source_keys = list(source_dict.keys())
    all_keys_count = len(source_keys)

    # 强制模式：直接将整个文件纳入范围，并添加统一标记
    if force_context:
        result: Dict[str, any] = dict(source_dict)
        result['__core_keys__'] = list(target_keys)
        return result

    # 如果总键数不超过max_context，直接返回全部
    if all_keys_count <= max_context:
        result: Dict[str, any] = dict(source_dict)
        result['__core_keys__'] = list(target_keys)
        return result

    # 否则，为目标键添加上下文
    target_set = set(target_keys)
    result_keys = list(target_set)  # 起始集合包含目标键

    # 为目标键添加前后上下文（从source_keys中按顺序查找）
    for key in target_keys:
        try:
            idx = source_keys.index(key)
            # 添加上方上下文（前max_context/2个键）
            start = max(0, idx - max_context // 2)
            for i in range(start, idx):
                result_keys.append(source_keys[i])
            # 添加下方上下文（后max_context/2个键）
            end = min(len(source_keys), idx + max_context // 2 + 1)
            for i in range(idx + 1, end):
                result_keys.append(source_keys[i])
        except ValueError:
            continue

    # 去重并保持顺序（按source_keys中的顺序）
    unique_keys = []
    for k in source_keys:
        if k in result_keys and k not in unique_keys:
            unique_keys.append(k)

    # 构建结果字典
    result: Dict[str, any] = {}
    for k in unique_keys:
        result[k] = source_dict[k]
    result['__core_keys__'] = list(target_keys)

    return result