#!/usr/bin/env python3
"""
自动翻译脚本 - 使用DeepSeek API进行多语言翻译
"""

import os
import sys
import json
import requests
import time
import subprocess
import re

import concurrent.futures
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass
from enum import Enum
import logging
from datetime import datetime

# 检测是否在GitHub Actions环境中运行
IS_GITHUB_ACTIONS = os.getenv('GITHUB_ACTIONS') == 'true'

# 配置详细日志
handlers = [logging.FileHandler('translation.log', encoding='utf-8')]
# 在非GitHub Actions环境中添加控制台输出
if not IS_GITHUB_ACTIONS:
    handlers.append(logging.StreamHandler(sys.stdout))

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=handlers,
    force=True
)
logger = logging.getLogger(__name__)

def flush_logs():
    """强制刷新所有日志处理器"""
    for handler in logging.getLogger().handlers:
        handler.flush()

def close_logs():
    """关闭所有日志处理器"""
    for handler in logging.getLogger().handlers:
        if hasattr(handler, 'close'):
            handler.close()

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
    added_keys: List[KeyChange]
    deleted_keys: List[KeyChange]
    modified_keys: List[KeyChange]

class ChangeType(Enum):
    """变更类型枚举"""
    ADDED = "added"
    DELETED = "deleted"
    MODIFIED = "modified"

def log_progress(message: str, level: str = "info"):
    """统一的进度日志函数，在GitHub Actions中使用特殊格式"""
    timestamp = datetime.now().strftime("%H:%M:%S")

    # 始终写入日志文件
    if level == "error":
        logger.error(message)
    elif level == "warning":
        logger.warning(message)
    else:
        logger.info(message)

    if IS_GITHUB_ACTIONS:
        # GitHub Actions 特殊格式输出到控制台
        if level == "error":
            print(f"::error::{message}")
        elif level == "warning":
            print(f"::warning::{message}")
        else:
            print(f"::notice::[{timestamp}] {message}")

    # 强制刷新输出缓冲区
    sys.stdout.flush()

def log_section(title: str):
    """记录主要章节，在GitHub Actions中使用分组"""
    if IS_GITHUB_ACTIONS:
        print(f"::group::{title}")
    log_progress(f"=== {title} ===")

def log_section_end():
    """结束章节分组"""
    if IS_GITHUB_ACTIONS:
        print("::endgroup::")

class ProgressTracker:
    """进度跟踪器"""
    def __init__(self, total_languages: int, total_namespaces: int):
        self.total_languages = total_languages
        self.total_namespaces = total_namespaces
        self.current_language = 0
        self.current_namespace = 0
        self.start_time = time.time()

    def start_language(self, lang_code: str, lang_name: str):
        self.current_language += 1
        self.current_namespace = 0
        elapsed = time.time() - self.start_time
        log_section(f"语言 {self.current_language}/{self.total_languages}: {lang_code} ({lang_name}) - 已用时 {elapsed:.1f}s")

    def start_namespace(self, namespace: str):
        self.current_namespace += 1
        log_progress(f"  命名空间 {self.current_namespace}/{self.total_namespaces}: {namespace}")

    def log_batch_progress(self, batch_num: int, total_batches: int, batch_size: int):
        log_progress(f"    批次 {batch_num}/{total_batches} (每批 {batch_size} 个键)")

    def finish_language(self):
        log_section_end()

    def get_total_progress(self) -> str:
        total_tasks = self.total_languages * self.total_namespaces
        completed_tasks = (self.current_language - 1) * self.total_namespaces + self.current_namespace
        percentage = (completed_tasks / total_tasks) * 100 if total_tasks > 0 else 0
        elapsed = time.time() - self.start_time
        return f"总进度: {completed_tasks}/{total_tasks} ({percentage:.1f}%) - 已用时 {elapsed:.1f}s"

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
            log_progress(f"已从 {file_path} 加载目标语言列表，共 {len(data)} 种")
            return data
        else:
            log_progress("语言列表文件格式无效，使用默认列表", "warning")
            return DEFAULT_TARGET_LANGUAGES
    except FileNotFoundError:
        log_progress(f"未找到语言列表文件 {file_path}，使用默认列表", "warning")
        return DEFAULT_TARGET_LANGUAGES
    except Exception as e:
        log_progress(f"加载语言列表失败：{e}，使用默认列表", "warning")
        return DEFAULT_TARGET_LANGUAGES

# 在导入时加载一次语言列表，提供常量以兼容旧用法
TARGET_LANGUAGES = load_target_languages()



def get_all_target_languages() -> dict:
    """获取所有目标语言（从文件或默认值）"""
    return TARGET_LANGUAGES



