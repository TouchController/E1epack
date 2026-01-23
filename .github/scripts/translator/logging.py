#!/usr/bin/env python3
"""
日志模块 - 包含进度跟踪和日志函数
"""

import sys
import time
import logging
from datetime import datetime
from typing import Optional

from translator.config import IS_GITHUB_ACTIONS

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