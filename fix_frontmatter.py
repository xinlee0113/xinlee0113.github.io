#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修复MiuiProvision文档的front matter - 更正parent配置"""

import os
import re
from pathlib import Path

# 配置
DOCS_ROOT = Path("/mnt/01_lixin_workspace/github-pages/docs/miui-provision")

# 目录与对应的parent标题
DIR_PARENT_MAP = {
    "操作手册": "操作手册",
    "模块解析": "模块解析",
    "流程规范": "流程规范",
    "问题修复": "问题修复",
    "汇报": "工作汇报",
    "提示词": "AI提示词",
}

def extract_current_frontmatter(content):
    """提取当前的front matter"""
    if not content.strip().startswith('---'):
        return None, content
    
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, content
    
    return parts[1], parts[2]

def fix_frontmatter(filepath, correct_parent):
    """修复文件的front matter中的parent"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    frontmatter, body = extract_current_frontmatter(content)
    
    if not frontmatter:
        print(f"  ⚠️  跳过（无front matter）: {filepath.name}")
        return
    
    # 提取title
    title_match = re.search(r'^title:\s*(.+)$', frontmatter, re.MULTILINE)
    if not title_match:
        print(f"  ⚠️  跳过（无title）: {filepath.name}")
        return
    
    title = title_match.group(1).strip()
    
    # 检查当前parent
    parent_match = re.search(r'^parent:\s*(.+)$', frontmatter, re.MULTILINE)
    if parent_match:
        current_parent = parent_match.group(1).strip()
        if current_parent == correct_parent:
            print(f"  ⏭️  跳过（parent已正确）: {filepath.name}")
            return
    
    # 构建新的front matter
    new_frontmatter = f"""---
layout: default
title: {title}
parent: {correct_parent}
---

"""
    
    # 写入文件
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_frontmatter + body)
    
    print(f"  ✅ 已修复: {filepath.name}")
    print(f"      parent: {correct_parent}")

def main():
    print("=" * 60)
    print("🔧 修复MiuiProvision文档的parent配置")
    print("=" * 60)
    
    # 处理每个目录
    for dir_name, parent_title in DIR_PARENT_MAP.items():
        dir_path = DOCS_ROOT / dir_name
        if not dir_path.exists():
            print(f"\n⚠️  目录不存在: {dir_name}")
            continue
        
        print(f"\n📁 处理目录: {dir_name}")
        print(f"   正确的parent: {parent_title}")
        
        # 获取所有.md文件（排除index.md）
        md_files = [f for f in dir_path.glob('*.md') if f.name != 'index.md']
        
        if not md_files:
            print(f"  ℹ️  没有需要处理的文件")
            continue
        
        # 修复每个文件
        for md_file in sorted(md_files):
            try:
                fix_frontmatter(md_file, parent_title)
            except Exception as e:
                print(f"  ❌ 错误: {md_file.name} - {e}")
    
    # 特殊处理：模块解析/1009子目录
    print(f"\n📁 处理子目录: 模块解析/1009")
    print(f"   正确的parent: 开机引导模块")
    
    subdir_path = DOCS_ROOT / "模块解析" / "1009"
    if subdir_path.exists():
        md_files = [f for f in subdir_path.glob('*.md') if f.name != 'index.md']
        for md_file in sorted(md_files):
            try:
                fix_frontmatter(md_file, "开机引导模块")
            except Exception as e:
                print(f"  ❌ 错误: {md_file.name} - {e}")
    
    print("\n" + "=" * 60)
    print("✨ 修复完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()

