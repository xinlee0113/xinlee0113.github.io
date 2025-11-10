#!/bin/bash
# PlantUML预渲染脚本
# 在构建时将所有PlantUML代码块渲染为SVG图片

set -e

PLANTUML_JAR="${PLANTUML_JAR:-plantuml.jar}"
OUTPUT_DIR="${OUTPUT_DIR:-_site/plantuml-images}"
DOCS_DIR="${DOCS_DIR:-docs}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "开始预渲染PlantUML图表..."
echo "PlantUML JAR: $PLANTUML_JAR"
echo "输出目录: $OUTPUT_DIR"
echo "文档目录: $DOCS_DIR"

# 计数器
diagram_count=0
file_count=0

# 查找所有Markdown文件
find "$DOCS_DIR" -name "*.md" -type f | while read -r md_file; do
    file_count=$((file_count + 1))
    echo "处理文件: $md_file"

    # 提取文件的基础名称（用于生成唯一ID）
    # 获取相对于docs目录的路径，例如: android-source/Android_Binder机制详解.md
    relative_path=$(echo "$md_file" | sed "s|^$DOCS_DIR/||")
    file_dir=$(dirname "$relative_path")
    file_basename=$(basename "$md_file" .md)

    # 将路径转换为文件名格式（替换特殊字符为下划线）
    if [ "$file_dir" = "." ]; then
        page_name=$(echo "$file_basename" | sed 's/[^a-zA-Z0-9_]/_/g')
    else
        page_name=$(echo "${file_dir}/${file_basename}" | sed 's/[^a-zA-Z0-9_/]/_/g' | sed 's|/|_|g')
    fi

    # 创建输出目录（统一放在根目录）
    mkdir -p "$OUTPUT_DIR"

    # 提取PlantUML代码块（使用Python脚本更可靠）
    python3 <<EOF
import re
import sys
import os

md_file = "$md_file"
page_name = "$page_name"
output_dir = "$OUTPUT_DIR"
plantuml_jar = "$PLANTUML_JAR"

# 读取Markdown文件
with open(md_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 查找所有```plantuml...```代码块
pattern = r'```plantuml\s*\n(.*?)\n```'
matches = re.findall(pattern, content, re.DOTALL)

block_num = 0
for match in matches:
    block_num += 1
    plantuml_code = match.strip()

    # 检查是否包含PlantUML标记
    if '@startuml' in plantuml_code or '@startmindmap' in plantuml_code or '@startwbs' in plantuml_code:
        # 生成唯一文件名（与客户端脚本匹配）
        output_file = os.path.join(output_dir, f"{page_name}_{block_num}.svg")

        # 创建输出目录
        os.makedirs(os.path.dirname(output_file), exist_ok=True)

        # 创建临时PlantUML文件
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.puml', delete=False) as temp_puml:
            temp_puml.write(plantuml_code)
            temp_puml_path = temp_puml.name

        try:
            # 渲染为SVG（使用-out参数指定输出文件名）
            import subprocess
            output_dir = os.path.dirname(output_file)
            output_name = os.path.basename(output_file)

            # PlantUML会生成与输入文件同名的SVG文件
            result = subprocess.run(
                ['java', '-jar', plantuml_jar, '-tsvg', temp_puml_path, '-o', output_dir],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                # PlantUML生成的SVG文件名与输入文件相同（只是扩展名不同）
                temp_svg = temp_puml_path.replace('.puml', '.svg')
                temp_svg_name = os.path.basename(temp_svg)

                # 查找生成的SVG文件
                if os.path.exists(temp_svg):
                    # 移动到目标位置
                    final_path = os.path.join(output_dir, output_name)
                    os.rename(temp_svg, final_path)
                    print(f"  ✓ 成功: {final_path}")
                else:
                    # 尝试在输出目录中查找
                    if os.path.exists(output_dir):
                        generated_files = [f for f in os.listdir(output_dir) if f.endswith('.svg')]
                        if generated_files:
                            # 使用最新生成的SVG文件
                            latest_svg = max([os.path.join(output_dir, f) for f in generated_files],
                                           key=os.path.getmtime)
                            os.rename(latest_svg, output_file)
                            print(f"  ✓ 成功: {output_file}")
                        else:
                            print(f"  ✗ 失败: 未找到生成的SVG文件 (stderr: {result.stderr})")
                    else:
                        print(f"  ✗ 失败: 输出目录不存在: {output_dir}")
            else:
                print(f"  ✗ 失败: {result.stderr}")
        except Exception as e:
            print(f"  ✗ 失败: {str(e)}")
        finally:
            # 清理临时文件
            if os.path.exists(temp_puml_path):
                os.unlink(temp_puml_path)
EOF

done

echo ""
echo "预渲染完成！"