class DeepSeekTranslator:
    def __init__(self, api_key: str, non_thinking_mode: bool = False):
        self.api_key = api_key
        self.non_thinking_mode = non_thinking_mode
        # 调试模式：在每次请求前记录详细日志（与错误日志格式一致）
        self.debug_mode = os.getenv('TRANSLATION_DEBUG', 'false').lower() == 'true'
        self.headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        self._init_error_logging()
        self.system_prompt = self._load_prompt_template(SYSTEM_PROMPT_FILE)
        self.user_prompt = self._load_prompt_template(USER_PROMPT_FILE)



    def _init_error_logging(self):
        """初始化错误日志系统"""
        log_dir = os.path.join(os.path.dirname(__file__), "logs")
        os.makedirs(log_dir, exist_ok=True)

        # 创建新的错误汇总日志文件
        summary_file = os.path.join(log_dir, "error_summary.log")
        session_start = datetime.now().isoformat()

        with open(summary_file, 'w', encoding='utf-8') as f:
            f.write(f"翻译错误汇总日志\n")
            f.write(f"会话开始时间: {session_start}\n")
            f.write(f"模式: {'非思考模式' if self.non_thinking_mode else '思考模式'}\n")
            f.write("=" * 80 + "\n\n")

    def _load_prompt_template(self, file_path: str) -> str:
        """加载提示词模板文件，跳过标题行"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            # 跳过以 # 开头的标题行和空行
            content_lines = []
            for line in lines:
                stripped_line = line.strip()
                # 跳过标题行（以#开头）和空行，但保留内容开始后的空行
                if content_lines or (stripped_line and not stripped_line.startswith('#')):
                    content_lines.append(line)

            return ''.join(content_lines).strip()
        except FileNotFoundError:
            log_progress(f"警告：提示词模板文件 {file_path} 不存在，使用默认提示词", "warning")
            return ""
        except Exception as e:
            log_progress(f"警告：加载提示词模板 {file_path} 时出错: {e}", "warning")
            return ""

    def _format_prompt(self, template: str, **kwargs) -> str:
        """格式化提示词模板，替换变量"""
        try:
            # 使用双大括号格式进行变量替换
            formatted = template
            for key, value in kwargs.items():
                formatted = formatted.replace(f"{{{{{key}}}}}", str(value))
            return formatted
        except Exception as e:
            log_progress(f"警告：格式化提示词时出错: {e}", "warning")
            return template

    def validate_placeholder_consistency(self, original_text: str, translated_text: str) -> bool:
        """验证翻译前后的占位符一致性

        只检查有效的本地化参数格式：%s 和 %n$s
        """
        # 匹配 %s 和 %n$s 格式的占位符
        placeholder_pattern = r'%(?:\d+\$)?s'

        original_placeholders = re.findall(placeholder_pattern, original_text)
        translated_placeholders = re.findall(placeholder_pattern, translated_text)

        # 排序后比较，确保占位符完全一致
        return sorted(original_placeholders) == sorted(translated_placeholders)

    def validate_translation_result(self, original: Dict[str, any], translated: Dict[str, str]) -> List[str]:
        """验证翻译结果的完整性和格式正确性

        Args:
            original: 原始文本字典，可能包含列表类型的值
            translated: 翻译结果字典，应该只包含字符串类型的值

        Returns:
            List[str]: 错误信息列表，空列表表示验证通过
        """
        errors = []

        # 1. 检查键完整性
        original_keys = set(original.keys())
        translated_keys = set(translated.keys())

        if original_keys != translated_keys:
            missing_keys = original_keys - translated_keys
            extra_keys = translated_keys - original_keys

            if missing_keys:
                errors.append(f"缺少键: {list(missing_keys)}")
            if extra_keys:
                errors.append(f"多余键: {list(extra_keys)}")

        # 2. 检查值类型和占位符一致性
        for key in original_keys & translated_keys:
            translated_value = translated.get(key)

            # 翻译结果必须是字符串
            if not isinstance(translated_value, str):
                errors.append(f"键 '{key}' 的值不是字符串类型: {type(translated_value)}")
                continue

            # 获取原始值进行占位符检查
            original_value = original[key]

            # 如果原始值是列表，使用第一个元素进行占位符验证
            # 因为列表中的所有元素应该具有相同的占位符模式
            if isinstance(original_value, list):
                if original_value:  # 确保列表不为空
                    reference_value = str(original_value[0])
                else:
                    reference_value = ""
            else:
                reference_value = str(original_value)

            # 检查占位符一致性（允许空值）
            if not self.validate_placeholder_consistency(reference_value, translated_value):
                errors.append(f"键 '{key}' 的占位符不一致: '{reference_value}' -> '{translated_value}'")

        return errors

    def log_translation_failure(self, attempt: int, system_prompt: str, user_prompt: str,
                              api_response: str, error: str, texts: Dict[str, str],
                              namespace: str = "unknown", target_lang_name: str = "unknown",
                              model: str = "unknown", temperature: float = 1.3,
                              log_to_main: bool = True) -> None:
        """记录翻译失败的详细信息到日志文件"""
        log_dir = os.path.join(os.path.dirname(__file__), "logs")
        os.makedirs(log_dir, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]  # 包含毫秒
        log_file = os.path.join(log_dir, f"translation_failure_{timestamp}_attempt_{attempt}.log")

        # 详细错误日志
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(f"翻译失败日志 - 尝试次数: {attempt}\n")
            f.write(f"时间: {datetime.now().isoformat()}\n")
            f.write(f"命名空间: {namespace}\n")
            f.write(f"目标语言: {target_lang_name}\n")
            f.write(f"模型: {model}\n")
            f.write(f"温度: {temperature}\n")
            f.write(f"文本数量: {len(texts)}\n")
            f.write("=" * 80 + "\n\n")

            f.write(f"错误信息:\n{error}\n")
            f.write("\n" + "=" * 80 + "\n\n")

            f.write("原始文本:\n")
            f.write(json.dumps(texts, ensure_ascii=False, indent=2))
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("系统提示词:\n")
            f.write(system_prompt)
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("用户提示词:\n")
            f.write(user_prompt)
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("API响应:\n")
            f.write(api_response)
            f.write("\n\n" + "=" * 80 + "\n")

        # 错误汇总日志
        summary_file = os.path.join(log_dir, "error_summary.log")
        with open(summary_file, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.now().isoformat()}] 尝试 {attempt} 失败: {error[:100]}{'...' if len(error) > 100 else ''}\n")
            f.write(f"  命名空间: {namespace}\n")
            f.write(f"  目标语言: {target_lang_name}\n")
            f.write(f"  文件: {os.path.basename(log_file)}\n")
            f.write(f"  文本数量: {len(texts)}\n")
            f.write(f"  模型: {model}\n")
            f.write(f"  温度: {temperature}\n\n")

        # 只在需要时记录主日志
        if log_to_main:
            error_summary = error[:50] + ('...' if len(error) > 50 else '')
            log_progress(f"    [尝试{attempt}/5] [{namespace}] {len(texts)}个文本 -> {target_lang_name} -> 失败: {error_summary}", "warning")
            flush_logs()  # 确保错误日志被及时写入

    def log_translation_attempt(self, attempt: int, system_prompt: str, user_prompt: str,
                                texts: Dict[str, str], namespace: str = "unknown",
                                target_lang_name: str = "unknown", model: str = "unknown",
                                temperature: float = 1.3) -> None:
        """在调试模式下记录每次请求的详细信息，格式与失败日志一致"""
        log_dir = os.path.join(os.path.dirname(__file__), "logs")
        os.makedirs(log_dir, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        log_file = os.path.join(log_dir, f"translation_attempt_{timestamp}_attempt_{attempt}.log")

        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(f"翻译请求日志 - 尝试次数: {attempt}\n")
            f.write(f"时间: {datetime.now().isoformat()}\n")
            f.write(f"命名空间: {namespace}\n")
            f.write(f"目标语言: {target_lang_name}\n")
            f.write(f"模型: {model}\n")
            f.write(f"温度: {temperature}\n")
            f.write(f"文本数量: {len(texts)}\n")
            f.write("=" * 80 + "\n\n")

            f.write("原始文本:\n")
            f.write(json.dumps(texts, ensure_ascii=False, indent=2))
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("系统提示词:\n")
            f.write(system_prompt)
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("用户提示词:\n")
            f.write(user_prompt)
            f.write("\n\n" + "=" * 80 + "\n\n")

            f.write("API响应:\n")
            f.write("(调试模式) 未请求或未记录响应\n")
            f.write("\n\n" + "=" * 80 + "\n")

    def prepare_texts_for_translation(self, texts: Dict[str, any]) -> Dict[str, str]:
        """准备合并后的文本进行翻译，处理列表值

        Args:
            texts: 可能包含列表值的文本字典

        Returns:
            Dict[str, str]: 准备好的翻译文本字典
        """
        prepared_texts = {}

        for key, value in texts.items():
            if isinstance(value, list):
                # 对于列表值，保留列表形式为AI提供更多上下文
                # AI会根据用户提示词中的指导只输出目标语言的字符串
                prepared_texts[key] = value
            else:
                prepared_texts[key] = str(value)

        return prepared_texts

    def translate_batch(self, texts: Dict[str, str], target_lang: str, target_lang_name: str, namespace: str = "unknown", attempt: int = 1, temperature: float = 1.3) -> Dict[str, str]:
        """
        翻译一批文本，单次执行（重试机制由上层函数处理）
        """
        if not texts:
            return {}

        # 精准过滤标记键：仅排除 '__core_keys__'，其他键正常参与翻译
        texts_to_translate = {k: v for k, v in texts.items() if k != '__core_keys__'}

        if not texts_to_translate:
            return {}

        source_text = json.dumps(texts_to_translate, ensure_ascii=False, indent=2)

        try:
                # 使用提示词模板或回退到默认提示词
                if self.system_prompt:
                    system_prompt = self._format_prompt(
                        self.system_prompt,
                        target_language=target_lang_name
                    )
                else:
                    system_prompt = "你是一个专业的游戏本地化翻译专家，擅长Minecraft相关内容的翻译。"

                if self.user_prompt:
                    user_prompt = self._format_prompt(
                        self.user_prompt,
                        target_language=target_lang_name,
                        content_to_translate=source_text
                    )
                else:
                    user_prompt = f"""请将以下JSON格式的游戏本地化文本翻译为{target_lang_name}。

