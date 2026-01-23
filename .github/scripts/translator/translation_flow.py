#!/usr/bin/env python3
"""
翻译流程模块 - 包含主函数和翻译流程控制逻辑
"""

import os
import sys
from typing import Dict, List, Tuple
from pathlib import Path

from .config import get_all_target_languages
from .logging import log_progress, log_section, log_section_end, ProgressTracker, flush_logs
from .translator import DeepSeekTranslator
from .git_changes import get_git_changes
from .file_ops import (
    get_namespace_list,
    load_namespace_translations_from_translate,
    save_namespace_translations,
    get_merged_reference_translations,
    get_context_for_keys,
    load_json_file,
    save_json_file
)
from .config import KeyChange, FileChanges, ChangeType


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
        namespace_lang_dir = Path("subprojects/Localization-Resource-Pack/assets") / namespace / "lang"
        if not namespace_lang_dir.exists():
            continue

        # 检查是否有任何语言文件存在
        has_lang_files = any(f.suffix == '.json' for f in namespace_lang_dir.glob('*.json'))
        if not has_lang_files:
            continue

        # 检查每种目标语言的翻译文件
        for lang_code, _ in get_all_target_languages().items():
            translate_file = Path("translate") / namespace / "lang" / f"{lang_code}.json"
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
            translate_file = Path("translate") / namespace / "lang" / f"{lang_code}.json"
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
        translate_file = Path("translate") / namespace / "lang" / f"{lang_code}.json"
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