#!/usr/bin/env python3
"""
Git变更检测模块 - 包含检测文件变更和键值对变更的函数
"""

import os
import json
import subprocess
from typing import Dict, List, Optional

from translator.config import KeyChange, FileChanges, ChangeType
from translator.logging import log_progress


def get_git_changes() -> List[FileChanges]:
    """读取 Git 差异，收集需要重新翻译的键：源文本变更与键重命名。

    新增键由缺失键扫描补全，删除键由清理阶段移除，因此这里都不处理。
    """
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', 'HEAD~1', 'HEAD'],
            capture_output=True, text=True, cwd='.'
        )

        if result.returncode != 0:
            log_progress("无法获取Git差异，使用全量翻译模式", "warning")
            return []

        changed_files = result.stdout.strip().split('\n') if result.stdout.strip() else []
        log_progress(f"检测到 {len(changed_files)} 个变更文件")

        # 按命名空间聚合（同一键只保留最后一次判定）
        aggregated: Dict[str, Dict[str, KeyChange]] = {}

        for file_path in changed_files:
            # 仅处理源目录 assets 下的语言文件
            if '/assets/' not in file_path or '/lang/' not in file_path or not file_path.endswith('.json'):
                continue

            parts = file_path.split('/')
            assets_index = parts.index('assets')
            if assets_index + 1 >= len(parts):
                continue
            namespace = parts[assets_index + 1]

            for kc in get_file_key_changes(file_path) or []:
                aggregated.setdefault(namespace, {})[kc.key] = kc

        return [
            FileChanges(namespace=ns, keys=list(keys.values()))
            for ns, keys in aggregated.items() if keys
        ]

    except Exception as e:
        log_progress(f"Git差异检测失败: {e}", "error")
        return []


def get_file_key_changes(file_path: str) -> Optional[List[KeyChange]]:
    """返回单个源语言文件中需要重新翻译的键：值变更与值不变的重命名。"""
    try:
        # 获取旧版本文件内容
        old_content_result = subprocess.run([
            'git', 'show', f'HEAD~1:{file_path}'
        ], capture_output=True, text=True, cwd='.')

        old_data = {}
        if old_content_result.returncode == 0:
            try:
                old_data = json.loads(old_content_result.stdout)
            except json.JSONDecodeError:
                pass

        # 获取新版本文件内容
        new_data = {}
        if os.path.exists(file_path):
            from translator.file_ops import load_json_file
            new_data = load_json_file(file_path) or {}

        changes: List[KeyChange] = []

        # 修改的键（值变化）
        for key in set(old_data) & set(new_data):
            if old_data[key] != new_data[key]:
                changes.append(KeyChange(key=key, operation=ChangeType.MODIFIED.value))

        # 键名重命名检测：删除+新增且值相同，仅在唯一匹配时判定为重命名，避免误匹配
        added = {k: v for k, v in new_data.items() if k not in old_data and isinstance(v, str)}
        deleted: Dict[str, str] = {}  # 值 -> 旧键
        duplicated_values = set()
        for key in set(old_data) - set(new_data):
            value = old_data[key]
            if isinstance(value, str):
                if value in deleted:
                    duplicated_values.add(value)
                deleted[value] = key

        for key, value in added.items():
            if value in deleted and value not in duplicated_values:
                old_key = deleted.pop(value)
                changes.append(KeyChange(key=key, operation=ChangeType.RENAMED.value, renamed_from=old_key))
                log_progress(f"检测到键重命名: {old_key} -> {key}")

        return changes

    except Exception as e:
        log_progress(f"获取文件变更失败 {file_path}: {e}", "error")
        return None