要求：
1. 保持JSON格式不变，只翻译值部分
2. 保持游戏术语的一致性和准确性
3. 考虑游戏上下文，使翻译自然流畅
4. 保持原有的格式标记（如方括号、冒号等）
5. 对于专有名词（如"数据包"、"实体"等），使用游戏中的标准翻译
6. 如果遇到列表格式，则应当参考列表中的所有条目进行翻译。但确保仅输出包含{target_lang_name}语言的字符串而不是列表

源文本：
{source_text}

请直接返回翻译后的JSON，不要添加任何解释文字。"""

                # 调试模式：记录请求详情（与失败日志格式一致）
                if self.debug_mode:
                    self.log_translation_attempt(
                        attempt=attempt,
                        system_prompt=system_prompt,
                        user_prompt=user_prompt,
                        texts=texts_to_translate,
                        namespace=namespace,
                        target_lang_name=target_lang_name,
                        model=("deepseek-chat" if self.non_thinking_mode else "deepseek-reasoner"),
                        temperature=temperature
                    )

                # 根据模式选择模型
                model = "deepseek-chat" if self.non_thinking_mode else "deepseek-reasoner"

                payload = {
                    "model": model,
                    "messages": [
                        {
                            "role": "system",
                            "content": system_prompt
                        },
                        {
                            "role": "user",
                            "content": user_prompt
                        }
                    ],
                    "temperature": temperature,
                    "stream": False
                }

                # 调用API
                start_time = time.time()
                response = requests.post(DEEPSEEK_API_URL, headers=self.headers, json=payload, timeout=60)
                api_time = time.time() - start_time

                response.raise_for_status()

                # 处理响应文本，过滤空行
                response_text = response.text.strip()
                if not response_text:
                    raise ValueError("API返回空响应")

                # 过滤空行和只包含空白字符的行
                filtered_lines = []
                for line in response_text.split('\n'):
                    line = line.strip()
                    if line:  # 只保留非空行
                        filtered_lines.append(line)

                if not filtered_lines:
                    raise ValueError("API响应过滤后为空")

                # 重新组合过滤后的响应
                filtered_response = '\n'.join(filtered_lines)

                # 解析JSON
                try:
                    result = json.loads(filtered_response)
                except json.JSONDecodeError as e:
                    # 如果过滤后仍然解析失败，尝试原始响应
                    log_progress(f"      过滤后JSON解析失败，尝试原始响应: {e}", "warning")
                    result = response.json()

                translated_content = result["choices"][0]["message"]["content"].strip()

                # 清理响应内容
                original_content = translated_content
                if translated_content.startswith("```json"):
                    translated_content = translated_content[7:]
                if translated_content.startswith("```"):
                    translated_content = translated_content[3:]
                if translated_content.endswith("```"):
                    translated_content = translated_content[:-3]
                translated_content = translated_content.strip()

                # 解析JSON
                try:
                    translated_dict = json.loads(translated_content)
                except json.JSONDecodeError as e:
                    raise ValueError(f"JSON解析失败: {e}")

                # 验证翻译结果
                validation_errors = self.validate_translation_result(texts_to_translate, translated_dict)
                if validation_errors:
                    raise ValueError(f"翻译验证失败: {'; '.join(validation_errors)}")

                # 验证成功，返回结果
                return translated_dict

        except Exception as e:
            # 记录失败详情到文件（不记录主日志，由上层函数统一管理主日志）
            self.log_translation_failure(
                attempt=attempt,  # 使用传入的实际尝试次数
                system_prompt=system_prompt if 'system_prompt' in locals() else "未生成",
                user_prompt=user_prompt if 'user_prompt' in locals() else "未生成",
                api_response=translated_content if 'translated_content' in locals() else "无响应",
                error=str(e),
                texts=texts,
                namespace=namespace,
                target_lang_name=target_lang_name,
                model=model,
                temperature=temperature,
                log_to_main=False  # 不记录主日志，由execute_translation_request统一管理
            )
            # 抛出异常让上层处理重试
            raise e

    # 新的多线程架构：请求预处理 + 统一并发执行

    @dataclass
    class TranslationRequest:
        """翻译请求数据结构"""
        request_id: int
        texts: Dict[str, str]
        target_lang: str
        target_lang_name: str
        namespace: str = "unknown"
        batch_id: int = 1
        total_batches: int = 1
        batch_size: int = 40

    def prepare_translation_requests(self, all_texts: Dict[str, str], target_languages: List[Tuple[str, str]],
                                   batch_size: int = 40, silent: bool = False, namespace: str = None) -> List['DeepSeekTranslator.TranslationRequest']:
        """
        预处理所有翻译请求，将文本按语言和批次分割

        Args:
            all_texts: 所有需要翻译的文本
            target_languages: 目标语言列表 [(lang_code, lang_name), ...]
            batch_size: 每个请求的批次大小
            silent: 是否静默模式（不输出详细日志）
            namespace: 命名空间ID（用于日志显示）

        Returns:
            预处理好的翻译请求列表
        """
        requests = []
        request_id = 1

        for target_lang, target_lang_name in target_languages:
            total_texts = len(all_texts)

            # 如果需要分段（超过batch_size），使用强制上下文模式
            if total_texts > batch_size:
                # 分段翻译：强制添加上下文
                batches = self.split_texts_with_context_guarantee(all_texts, batch_size, context_size=4)
                total_batches = len(batches)

                for batch_index, batch_texts in enumerate(batches, 1):
                    request = self.TranslationRequest(
                        request_id=request_id,
                        texts=batch_texts,
                        target_lang=target_lang,
                        target_lang_name=target_lang_name,
                        namespace=namespace or "unknown",
                        batch_id=batch_index,
                        total_batches=total_batches,
                        batch_size=len(batch_texts)
                    )
                    requests.append(request)
                    request_id += 1
            else:
                # 不需要分段，直接创建单个请求
                request = self.TranslationRequest(
                    request_id=request_id,
                    texts=all_texts,
                    target_lang=target_lang,
                    target_lang_name=target_lang_name,
                    namespace=namespace or "unknown",
                    batch_id=1,
                    total_batches=1,
                    batch_size=len(all_texts)
                )
                requests.append(request)
                request_id += 1

        if not silent:
            total_requests = len(requests)
            total_texts_to_translate = sum(len(req.texts) for req in requests)
            namespace_display = f" {namespace}" if namespace else ""
            # 获取目标语言名称（使用第一个请求的语言名称作为代表）
            target_lang_display = requests[0].target_lang_name if requests else "未知语言"
            log_progress(f"为{namespace_display} 创建了 {total_requests} 个{target_lang_display}翻译请求，共 {total_texts_to_translate} 个文本")

        return requests

    def execute_translation_request(self, request: 'DeepSeekTranslator.TranslationRequest') -> Tuple[int, str, str, Dict[str, str]]:
        """
        执行单个翻译请求，支持重试机制
        区分API请求失败和模型输出验证失败，采用不同的重试策略

        Args:
            request: 翻译请求对象

        Returns:
            (request_id, target_lang, target_lang_name, translation_result)
        """
        max_individual_retries = 10  # 每种失败类型的最大重试次数
        api_failure_count = 0  # API请求失败计数
        validation_failure_count = 0  # 模型输出验证失败计数
        total_attempts = 0  # 总尝试次数（仅用于日志记录）

        # 温度调整策略
        def get_temperature_and_mode(validation_attempt: int):
            if validation_attempt <= 5:
                # 前5次：调整温度
                temperatures = [1.3, 1.3, 1.2, 1.0, 0.7]
                return temperatures[validation_attempt - 1], self.non_thinking_mode
            else:
                # 第6次开始：切换思考模式，重新开始温度循环
                cycle_pos = (validation_attempt - 6) % 5
                temperatures = [1.3, 1.3, 1.2, 1.0, 0.7]
                return temperatures[cycle_pos], not self.non_thinking_mode

        batch_info = f"批次{request.batch_id}/{request.total_batches} " if request.total_batches > 1 else ""

        while api_failure_count < max_individual_retries and validation_failure_count < max_individual_retries:
            total_attempts += 1

            try:
                # 根据验证失败次数调整参数
                if validation_failure_count > 0:
                    temperature, thinking_mode = get_temperature_and_mode(validation_failure_count)
                    # 临时切换模式和温度
                    original_mode = self.non_thinking_mode
                    self.non_thinking_mode = thinking_mode
                else:
                    temperature = 1.3
                    original_mode = self.non_thinking_mode

                # 执行翻译
                result = self.translate_batch(request.texts, request.target_lang, request.target_lang_name,
                                            request.namespace, total_attempts, temperature)

                # 恢复原始模式
                if validation_failure_count > 0:
                    self.non_thinking_mode = original_mode

                # 检查翻译结果是否为空
                if not result:
                    validation_failure_count += 1
                    if validation_failure_count < max_individual_retries:
                        log_progress(f"    [总尝试{total_attempts}|API失败{api_failure_count}/{max_individual_retries}|验证失败{validation_failure_count}/{max_individual_retries}] [{request.namespace}] {batch_info}-> {request.target_lang_name} -> 翻译结果为空，重试中... (等待1秒)", "warning")
                        time.sleep(1)  # 验证失败等待1秒
                        continue
                    else:
                        log_progress(f"    [总尝试{total_attempts}|API失败{api_failure_count}/{max_individual_retries}|验证失败{validation_failure_count}/{max_individual_retries}] [{request.namespace}] {batch_info}{len(request.texts)}个文本 -> {request.target_lang_name} -> 失败: 翻译结果为空 (达到验证失败上限)", "error")
                        return (request.request_id, request.target_lang, request.target_lang_name, {})

                # 成功
                attempt_info = f"（API失败{api_failure_count}次，验证失败{validation_failure_count}次）" if total_attempts > 1 else ""
                log_progress(f"    [总尝试{total_attempts}|API失败{api_failure_count}|验证失败{validation_failure_count}] [{request.namespace}] {batch_info}{len(request.texts)}个文本 -> {request.target_lang_name} -> 成功{attempt_info}")
                return (request.request_id, request.target_lang, request.target_lang_name, result)

            except Exception as e:
                error_str = str(e)

                # 判断错误类型
                if "翻译验证失败" in error_str:
                    # 模型输出验证失败
                    validation_failure_count += 1
                    failure_type = "验证失败"
                    wait_time = 1  # 验证失败等待1秒
                else:
                    # API请求失败（网络超时、连接错误等）
                    api_failure_count += 1
                    failure_type = "API失败"
                    wait_time = 5  # API失败等待5秒

                # 恢复原始模式
                if validation_failure_count > 0:
                    self.non_thinking_mode = original_mode

                if api_failure_count < max_individual_retries and validation_failure_count < max_individual_retries:
                    # 记录失败并提示重试
                    error_summary = error_str[:50] + ('...' if len(error_str) > 50 else '')
                    log_progress(f"    [总尝试{total_attempts}|API失败{api_failure_count}/{max_individual_retries}|验证失败{validation_failure_count}/{max_individual_retries}] [{request.namespace}] {batch_info}-> {request.target_lang_name} -> {failure_type}: {error_summary}，{wait_time}秒后重试...", "warning")
                    time.sleep(wait_time)
                    continue
                else:
                    # 最后一次失败，记录最终失败状态
                    error_summary = error_str[:50] + ('...' if len(error_str) > 50 else '')
                    log_progress(f"    [总尝试{total_attempts}|API失败{api_failure_count}/{max_individual_retries}|验证失败{validation_failure_count}/{max_individual_retries}] [{request.namespace}] {batch_info}{len(request.texts)}个文本 -> {request.target_lang_name} -> 最终失败: {error_summary} (达到重试上限)", "error")
                    return (request.request_id, request.target_lang, request.target_lang_name, {})

    def execute_requests_concurrently(self, requests: List['DeepSeekTranslator.TranslationRequest'],
                                    max_workers: int = None) -> Dict[str, Dict[str, str]]:
        """
        统一并发执行所有翻译请求

        Args:
            requests: 预处理好的翻译请求列表
            max_workers: 最大并发数，默认为请求数量

        Returns:
            按命名空间和语言双重分组的翻译结果 {namespace: {lang_code: {key: translation, ...}, ...}, ...}
        """
        if not requests:
            return {}

        if max_workers is None:
            max_workers = len(requests)  # 无并发限制，充分利用DeepSeek API

        log_progress(f"开始并发执行 {len(requests)} 个翻译请求")

        # 按命名空间和语言双重分组结果
        results_by_namespace_and_language = {}
        completed_requests = 0

        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            # 提交所有请求
            future_to_request = {
                executor.submit(self.execute_translation_request, request): request
                for request in requests
            }

            # 收集结果
            for future in concurrent.futures.as_completed(future_to_request):
                request = future_to_request[future]
                completed_requests += 1

                try:
                    request_id, target_lang, target_lang_name, result = future.result()

                    # 按命名空间和语言双重分组结果
                    namespace = getattr(request, 'namespace', 'default')
                    if namespace not in results_by_namespace_and_language:
                        results_by_namespace_and_language[namespace] = {}

                    if target_lang not in results_by_namespace_and_language[namespace]:
                        results_by_namespace_and_language[namespace][target_lang] = {}

                    results_by_namespace_and_language[namespace][target_lang].update(result)

                except Exception as e:
                    namespace = getattr(request, 'namespace', 'default')
                    log_progress(f"  [{namespace}] 执行异常: {str(e)}", "error")

        # 统计最终结果
        total_translations = sum(
            len(translations)
            for namespace_results in results_by_namespace_and_language.values()
            for translations in namespace_results.values()
        )
        log_progress(f"统一并发执行完成:")
        log_progress(f"  完成命名空间数: {len(results_by_namespace_and_language)}")
        log_progress(f"  总翻译数: {total_translations}")

        return results_by_namespace_and_language













    def split_texts_for_concurrent_translation(self, texts: Dict[str, str], batch_size: int = 40) -> List[Dict[str, str]]:
        """
        将文本字典分割为适合并发翻译的批次

        Args:
            texts: 要翻译的文本字典
            batch_size: 每个批次的大小

        Returns:
            分割后的批次列表
        """
        if not texts:
            return []

        items = list(texts.items())
        batches = []

        for i in range(0, len(items), batch_size):
            batch_items = items[i:i + batch_size]
            batch_dict = dict(batch_items)
            batches.append(batch_dict)

        log_progress(f"    将 {len(texts)} 个文本分割为 {len(batches)} 个批次 (每批次 {batch_size} 个)")
        return batches

    def split_texts_with_context_guarantee(self, texts: Dict[str, str], batch_size: int = 40, context_size: int = 4) -> List[Dict[str, str]]:
        """
        将文本字典分割为适合并发翻译的批次，并为每个批次添加上下文保证

        Args:
            texts: 要翻译的文本字典
            batch_size: 每个批次的大小
            context_size: 上下文大小（前后各添加的条数）

        Returns:
            分割后的批次列表，每个批次包含上下文
        """
        if not texts:
            return []

        items = list(texts.items())
        total_items = len(items)

        # 如果总数不超过批次大小，直接返回
        if total_items <= batch_size:
            return [dict(items)]

        batches = []

        for i in range(0, total_items, batch_size):
            batch_start = i
            batch_end = min(i + batch_size, total_items)

            # 获取当前批次的核心内容
            core_items = items[batch_start:batch_end]

            # 计算上下文范围
            context_items = []

            if i == 0:
                # 第一段：仅添加后方上下文
                context_start = batch_end
                context_end = min(batch_end + context_size, total_items)
                if context_start < total_items:
                    context_items = items[context_start:context_end]
                    log_progress(f"    批次 {len(batches)+1} (首段): 核心 {len(core_items)} 项 + 后方上下文 {len(context_items)} 项")
                else:
                    log_progress(f"    批次 {len(batches)+1} (首段): 核心 {len(core_items)} 项")
            elif batch_end >= total_items:
                # 最后一段：仅添加前方上下文
                context_start = max(0, batch_start - context_size)
                context_end = batch_start
                context_items = items[context_start:context_end]
                log_progress(f"    批次 {len(batches)+1} (末段): 前方上下文 {len(context_items)} 项 + 核心 {len(core_items)} 项")
            else:
                # 中间段落：前后各添加2条上下文
                half_context = context_size // 2
                # 前方上下文
                pre_context_start = max(0, batch_start - half_context)
                pre_context_end = batch_start
                pre_context = items[pre_context_start:pre_context_end]

                # 后方上下文
                post_context_start = batch_end
                post_context_end = min(batch_end + half_context, total_items)
                post_context = items[post_context_start:post_context_end]

                context_items = pre_context + post_context
                log_progress(f"    批次 {len(batches)+1} (中段): 前方上下文 {len(pre_context)} 项 + 核心 {len(core_items)} 项 + 后方上下文 {len(post_context)} 项")

            # 合并核心内容和上下文
            batch_items = core_items + context_items
            batch_dict = dict(batch_items)

            # 标记哪些是核心内容（需要保存），哪些是上下文（不保存）
            core_keys = set(key for key, _ in core_items)
            batch_dict['__core_keys__'] = list(core_keys)  # 转换为list以支持JSON序列化

            batches.append(batch_dict)

        log_progress(f"    将 {len(texts)} 个文本分割为 {len(batches)} 个批次 (每批次 {batch_size} 个 + 上下文)")
        return batches

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

        # 键名重命名检测：将“删除+新增且值相同”的情况归类为修改
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

def get_context_for_keys(source_dict: Dict[str, str], target_keys: List[str], max_context: int = 10, force_context: bool = False) -> Dict[str, any]:
    """为目标键获取上下文键值对，并统一使用核心键标记

    两步模型对齐：
    - 第一步（本函数）：在“源语言文件合并后”的字典上工作，若目标数不足上限则按从上到下的分块迭代补前后文；
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

    # 特殊判断：如果源文件合并后总键数 < max_context（如 < 10），直接纳入整个文件并添加标记
    if all_keys_count <= max_context:
        result: Dict[str, any] = dict(source_dict)
        result['__core_keys__'] = list(target_keys)
        return result

    # 若目标键已达/超上限，非强制模式直接返回目标键，并添加统一标记
    if len(target_keys) >= max_context:
        result: Dict[str, any] = {k: source_dict[k] for k in target_keys if k in source_dict}
        result['__core_keys__'] = list(target_keys)
        return result

    # 以下为“分块迭代前后扩展”补上下文（仅在非强制且目标不足上限时）
    index_map = {k: i for i, k in enumerate(source_keys)}
    valid_target_indices = [index_map[k] for k in target_keys if k in index_map]
    selected_indices: Set[int] = set(valid_target_indices)

    # 组块：按连续索引将目标键聚为段落
    segments: List[Tuple[int, int]] = []
    if valid_target_indices:
        valid_target_indices.sort()
        s = valid_target_indices[0]
        e = s
        for idx in valid_target_indices[1:]:
            if idx == e + 1:
                e = idx
            else:
                segments.append((s, e))
                s, e = idx, idx
        segments.append((s, e))

    left_ptrs = [s - 1 for (s, _e) in segments]
    right_ptrs = [e + 1 for (_s, e) in segments]

    def add_one_before_each_segment() -> bool:
        did_add = False
        for idx, (_s, _e) in enumerate(segments):
            if len(selected_indices) >= max_context:
                break
            lp = left_ptrs[idx]
            while lp >= 0 and lp in selected_indices:
                lp -= 1
            if lp >= 0 and len(selected_indices) < max_context:
                selected_indices.add(lp)
                left_ptrs[idx] = lp - 1
                did_add = True
        return did_add

    def add_one_after_each_segment() -> bool:
        did_add = False
        for idx, (_s, _e) in enumerate(segments):
            if len(selected_indices) >= max_context:
                break
            rp = right_ptrs[idx]
            while rp < len(source_keys) and rp in selected_indices:
                rp += 1
            if rp < len(source_keys) and len(selected_indices) < max_context:
                selected_indices.add(rp)
                right_ptrs[idx] = rp + 1
                did_add = True
        return did_add

    while len(selected_indices) < max_context and segments:
        added_before = add_one_before_each_segment()
        if len(selected_indices) >= max_context:
            break
        added_after = add_one_after_each_segment()
        if not added_before and not added_after:
            break

    # 产出结果并追加统一标记
    result: Dict[str, any] = {}
    count = 0
    for i in sorted(selected_indices):
        key = source_keys[i]
        result[key] = source_dict[key]
        count += 1
        if count >= max_context:
            break

    result['__core_keys__'] = list(target_keys)
    return result

