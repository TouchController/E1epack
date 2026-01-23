#!/usr/bin/env python3
"""
Git变更检测模块 - 包含检测文件变更和键值对变更的函数
"""

import os
import json
import subprocess
from typing import Dict, List, Optional
from pathlib import Path

from translator.config import KeyChange, FileChanges, ChangeType, ASSETS_DIR
from translator.logging import log_progress


def get_git_changes() -> List[FileChanges]:
    """使用 Git 差异收集源目录下所有本地化文件的新增/修改（按命名空间聚合）。删除键不解析。"""
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

        # 按命名空间聚合变更键（仅新增/修改）
        aggregated: Dict[str, Dict[str, Dict[str, KeyChange]]] = {}

        for file_path in changed_files:
            # 仅处理源目录 assets 下的语言文件
            if '/assets/' not in file_path or '/lang/' not in file_path or not file_path.endswith('.json'):
                continue

            parts = file_path.split('/')
            if 'assets' not in parts:
                continue
            assets_index = parts.index('assets')
            if assets_index + 1 >= len(parts):
                continue
            namespace = parts[assets_index + 1]

            changes = get_file_key_changes(file_path)
            if not changes:
                continue

            if namespace not in aggregated:
                aggregated[namespace] = {
                    'added': {},
                    'modified': {}
                }

            for kc in changes['added']:
                aggregated[namespace]['added'][kc.key] = kc
            for kc in changes['modified']:
                aggregated[namespace]['modified'][kc.key] = kc

        # 转换为 FileChanges 列表
        file_changes: List[FileChanges] = []
        for ns, buckets in aggregated.items():
            added = list(buckets['added'].values())
            modified = list(buckets['modified'].values())
            if added or modified:
                file_changes.append(FileChanges(
                    namespace=ns,
                    file_path=f"virtual:{ns}",
                    added_keys=added,
                    deleted_keys=[],
                    modified_keys=modified
                ))

        return file_changes

    except Exception as e:
        log_progress(f"Git差异检测失败: {e}", "error")
        return []


def get_file_key_changes(file_path: str) -> Optional[Dict[str, List[KeyChange]]]:
    """获取单个文件的键值对变更"""
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

        # 比较变更
        old_keys = set(old_data.keys())
        new_keys = set(new_data.keys())

        added_keys = []
        deleted_keys = []
        modified_keys = []

        # 添加的键
        for key in new_keys - old_keys:
            added_keys.append(KeyChange(
                key=key,
                old_value=None,
                new_value=new_data[key],
                operation=ChangeType.ADDED.value
            ))

        # 删除的键
        for key in old_keys - new_keys:
            deleted_keys.append(KeyChange(
                key=key,
                old_value=old_data[key],
                new_value=None,
                operation=ChangeType.DELETED.value
            ))

        # 修改的键（值变化）
        for key in old_keys & new_keys:
            if old_data.get(key) != new_data.get(key):
                modified_keys.append(KeyChange(
                    key=key,
                    old_value=old_data.get(key),
                    new_value=new_data.get(key),
                    operation=ChangeType.MODIFIED.value
                ))

        # 键名重命名检测：将"删除+新增且值相同"的情况归类为修改
        # 仅在唯一匹配时判定为重命名，避免误匹配
        if added_keys and deleted_keys:
            # 构建值到删除项的索引（仅字符串值）
            deleted_index: Dict[str, KeyChange] = {}
            deleted_value_counts: Dict[str, int] = {}
            for d in deleted_keys:
                if isinstance(d.old_value, str):
                    deleted_index[d.old_value] = d
                    deleted_value_counts[d.old_value] = deleted_value_counts.get(d.old_value, 0) + 1

            added_remaining: List[KeyChange] = []
            used_deleted: set = set()

            for a in added_keys:
                if isinstance(a.new_value, str) and a.new_value in deleted_index and deleted_value_counts.get(a.new_value, 0) == 1:
                    d = deleted_index[a.new_value]
                    if d.key not in used_deleted:
                        # 记录为修改（键名重命名）
                        modified_keys.append(KeyChange(
                            key=a.key,
                            old_value=d.old_value,
                            new_value=a.new_value,
                            operation=ChangeType.MODIFIED.value
                        ))
                        used_deleted.add(d.key)
                        log_progress(f"检测到键重命名: {d.key} -> {a.key}")
                        continue
                added_remaining.append(a)

            # 过滤掉已配对的删除项
            deleted_remaining = [d for d in deleted_keys if d.key not in used_deleted]
            added_keys = added_remaining
            deleted_keys = deleted_remaining

        return {
            'added': added_keys,
            'deleted': deleted_keys,
            'modified': modified_keys
        }

    except Exception as e:
        log_progress(f"获取文件变更失败 {file_path}: {e}", "error")
        return None