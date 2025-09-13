#!/bin/bash

echo "🔍 检查GitHub Pages部署状态..."
echo ""

echo "📊 仓库信息："
curl -s "https://api.github.com/repos/xinlee0113/xinlee0113.github.io" | jq -r '
"仓库名: " + .name,
"默认分支: " + .default_branch,
"Pages启用: " + (.has_pages | tostring),
"更新时间: " + .pushed_at'

echo ""
echo "🚀 GitHub Actions状态："
curl -s "https://api.github.com/repos/xinlee0113/xinlee0113.github.io/actions/runs?per_page=1" | jq -r '
.workflow_runs[0] | 
"工作流: " + .name,
"状态: " + .status,
"结论: " + (.conclusion // "进行中"),
"运行时间: " + .created_at'

echo ""
echo "📝 下一步操作："
echo "1. 确保在GitHub仓库设置中启用了Pages功能"  
echo "2. Source设置为'GitHub Actions'"
echo "3. 等待工作流完成部署"
echo "4. 访问 https://xinlee0113.github.io"