def check_missing_translation_files() -> Dict[str, List[str]]:
    """检查缺失的翻译文件

    Returns:
        Dict[namespace, List[missing_lang_codes]]: 缺失翻译文件的命名空间和语言代码
    """
    missing_files = {}

    # 获取所有命名空间
    namespaces = get_namespace_list()
    if not namespaces:
        return missing_files

    log_progress("检查翻译文件完整性...")

    for namespace in namespaces:
        # 检查是否存在任何语言文件
        namespace_lang_dir = Path(ASSETS_DIR) / namespace / "lang"
        if not namespace_lang_dir.exists():
            continue

        # 检查是否有任何语言文件存在
        has_lang_files = any(f.suffix == '.json' for f in namespace_lang_dir.glob('*.json'))
        if not has_lang_files:
            continue

        missing_langs = []

        # 检查每种目标语言的翻译文件
        for lang_code, lang_name in get_all_target_languages().items():
            translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
            if not translate_file.exists():
                missing_langs.append(lang_code)

        if missing_langs:
            missing_files[namespace] = missing_langs
            log_progress(f"  {namespace}: 缺失 {len(missing_langs)} 个语言的翻译文件")

    if missing_files:
        total_missing = sum(len(langs) for langs in missing_files.values())
        log_progress(f"发现 {len(missing_files)} 个命名空间缺失翻译文件，共 {total_missing} 个文件")
    else:
        log_progress("所有翻译文件完整")

    return missing_files



