"""
日志分析工具库 - 整合 Kimi K2.5 + GLM-5 最佳实践

使用场景：
- 小型日志（< 1GB）：用流式生成器
- 多文件并行：用多进程池
- 超大规模（> 10GB）：用 Polars/DuckDB
- 正则搜索大文件：用内存映射
- 定时任务：用断点续传
"""

import re
import json
import mmap
import glob
import gzip
import logging
from pathlib import Path
from datetime import datetime
from collections import Counter, defaultdict
from typing import Iterator, Callable, Optional, List, Dict, Union
from concurrent.futures import ProcessPoolExecutor, as_completed
from multiprocessing import cpu_count

# 可选依赖，未安装时优雅降级
try:
    import polars as pl
    HAS_POLARS = True
except ImportError:
    HAS_POLARS = False

try:
    import duckdb
    HAS_DUCKDB = True
except ImportError:
    HAS_DUCKDB = False

try:
    import pandas as pd
    HAS_PANDAS = True
except ImportError:
    HAS_PANDAS = False


# =============================================================================
# 基础工具函数
# =============================================================================

def stream_lines(filepath: str) -> Iterator[str]:
    """
    流式读取文件行，O(1)内存占用
    支持 .gz 压缩文件自动解压
    """
    opener = gzip.open if filepath.endswith('.gz') else open
    with opener(filepath, 'rt', encoding='utf-8', errors='ignore') as f:
        for line in f:
            yield line.strip()


def stream_multiple(file_pattern: str) -> Iterator[str]:
    """多文件流式生成器"""
    for filepath in glob.glob(file_pattern):
        yield from stream_lines(filepath)


# =============================================================================
# 方案一：流式处理（内存安全，推荐）
# =============================================================================

class LogAnalyzer:
    """流式日志分析器 - 适合大文件/内存受限环境"""
    
    def __init__(self, level_pattern: Optional[str] = None):
        self.level_regex = re.compile(level_pattern) if level_pattern else None
        self.stats = defaultdict(int)
    
    def analyze_file(self, filepath: str) -> Dict:
        """单文件分析"""
        result = {
            'filepath': filepath,
            'total_lines': 0,
            'error_count': 0,
            'warn_count': 0,
            'pattern_matches': Counter(),
            'hourly_distribution': defaultdict(int)
        }
        
        for line in stream_lines(filepath):
            result['total_lines'] += 1
            
            # 快速字符串检测（比正则快5-10倍）
            if '[ERROR]' in line:
                result['error_count'] += 1
            elif '[WARN]' in line:
                result['warn_count'] += 1
            
            # 正则匹配（预编译）
            if self.level_regex:
                match = self.level_regex.search(line)
                if match:
                    result['pattern_matches'][match.group(1) if match.groups() else match.group(0)] += 1
            
            # 时间解析（简单提取）
            if line[:4].isdigit() and '-' in line[:10]:
                try:
                    hour = line[11:13] if len(line) > 13 else '00'
                    result['hourly_distribution'][hour] += 1
                except:
                    pass
        
        return result
    
    def analyze_pattern(self, file_pattern: str) -> Dict:
        """批量分析匹配模式的所有文件"""
        files = glob.glob(file_pattern)
        total_stats = {
            'files_processed': 0,
            'total_lines': 0,
            'total_errors': 0,
            'total_warns': 0,
            'pattern_matches': Counter()
        }
        
        for filepath in files:
            result = self.analyze_file(filepath)
            total_stats['files_processed'] += 1
            total_stats['total_lines'] += result['total_lines']
            total_stats['total_errors'] += result['error_count']
            total_stats['total_warns'] += result['warn_count']
            total_stats['pattern_matches'].update(result['pattern_matches'])
        
        return total_stats


# =============================================================================
# 方案二：多进程并行（多文件场景）
# =============================================================================

def _process_single_file(args: tuple) -> Dict:
    """
    子进程执行函数（必须在模块顶层才能被 pickle）
    """
    filepath, pattern = args
    analyzer = LogAnalyzer(level_pattern=pattern)
    try:
        return analyzer.analyze_file(filepath)
    except Exception as e:
        return {'filepath': filepath, 'error': str(e)}


