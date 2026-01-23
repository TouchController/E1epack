#!/usr/bin/env python3
"""
DeepSeek翻译器模块 - 包含DeepSeekTranslator类和翻译核心逻辑
"""

import os
import json
import re
import time
import requests
from datetime import datetime
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
import concurrent.futures

from translator.config import DEEPSEEK_API_URL, SYSTEM_PROMPT_FILE, USER_PROMPT_FILE, BATCH_SIZE, MAX_CONTEXT, MAX_INDIVIDUAL_RETRIES, CONTEXT_SIZE, DEFAULT_TEMPERATURE, TEMPERATURE_ADJUSTMENTS, API_TIMEOUT
from translator.logging import log_progress, flush_logs


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

    def translate_batch(self, texts: Dict[str, str], target_lang: str, target_lang_name: str, namespace: str = "unknown", attempt: int = 1, temperature: float = DEFAULT_TEMPERATURE) -> Dict[str, str]:
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
                response = requests.post(DEEPSEEK_API_URL, headers=self.headers, json=payload, timeout=API_TIMEOUT)
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
        batch_size: int = BATCH_SIZE

    def prepare_translation_requests(self, all_texts: Dict[str, str], target_languages: List[Tuple[str, str]],
                                   batch_size: int = BATCH_SIZE, silent: bool = False, namespace: str = None) -> List['DeepSeekTranslator.TranslationRequest']:
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
                batches = self.split_texts_with_context_guarantee(all_texts, batch_size, context_size=CONTEXT_SIZE)
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
        max_individual_retries = MAX_INDIVIDUAL_RETRIES  # 每种失败类型的最大重试次数
        api_failure_count = 0  # API请求失败计数
        validation_failure_count = 0  # 模型输出验证失败计数
        total_attempts = 0  # 总尝试次数（仅用于日志记录）

        # 温度调整策略
        def get_temperature_and_mode(validation_attempt: int):
            if validation_attempt <= 5:
                # 前5次：调整温度
                temperatures = TEMPERATURE_ADJUSTMENTS
                return temperatures[validation_attempt - 1], self.non_thinking_mode
            else:
                # 第6次开始：切换思考模式，重新开始温度循环
                cycle_pos = (validation_attempt - 6) % 5
                temperatures = TEMPERATURE_ADJUSTMENTS
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

    def split_texts_for_concurrent_translation(self, texts: Dict[str, str], batch_size: int = BATCH_SIZE) -> List[Dict[str, str]]:
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

    def split_texts_with_context_guarantee(self, texts: Dict[str, str], batch_size: int = BATCH_SIZE, context_size: int = CONTEXT_SIZE) -> List[Dict[str, str]]:
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