def check_missing_translation_files() -> List[Tuple[str, str]]:
    """检查缺失的翻译文件

    Returns:
        List[Tuple[str, str]]: 缺失文件的 (namespace, lang_code) 列表
    """
    missing_files = []

    # 获取所有命名空间
    namespaces = get_namespace_list()

    for namespace in namespaces:
        # 检查是否存在任何语言文件
        namespace_lang_dir = Path(ASSETS_DIR) / namespace / "lang"
        if not namespace_lang_dir.exists():
            continue

        # 检查是否有任何语言文件存在
        has_lang_files = any(f.suffix == '.json' for f in namespace_lang_dir.glob('*.json'))
        if not has_lang_files:
            continue

        # 检查每种目标语言的翻译文件
        for lang_code, _ in get_all_target_languages().items():
            translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
            if not translate_file.exists():
                missing_files.append((namespace, lang_code))

    if missing_files:
        log_progress(f"发现 {len(missing_files)} 个缺失的翻译文件")
        for namespace, lang_code in missing_files[:5]:  # 只显示前5个
            log_progress(f"  缺失: {namespace}/{lang_code}.json")
        if len(missing_files) > 5:
            log_progress(f"  ... 还有 {len(missing_files) - 5} 个文件")

    return missing_files

def create_virtual_changes_for_missing_files(missing_files: List[Tuple[str, str]]) -> List[FileChanges]:
    """为缺失的翻译文件创建虚拟变更

    Args:
        missing_files: 缺失文件的 (namespace, lang_code) 列表

    Returns:
        List[FileChanges]: 虚拟变更列表
    """
    # 按命名空间分组
    namespace_groups = {}
    for namespace, lang_code in missing_files:
        if namespace not in namespace_groups:
            namespace_groups[namespace] = []
        namespace_groups[namespace].append(lang_code)

    virtual_changes = []

    for namespace, lang_codes in namespace_groups.items():
        # 使用合并后的参考翻译以获取所有键
        source_dict = get_merged_reference_translations(namespace)
        if not source_dict:
            continue

        # 为每个缺失的语言文件创建虚拟变更
        for lang_code in lang_codes:
            # 创建虚拟变更，将所有合并后的键标记为新增
            added_keys = []
            for key, value in source_dict.items():
                # 处理列表值的情况
                if isinstance(value, list):
                    # 对于列表值，使用第一个值作为翻译源
                    added_keys.append(KeyChange(key=key, old_value=None, new_value=value[0], operation='added'))
                else:
                    added_keys.append(KeyChange(key=key, old_value=None, new_value=value, operation='added'))

            # 构建缺失文件的路径
            missing_file_path = f"{namespace}/{lang_code}.json"

            virtual_changes.append(FileChanges(
                namespace=namespace,
                file_path=missing_file_path,
                added_keys=added_keys,
                deleted_keys=[],
                modified_keys=[]
            ))

        log_progress(f"为命名空间 {namespace} 创建虚拟变更，包含 {len(added_keys)} 个键")

    return virtual_changes