def parallel_analyze(file_pattern: str, 
                     level_pattern: Optional[str] = None,
                     max_workers: Optional[int] = None) -> Dict:
    """
    多进程并行分析多个日志文件
    
    Args:
        file_pattern: 文件匹配模式，如 "/var/log/*.log"
        level_pattern: 可选的正则表达式
        max_workers: 进程数，默认 CPU 核心数
    """
    files = glob.glob(file_pattern)
    if not files:
        return {'error': f'No files match pattern: {file_pattern}'}
    
    max_workers = max_workers or cpu_count()
    total_stats = {
        'files_processed': 0,
        'total_lines': 0,
        'total_errors': 0,
        'failed_files': []
    }
    
    # 准备参数
    args_list = [(f, level_pattern) for f in files]
    
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(_process_single_file, args): args[0] 
                   for args in args_list}
        
        for future in as_completed(futures):
            filepath = futures[future]
            try:
                result = future.result()
                if 'error' in result:
                    total_stats['failed_files'].append(result)
                else:
                    total_stats['files_processed'] += 1
                    total_stats['total_lines'] += result.get('total_lines', 0)
                    total_stats['total_errors'] += result.get('error_count', 0)
            except Exception as e:
                total_stats['failed_files'].append({'filepath': filepath, 'error': str(e)})
    
    return total_stats


# =============================================================================
# 方案三：内存映射 + 正则（大文件快速搜索）
# =============================================================================

def mmap_search(filepath: str, pattern: str) -> List[str]:
    """
    使用内存映射进行快速正则搜索
    适合：大文件中的复杂模式匹配，比逐行读取快 3-5x
    
    Args:
        filepath: 日志文件路径
        pattern: 正则表达式
    
    Returns:
        匹配结果列表
    """
    compiled_pattern = re.compile(pattern)
    matches = []
    
    with open(filepath, 'rb') as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        # 逐行扫描内存映射（注意：二进制模式）
        for line in iter(mm.readline, b''):
            decoded = line.decode('utf-8', errors='ignore')
            if compiled_pattern.search(decoded):
                matches.append(decoded.strip())
        mm.close()
    
    return matches


def mmap_extract_ips(filepath: str) -> List[str]:
    """示例：快速提取所有 IP 地址"""
    ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    return mmap_search(filepath, ip_pattern)


# =============================================================================
# 方案四：断点续传（定时任务/大文件增量处理）
# =============================================================================

class IncrementalProcessor:
    """
    增量日志处理器 - 支持断点续传
    适合：定时任务、大文件持续追加场景
    """
    
    def __init__(self, checkpoint_file: str = 'log_checkpoint.json'):
        self.checkpoint_file = Path(checkpoint_file)
        self.positions = self._load_checkpoint()
    
    def _load_checkpoint(self) -> Dict:
        """加载检查点"""
        if self.checkpoint_file.exists():
            with open(self.checkpoint_file, 'r') as f:
                return json.load(f)
        return {}
    
    def _save_checkpoint(self):
        """保存检查点"""
        with open(self.checkpoint_file, 'w') as f:
            json.dump(self.positions, f)
    
    def process_incremental(self, filepath: str, 
                           filter_fn: Optional[Callable[[str], bool]] = None) -> List[str]:
        """
        增量处理文件，从上次的 offset 继续
        
        Args:
            filepath: 日志文件路径
            filter_fn: 可选的过滤函数
        
        Returns:
            新匹配的行列表
        """
        last_pos = self.positions.get(filepath, 0)
        results = []
        
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            f.seek(last_pos)
            for line in f:
                line = line.strip()
                if filter_fn is None or filter_fn(line):
                    results.append(line)
            # 保存新位置
            self.positions[filepath] = f.tell()
        
        self._save_checkpoint()
        return results
    
    def reset_checkpoint(self, filepath: Optional[str] = None):
        """重置检查点"""
        if filepath:
            self.positions.pop(filepath, None)
        else:
            self.positions = {}
        self._save_checkpoint()


# =============================================================================
# 方案五：Polars 大规模分析（超大数据集）
# =============================================================================

def polars_analyze(file_pattern: str, 
                   separator: str = '|',
                   columns: Optional[List[str]] = None) -> Optional['pl.DataFrame']:
    """
    使用 Polars 进行超大规模日志分析
    比 Pandas 快 10-50 倍，内存效率更高
    
    Args:
        file_pattern: 文件匹配模式
        separator: 分隔符
        columns: 列名列表
    
    Returns:
        Polars DataFrame 或 None（未安装 polars）
    """
    if not HAS_POLARS:
        logging.warning("Polars not installed. Run: pip install polars")
        return None
    
    default_columns = ['timestamp', 'level', 'module', 'message']
    columns = columns or default_columns
    
    df = pl.scan_csv(
        file_pattern,
        separator=separator,
        has_header=False,
        new_columns=columns,
        infer_schema_length=10000
    )
    
    return df


