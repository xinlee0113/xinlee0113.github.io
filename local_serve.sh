#!/bin/bash

################################################################################
# Jekyll本地服务器启动脚本
# 用途：自动安装依赖并启动Jekyll本地开发服务器
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo -e "${BLUE}🚀 Jekyll本地服务器启动脚本${NC}"
echo "=========================================="
echo ""

# 检查Ruby是否安装
echo "检查环境..."
if ! command -v ruby &> /dev/null; then
    echo -e "${RED}❌ Ruby未安装${NC}"
    echo "请先安装Ruby 3.1或更高版本"
    echo "Ubuntu/Debian: sudo apt install ruby-full"
    echo "macOS: brew install ruby"
    exit 1
fi

echo -e "${GREEN}✅ Ruby版本: $(ruby -v)${NC}"

# 检查Bundler是否安装
if ! command -v bundle &> /dev/null; then
    echo -e "${YELLOW}⚠️  Bundler未安装，正在安装...${NC}"
    gem install bundler
fi

echo -e "${GREEN}✅ Bundler版本: $(bundle -v)${NC}"
echo ""

# 安装Jekyll依赖
echo "--- 安装依赖包 ---"
if [ ! -f "Gemfile.lock" ]; then
    echo "首次运行，安装所有依赖..."
    bundle install
else
    echo "检查并更新依赖..."
    bundle install
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 依赖安装失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 依赖安装完成${NC}"
echo ""

# 清理旧的构建文件
echo "--- 清理旧文件 ---"
if [ -d "_site" ]; then
    rm -rf _site
    echo "已清理 _site 目录"
fi

if [ -d ".jekyll-cache" ]; then
    rm -rf .jekyll-cache
    echo "已清理 .jekyll-cache 目录"
fi
echo ""

# 启动Jekyll服务器
echo "=========================================="
echo -e "${GREEN}🎉 启动Jekyll本地服务器${NC}"
echo "=========================================="
echo ""
echo "访问地址: http://localhost:4000"
echo "按 Ctrl+C 停止服务器"
echo ""

# 使用livereload自动刷新
bundle exec jekyll serve --livereload --open-url

# 如果livereload不支持，使用标准模式
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  livereload模式失败，使用标准模式${NC}"
    bundle exec jekyll serve
fi