def create_virtual_changes_for_missing_keys() -> List[FileChanges]:
    """为已有翻译文件中的缺失键创建虚拟变更，只扫描缺失键，忽略输出目录的修改"""
    virtual_changes: List[FileChanges] = []

    # 遍历所有命名空间
    for namespace in get_namespace_list():
        # 使用合并后的参考翻译获取完整键集合
        source_dict = get_merged_reference_translations(namespace)
        if not source_dict:
            continue

        source_keys = list(source_dict.keys())

        # 遍历所有目标语言
        for lang_code, _ in get_all_target_languages().items():
            translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
            if not translate_file.exists():
                # 文件缺失的场景由 create_virtual_changes_for_missing_files 处理
                continue

            # 仅基于 translate 目录检查缺失，assets 将在构建时合并
            existing_translations = load_namespace_translations_from_translate(namespace, lang_code)
            existing_keys = set(existing_translations.keys())

            # 仅扫描缺失键（忽略输出目录的修改）
            missing_keys = [k for k in source_keys if k not in existing_keys]
            if not missing_keys:
                continue

            added_keys: List[KeyChange] = []
            for key in missing_keys:
                value = source_dict.get(key)
                if isinstance(value, list):
                    value = value[0] if value else ""
                added_keys.append(KeyChange(key=key, old_value=None, new_value=value, operation=ChangeType.ADDED.value))

            virtual_changes.append(FileChanges(
                namespace=namespace,
                file_path=f"{namespace}/{lang_code}.json",
                added_keys=added_keys,
                deleted_keys=[],
                modified_keys=[]
            ))

            log_progress(f"为命名空间 {namespace} -> {lang_code} 创建缺失键补全任务：{len(added_keys)} 个键")

    return virtual_changes

def delete_keys_from_translations(namespace: str, keys_to_delete: List[str]) -> bool:
    """从所有翻译文件中删除指定的键"""
    success = True

    # 处理所有目标语言的翻译文件
    for lang_code, _ in get_all_target_languages().items():
        translate_file = Path(TRANSLATE_DIR) / namespace / "lang" / f"{lang_code}.json"
        if not translate_file.exists():
            continue

        # 加载现有翻译
        translations = load_json_file(str(translate_file))
        if not translations:
            continue

        # 删除指定的键
        modified = False
        for key in keys_to_delete:
            if key in translations:
                del translations[key]
                modified = True

        # 如果有修改，保存文件
        if modified:
            if save_json_file(str(translate_file), translations):
                log_progress(f"    ✓ 从 {lang_code} 翻译中删除了 {len([k for k in keys_to_delete if k in translations])} 个键")
            else:
                log_progress(f"    ✗ 删除键失败: {translate_file}", "error")
                success = False

    return success

def needs_translation(namespace: str, lang_code: str, source_dict: Dict[str, str]) -> bool:
    """判断是否需要翻译"""
    force_translate = os.getenv('FORCE_TRANSLATE', 'false').lower() == 'true'

    if force_translate:
        return True

    # 检查已有翻译是否完整（仅检查translate目录）
    existing_translations = load_namespace_translations_from_translate(namespace, lang_code)

    # 如果没有任何翻译，需要翻译
    if not existing_translations:
        return True

    # 检查是否有新的键需要翻译
    missing_keys = set(source_dict.keys()) - set(existing_translations.keys())
    if missing_keys:
        log_progress(f"{lang_code}: 发现 {len(missing_keys)} 个新键需要翻译")
        return True

    return False

