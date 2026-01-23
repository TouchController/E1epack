"""
翻译模块包
包含自动翻译脚本的各个组件
"""

from .config import *
from .logging import *
from .translator import DeepSeekTranslator
from .git_changes import *
from .file_ops import *
from .translation_flow import *

__all__ = [
    'DeepSeekTranslator',
    'KeyChange',
    'FileChanges',
    'ChangeType',
    'DEEPSEEK_API_URL',
    'SYSTEM_PROMPT_FILE',
    'USER_PROMPT_FILE',
    'ASSETS_DIR',
    'TRANSLATE_DIR',
    'TARGET_LANGUAGES',
    'IS_GITHUB_ACTIONS',
    'get_all_target_languages',
    'log_progress',
    'log_section',
    'log_section_end',
    'ProgressTracker',
    'flush_logs',
    'close_logs',
    'get_git_changes',
    'get_namespace_list',
    'load_namespace_translations_from_translate',
    'save_namespace_translations',
    'get_merged_reference_translations',
    'get_context_for_keys',
    'load_json_file',
    'save_json_file',
]