def polars_error_summary(df: 'pl.DataFrame') -> 'pl.DataFrame':
    """Polars 错误统计示例"""
    if df is None:
        return None
    
    return df.filter(
        pl.col('level').str.to_uppercase() == 'ERROR'
    ).group_by(
        pl.col('timestamp').str.strptime(pl.Datetime, '%Y-%m-%d %H:%M:%S').dt.truncate('1h')
    ).agg(
        pl.count().alias('error_count')
    ).sort('timestamp').collect()


# =============================================================================
# 方案六：DuckDB SQL 分析
# =============================================================================

def duckdb_analyze(file_pattern: str) -> Optional['duckdb.DuckDBPyConnection']:
    """
    使用 DuckDB 进行 SQL 分析
    优势：零配置，支持直接查询 CSV/JSON/Parquet
    """
    if not HAS_DUCKDB:
        logging.warning("DuckDB not installed. Run: pip install duckdb")
        return None
    
    conn = duckdb.connect()
    
    # 创建视图直接查询日志文件
    conn.execute(f"""
        CREATE VIEW logs AS 
        SELECT * FROM read_csv_auto('{file_pattern}', 
            columns={{'timestamp': 'TIMESTAMP', 'level': 'VARCHAR', 'message': 'VARCHAR'}})
    """)
    
    return conn


# =============================================================================
# 管道组合工具（函数式编程风格）
# =============================================================================

def pipeline_process(file_pattern: str,
                    filter_fn: Optional[Callable[[str], bool]] = None,
                    transform_fn: Optional[Callable[[str], Dict]] = None,
                    aggregate_fn: Optional[Callable[[Iterator], Dict]] = None) -> Dict:
    """
    函数式管道处理
    
    示例：
        pipeline_process(
            '/var/log/*.log',
            filter_fn=lambda x: '[ERROR]' in x,
            transform_fn=lambda x: {'timestamp': x[:19], 'msg': x[20:]},
            aggregate_fn=lambda it: Counter(item['timestamp'][:10] for item in it)
        )
    """
    lines = stream_multiple(file_pattern)
    
    if filter_fn:
        lines = filter(filter_fn, lines)
    
    if transform_fn:
        lines = map(transform_fn, lines)
    
    if aggregate_fn:
        return aggregate_fn(lines)
    
    return list(lines)


# =============================================================================
# 便捷函数
# =============================================================================

def quick_count_errors(file_pattern: str) -> Dict:
    """快速统计错误数"""
    return pipeline_process(
        file_pattern,
        filter_fn=lambda x: '[ERROR]' in x,
        aggregate_fn=lambda it: {'error_count': sum(1 for _ in it)}
    )


def extract_with_pattern(file_pattern: str, regex: str) -> List[str]:
    """提取匹配正则的所有行"""
    compiled = re.compile(regex)
    return pipeline_process(
        file_pattern,
        filter_fn=lambda x: compiled.search(x),
        aggregate_fn=list
    )


# =============================================================================
# 使用示例
# =============================================================================

if __name__ == '__main__':
    # 示例 1: 快速统计
    print("=== 快速错误统计 ===")
    result = quick_count_errors('/var/log/*.log')
    print(f"错误数: {result}")
    
    # 示例 2: 流式分析
    print("\n=== 流式分析 ===")
    analyzer = LogAnalyzer(level_pattern=r'user_id=(\d+)')
    stats = analyzer.analyze_pattern('/var/log/app*.log')
    print(f"处理文件: {stats['files_processed']}, 总行数: {stats['total_lines']}")
    
    # 示例 3: 多进程并行
    print("\n=== 多进程并行 ===")
    parallel_stats = parallel_analyze('/var/log/*.log', max_workers=4)
    print(f"成功: {parallel_stats['files_processed']}, 失败: {len(parallel_stats['failed_files'])}")
    
    # 示例 4: 增量处理
    print("\n=== 增量处理 ===")
    processor = IncrementalProcessor('my_checkpoint.json')
    new_errors = processor.process_incremental(
        '/var/log/app.log',
        filter_fn=lambda x: '[ERROR]' in x
    )
    print(f"新错误: {len(new_errors)}")
    
    # 示例 5: Polars 分析（如果安装了 polars）
    if HAS_POLARS:
        print("\n=== Polars 分析 ===")
        df = polars_analyze('/var/log/*.log')
        if df is not None:
            summary = polars_error_summary(df)
            print(summary)