def main():
    """主函数"""
    log_section("翻译脚本启动")

    # 检查环境变量
    api_key = os.getenv('DEEPSEEK_API_KEY')
    if not api_key:
        log_progress("错误：未找到DEEPSEEK_API_KEY环境变量", "error")
        sys.exit(1)

    log_progress("✓ API密钥已配置")

    # 检查是否使用非思考模式
    non_thinking_mode = os.getenv('NON_THINKING_MODE', 'false').lower() == 'true'
    if non_thinking_mode:
        log_progress("⚡ 非思考模式：使用deepseek-chat模型以提升速度")
    else:
        log_progress("🧠 思考模式：使用deepseek-reasoner模型以提升质量")

    # 创建翻译器
    translator = DeepSeekTranslator(api_key, non_thinking_mode)
    log_progress("✓ 翻译器初始化完成")

    # 检查翻译模式
    force_translate = os.getenv('FORCE_TRANSLATE', 'false').lower() == 'true'

    if force_translate:
        log_progress("🔄 强制翻译模式：将重新翻译所有内容（使用合并翻译逻辑）")
        # 使用全量翻译逻辑（已集成合并翻译）
        run_full_translation(translator)
    else:
        log_progress("🔍 智能翻译模式：检测Git变更（使用合并翻译逻辑）")
        # 使用智能差异翻译逻辑（已集成合并翻译）
        run_smart_translation(translator)

def run_full_translation(translator):
    """运行全量翻译（原有逻辑）"""
    # 获取所有命名空间
    log_progress("扫描命名空间...")
    namespaces = get_namespace_list()
    if not namespaces:
        log_progress("错误：未找到任何命名空间", "error")
        sys.exit(1)

    log_progress(f"✓ 找到 {len(namespaces)} 个命名空间: {', '.join(namespaces)}")
    # 计算需要翻译的语言数
    target_lang_count = len(get_all_target_languages())
    log_progress(f"✓ 目标语言: {target_lang_count} 种")

    # 创建进度跟踪器
    progress_tracker = ProgressTracker(target_lang_count, len(namespaces))

    log_section_end()

    # 调用原有的翻译逻辑
    continue_full_translation(translator, progress_tracker, namespaces)

def run_smart_translation(translator):
    """运行智能差异翻译（一次性并发；基于Git差异收集键名）"""
    # 使用 Git 收集每个源目录语言文件的键级差异，随后在合并源文本上处理
    file_changes = get_git_changes()

    # 检查输出文件缺失情况
    missing_translations = check_missing_translation_files()

    if missing_translations:
        virtual_changes = create_virtual_changes_for_missing_files(missing_translations)
        file_changes.extend(virtual_changes)
        log_progress(f"为 {len(missing_translations)} 个缺失文件创建补全翻译任务")

    # 已有翻译文件的缺失键补全任务
    missing_key_changes = create_virtual_changes_for_missing_keys()
    if missing_key_changes:
        file_changes.extend(missing_key_changes)
        log_progress(f"为已有翻译文件创建缺失键补全任务：{len(missing_key_changes)} 个变更")

    if not file_changes:
        log_progress("未检测到差异或缺失，跳过翻译")
        perform_cleanup_extra_keys()
        return

    log_progress(f"检测到 {len(file_changes)} 个变更任务")

    # 注意：删除键在后续清理过程中处理，这里忽略删除键

    # 收集所有翻译任务（一次性并发）
    all_translation_tasks = []
    for changes in file_changes:
        # 使用合并后的参考翻译
        source_dict = get_merged_reference_translations(changes.namespace)
        if not source_dict:
            log_progress(f"无法加载命名空间 {changes.namespace} 的合并参考翻译", "error")
            continue

        # 目标键集合：新增 + 修改（去重保持顺序）
        keys_to_translate = list(dict.fromkeys([c.key for c in (changes.added_keys + changes.modified_keys)]))
        if not keys_to_translate:
            continue

        # 上下文策略：若少于10条则补齐上下文到10条；否则仅目标键
        if len(keys_to_translate) < 10:
            context_dict = get_context_for_keys(source_dict, keys_to_translate, max_context=10, force_context=False)
            log_progress(f"差异翻译上下文补充：{len(keys_to_translate)} 个目标键 + {len(context_dict) - len(keys_to_translate)} 个上下文键 = {len(context_dict)} 个键值对")
        else:
            context_dict = {k: source_dict[k] for k in keys_to_translate if k in source_dict}
            log_progress(f"差异翻译：{len(context_dict)} 个键值对（无需添加上下文）")

        # 目标语言列表：默认所有语言；若为缺失文件的虚拟变更，则限制到该语言
        target_languages = get_all_target_languages().copy()
        if "/" in changes.file_path and changes.file_path.endswith('.json'):
            file_name = Path(changes.file_path).name
            target_lang_code = file_name[:-5]
            if target_lang_code in target_languages:
                target_languages = {target_lang_code: target_languages[target_lang_code]}
                log_progress(f"  虚拟变更：只翻译缺失的语言 {target_languages[target_lang_code]} ({target_lang_code})")
            else:
                target_languages = {}
                log_progress(f"  未知的语言代码: {target_lang_code}，跳过翻译")

        for lang_code, lang_name in target_languages.items():
            existing_translations = load_namespace_translations_from_translate(changes.namespace, lang_code)
            all_translation_tasks.append({
                'namespace': changes.namespace,
                'lang_code': lang_code,
                'lang_name': lang_name,
                'context_dict': context_dict,
                'keys_to_translate': keys_to_translate,
                'existing_translations': existing_translations
            })

    if not all_translation_tasks:
        log_progress("没有需要执行的翻译任务")
        perform_cleanup_extra_keys()
        return

    log_progress(f"准备 {len(all_translation_tasks)} 个翻译任务（全局并发）")

    # 统一准备与并发请求
    all_requests = []
    for task in all_translation_tasks:
        prepared_context = translator.prepare_texts_for_translation(task['context_dict'])
        target_languages_list = [(task['lang_code'], task['lang_name'])]
        requests = translator.prepare_translation_requests(prepared_context, target_languages_list, batch_size=40, silent=True)
        for request in requests:
            request.namespace = task['namespace']
            request.keys_to_translate = task['keys_to_translate']
            request.existing_translations = task['existing_translations']
            all_requests.append(request)

    log_progress(f"开始并发翻译 {len(all_requests)} 个请求...")
    results_by_namespace_and_language = translator.execute_requests_concurrently(all_requests)

    # 保存结果
    saved_count = 0
    for task in all_translation_tasks:
        ns = task['namespace']
        lang = task['lang_code']
        keys = task['keys_to_translate']
        existing = task['existing_translations']
        if ns in results_by_namespace_and_language and lang in results_by_namespace_and_language[ns]:
            translated = results_by_namespace_and_language[ns][lang]
            target_translations = {k: translated[k] for k in keys if k in translated}
            final = existing.copy()
            final.update(target_translations)
            if save_namespace_translations(ns, lang, final):
                saved_count += 1
                log_progress(f"✓ {ns} -> {lang}: {len(target_translations)} 个新翻译")
            else:
                log_progress(f"✗ 保存失败: {ns} -> {lang}", "error")

    log_progress(f"✓ 成功保存 {saved_count}/{len(all_translation_tasks)} 个翻译文件")

    log_section("智能翻译完成")
    log_progress("🎉 所有变更已处理完成！")
    perform_cleanup_extra_keys()
    log_section_end()

