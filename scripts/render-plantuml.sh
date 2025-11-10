#!/bin/bash
# PlantUML预渲染脚本
# 在构建时将所有PlantUML代码块渲染为SVG图片
# 支持并发渲染和错误恢复

# 不设置set -e，允许部分失败继续执行
set +e

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
success_count=0
fail_count=0

# 检查PlantUML JAR是否存在
if [ ! -f "$PLANTUML_JAR" ]; then
    echo "错误: PlantUML JAR文件不存在: $PLANTUML_JAR"
    exit 1
fi

# 验证Java是否可用
if ! command -v java &> /dev/null; then
    echo "错误: Java未安装或不在PATH中"
    exit 1
fi

echo "验证PlantUML JAR..."
java -jar "$PLANTUML_JAR" -version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "警告: PlantUML JAR可能损坏，但继续尝试..."
fi

# 查找所有Markdown文件
find "$DOCS_DIR" -name "*.md" -type f | while read -r md_file; do
    file_count=$((file_count + 1))
    echo "处理文件: $md_file"

    # 提取文件的基础名称（用于生成唯一ID）
    # 获取相对于docs目录的路径，例如: android-source/Android_Binder机制详解.md
    relative_path=$(echo "$md_file" | sed "s|^$DOCS_DIR/||")
    file_dir=$(dirname "$relative_path")
    file_basename=$(basename "$md_file" .md)

    # 将路径转换为文件名格式（与客户端脚本保持一致）
    # 客户端脚本逻辑：pagePath.replace(/\//g, '_').replace(/[^a-zA-Z0-9_]/g, '_')
    if [ "$file_dir" = "." ]; then
        # 如果文件在docs根目录
        page_name=$(echo "$file_basename" | sed 's/[^a-zA-Z0-9_]/_/g')
    else
        # 如果文件在子目录，先合并路径再替换
        page_path="${file_dir}/${file_basename}"
        page_name=$(echo "$page_path" | sed 's|/|_|g' | sed 's/[^a-zA-Z0-9_]/_/g')
    fi

    echo "  生成页面名: $page_name (文件: $relative_path)"

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
success_count = 0
fail_count = 0

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
            # 增加超时时间到60秒，并设置JVM内存限制
            # 使用 -o 参数指定输出目录，PlantUML会在该目录生成SVG文件
            result = subprocess.run(
                ['java', '-Xmx512m', '-jar', plantuml_jar, '-tsvg', temp_puml_path, '-o', output_dir],
                capture_output=True,
                text=True,
                timeout=60,
                cwd=os.path.dirname(temp_puml_path)  # 设置工作目录
            )

            if result.returncode == 0:
                # PlantUML使用 -o 参数时，会在输出目录生成SVG文件
                # 文件名基于输入文件名（临时文件名）
                temp_svg_basename = os.path.basename(temp_puml_path).replace('.puml', '.svg')

                # 查找生成的SVG文件（可能在输出目录或临时目录）
                found_svg = None

                # 1. 先检查输出目录
                output_svg = os.path.join(output_dir, temp_svg_basename)
                if os.path.exists(output_svg):
                    found_svg = output_svg
                else:
                    # 2. 检查临时目录（PlantUML可能在工作目录生成）
                    temp_svg = os.path.join(os.path.dirname(temp_puml_path), temp_svg_basename)
                    if os.path.exists(temp_svg):
                        found_svg = temp_svg
                    else:
                        # 3. 在输出目录中查找所有SVG文件（可能是其他名称）
                        if os.path.exists(output_dir):
                            generated_files = [f for f in os.listdir(output_dir) if f.endswith('.svg')]
                            if generated_files:
                                # 使用最新生成的SVG文件
                                found_svg = max([os.path.join(output_dir, f) for f in generated_files],
                                               key=os.path.getmtime)

                if found_svg and os.path.exists(found_svg):
                    # 移动到目标位置
                    final_path = os.path.join(output_dir, output_name)
                    if found_svg != final_path:
                        os.rename(found_svg, final_path)
                    print(f"  ✓ 成功: {final_path}")
                    success_count += 1
                else:
                    print(f"  ✗ 失败: 未找到生成的SVG文件")
                    print(f"    查找路径: {output_svg}")
                    print(f"    临时路径: {temp_svg}")
                    if result.stderr:
                        print(f"    错误信息: {result.stderr[:200]}")
                    if result.stdout:
                        print(f"    输出信息: {result.stdout[:200]}")
                    fail_count += 1
            else:
                print(f"  ✗ 失败: PlantUML渲染错误 (返回码: {result.returncode})")
                if result.stderr:
                    print(f"    错误信息: {result.stderr[:200]}")
                if result.stdout:
                    print(f"    输出信息: {result.stdout[:200]}")
                fail_count += 1
        except subprocess.TimeoutExpired:
            print(f"  ✗ 失败: 渲染超时（超过60秒）")
            fail_count += 1
        except Exception as e:
            print(f"  ✗ 失败: {str(e)}")
            fail_count += 1
        finally:
            # 清理临时文件
            if os.path.exists(temp_puml_path):
                os.unlink(temp_puml_path)

# 输出统计信息
print(f"\n========== 文件统计 ==========")
print(f"成功渲染: {success_count}")
print(f"失败渲染: {fail_count}")
print(f"================================")
EOF

done

echo ""
echo "========== 预渲染完成 =========="
echo "处理文件数: $file_count"
echo "================================"