def perform_cleanup_extra_keys():
    """清理所有命名空间与语言中的多余键，并保存更新"""
    # 清理多余的键值对
    log_progress("开始清理多余的键值对...")
    cleaned_count = 0
    total_keys_removed = 0

    # 获取所有命名空间
    all_namespaces = get_namespace_list()
    log_progress(f"处理的命名空间: {', '.join(all_namespaces)}")

    for namespace in all_namespaces:
        # 获取源字典（参考翻译）
        source_dict = get_merged_reference_translations(namespace)
        if not source_dict:
            log_progress(f"⚠️ 命名空间 {namespace} 没有源字典", "warning")
            continue

        log_progress(f"命名空间 {namespace} 源字典包含 {len(source_dict)} 个键")

        # 获取所有目标语言
        for lang_code, lang_name in get_all_target_languages().items():
            # 加载现有翻译（仅检查 translate 目录；assets 在构建时合并，不参与完整性检查）
            existing_translations = load_namespace_translations_from_translate(namespace, lang_code)
            if not existing_translations:
                log_progress(f"⚠️ 未在 translate 目录找到翻译文件: {namespace} -> {lang_code}", "warning")
                continue

            log_progress(f"检查 {namespace} -> {lang_code}: 包含 {len(existing_translations)} 个键")

            # 找出多余的键（在翻译中存在但在源字典中不存在的键）
            source_keys = set(source_dict.keys())
            keys_to_remove = [key for key in existing_translations if key not in source_keys]

            if keys_to_remove:
                log_progress(f"发现 {len(keys_to_remove)} 个多余键: {', '.join(keys_to_remove[:5])}{' 等' if len(keys_to_remove) > 5 else ''}")

                # 移除多余的键
                for key in keys_to_remove:
                    del existing_translations[key]

                # 保存更新后的翻译（保存到 translate 目录）
                try:
                    if save_namespace_translations(namespace, lang_code, existing_translations):
                        cleaned_count += 1
                        total_keys_removed += len(keys_to_remove)
                        log_progress(f"✓ 清理 {namespace} -> {lang_code}: 移除了 {len(keys_to_remove)} 个多余键", "info")
                    else:
                        log_progress(f"✗ 清理失败: {namespace} -> {lang_code}", "error")
                except Exception as e:
                    log_progress(f"✗ 清理时发生错误: {namespace} -> {lang_code}, 错误: {str(e)}", "error")
            else:
                log_progress(f"✓ {namespace} -> {lang_code}: 没有多余键", "info")

    log_progress(f"清理完成，共清理了 {cleaned_count} 个文件，移除了 {total_keys_removed} 个多余键")

def continue_full_translation(translator, progress_tracker, namespaces):
    """继续执行全量翻译的剩余逻辑 - 全并发版本"""
    log_progress("开始准备所有翻译请求...")

    # 第一阶段：收集所有需要翻译的内容
    all_translation_tasks = []
    force_translate = os.getenv('FORCE_TRANSLATE', 'false').lower() == 'true'

    for namespace in namespaces:
        # 使用合并后的参考翻译
        source_dict = get_merged_reference_translations(namespace)
        if not source_dict:
            log_progress(f"跳过命名空间 {namespace}：无法加载合并参考翻译", "warning")
            continue

        log_progress(f"✓ 命名空间 {namespace}：{len(source_dict)} 个键值对")

        for lang_code, lang_name in get_all_target_languages().items():
            # 检查是否需要翻译
            if not needs_translation(namespace, lang_code, source_dict):
                continue

            # 加载已有翻译（仅从translate目录）
            existing_translate = load_namespace_translations_from_translate(namespace, lang_code)

            # 确定需要翻译的内容
            if force_translate:
                keys_to_translate = source_dict.copy()
            else:
                keys_to_translate = {k: v for k, v in source_dict.items() if k not in existing_translate}

            if keys_to_translate:
                all_translation_tasks.append({
                    'namespace': namespace,
                    'lang_code': lang_code,
                    'lang_name': lang_name,
                    'texts': keys_to_translate,
                    'existing_translations': existing_translate
                })

    if not all_translation_tasks:
        log_progress("所有内容已翻译完成")
        return

    log_progress(f"✓ 准备完成：{len(all_translation_tasks)} 个翻译任务")

    # 第二阶段：准备所有翻译请求
    log_progress("准备翻译请求...")
    all_requests = []

    for task in all_translation_tasks:
        prepared_texts = translator.prepare_texts_for_translation(task['texts'])
        target_languages = [(task['lang_code'], task['lang_name'])]

        # 创建翻译请求
        requests = translator.prepare_translation_requests(prepared_texts, target_languages, batch_size=40, namespace=task['namespace'])

        # 为每个请求添加任务信息
        for request in requests:
            request.namespace = task['namespace']
            request.existing_translations = task['existing_translations']
            all_requests.append(request)

    log_progress(f"✓ 生成了 {len(all_requests)} 个翻译请求")

    # 第三阶段：一次性并发执行所有请求
    log_progress("开始全并发翻译...")
    results_by_namespace_and_language = translator.execute_requests_concurrently(all_requests)

    # 第四阶段：保存翻译结果
    log_progress("保存翻译结果...")
    saved_count = 0

    for task in all_translation_tasks:
        namespace = task['namespace']
        lang_code = task['lang_code']
        existing_translations = task['existing_translations']

        # 获取该任务的翻译结果
        if (namespace in results_by_namespace_and_language and
            lang_code in results_by_namespace_and_language[namespace]):
            translated_results = results_by_namespace_and_language[namespace][lang_code]

            # 计算真正的新翻译数量
            if force_translate:
                # 强制翻译模式：所有翻译结果都是新的（覆盖现有翻译）
                final_translations = translated_results
                new_translations_count = len(translated_results)
            else:
                # 增量翻译模式：translated_results中的所有键都是新的
                # （因为keys_to_translate已经过滤掉了existing_translations中存在的键）
                new_translations_count = len(translated_results)
                final_translations = existing_translations.copy()
                final_translations.update(translated_results)

            # 保存翻译结果
            if save_namespace_translations(namespace, lang_code, final_translations):
                saved_count += 1
                log_progress(f"✓ {namespace} -> {lang_code}: {new_translations_count} 个新翻译")
            else:
                log_progress(f"✗ 保存失败: {namespace} -> {lang_code}", "error")
        else:
            log_progress(f"✗ 未找到翻译结果: {namespace} -> {lang_code}", "warning")

    log_progress(f"🎉 全并发翻译完成！成功保存 {saved_count}/{len(all_translation_tasks)} 个翻译文件")

    # 翻译完成后统一执行清理
    perform_cleanup_extra_keys()
    flush_logs()

if __name__ == "__main__":
    try:
        main()
    finally:
        # 确保日志文件被正确关闭
        flush_logs()
        close_logs()
