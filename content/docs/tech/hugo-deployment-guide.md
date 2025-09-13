---
title: "Hugo博客完整部署指南"
weight: 2
date: 2025-09-13T15:30:00+08:00
draft: false
bookFlatSection: false
bookToc: true
bookHidden: false
bookCollapseSection: false
bookComments: true
bookSearchExclude: false
tags: ["Hugo", "部署", "GitHub Pages", "WSL"]
description: "从零开始搭建和部署Hugo博客的详细教程，包含环境配置、主题选择、问题排查等"
---

# Hugo博客完整部署指南

## 🎯 概述

本指南详细记录了从零开始搭建Hugo博客的完整流程，包括环境配置、主题安装、常见问题解决方案等。

## 📋 前置条件

- Windows 10/11 + WSL2 (Ubuntu)
- Git 版本控制
- GitHub 账户（用于托管）

## 🚀 第一步：环境准备

### 1.1 安装Hugo

#### 下载Hugo Extended版本

```bash
# 进入临时目录
cd /tmp

# 下载Hugo Extended版本（支持SCSS/SASS）
wget https://github.com/gohugoio/hugo/releases/download/v0.150.0/hugo_extended_0.150.0_linux-amd64.tar.gz

# 解压缩
tar -xzf hugo_extended_0.150.0_linux-amd64.tar.gz

# 移动到系统路径
sudo mv hugo /usr/local/bin/

# 验证安装
hugo version
```

#### 安装兼容的Go版本

```bash
# 下载Go语言
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz

# 解压到/usr/local
sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz

# 添加环境变量到~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 验证Go安装
go version
```

### 1.2 验证环境

```bash
# 检查Hugo版本（应显示extended）
hugo version

# 检查Go版本
go version
```

## 🏗️ 第二步：创建Hugo站点

### 2.1 初始化项目

```bash
# 创建新的Hugo站点
hugo new site my_hugo_blog

# 进入项目目录
cd my_hugo_blog

# 初始化Git仓库
git init
```

### 2.2 选择并安装主题

我们选择功能丰富的 `hugo-book` 主题：

```bash
# 下载主题到themes目录
git clone https://github.com/alex-shpak/hugo-book.git themes/hugo-book

# 或者作为Git子模块添加
git submodule add https://github.com/alex-shpak/hugo-book.git themes/hugo-book
```

### 2.3 配置站点

创建或编辑 `config.toml` 文件：

```toml
baseURL = "https://your-username.github.io/"
languageCode = "zh-cn"
title = "我的个人博客"
theme = "hugo-book"

# Book configuration
disablePathToLower = true
enableGitInfo = true

# Needed for mermaid/katex shortcodes
[markup]
[markup.goldmark.renderer]
  unsafe = true

[markup.tableOfContents]
  startLevel = 1

[params]
  # Sets color theme: light, dark or auto
  BookTheme = 'auto'
  
  # Controls table of contents visibility
  BookToC = true
  
  # Specify root page to render child pages as menu
  BookSection = 'docs'
  
  # Enable search function
  BookSearch = true
  
  # Enable comments
  BookComments = false
  
  # Date format
  BookDateFormat = '2006年1月2日'
```

## 📝 第三步：创建内容结构

### 3.1 创建文档目录结构

```bash
# 创建主要内容目录
mkdir -p content/docs/{tech,notes,projects}

# 创建索引页面
hugo new content/docs/_index.md
hugo new content/docs/tech/_index.md
hugo new content/docs/notes/_index.md
hugo new content/docs/projects/_index.md
```

### 3.2 创建第一篇文章

```bash
# 创建技术文章
hugo new content/docs/tech/my-first-post.md
```

## 🔧 第四步：本地开发和调试

### 4.1 启动开发服务器

```bash
# 启动包含草稿的开发服务器
hugo server --buildDrafts --theme hugo-book

# 或者指定端口
hugo server -p 1313 --buildDrafts --theme hugo-book
```

### 4.2 访问本地博客

打开浏览器访问：`http://localhost:1313`

## ⚠️ 常见问题及解决方案

### 问题1：SCSS编译错误

**错误信息：**
```
ERROR TOCSS: failed to transform "book.scss" (text/x-scss). 
Check your Hugo installation; you need the extended version to build SCSS/SASS
```

**解决方案：**
- 必须使用Hugo Extended版本
- 重新下载并安装 `hugo_extended_0.150.0_linux-amd64.tar.gz`

### 问题2：主题样式不显示

**可能原因：**
- 主题路径不正确
- config.toml中theme配置错误

**解决方案：**
```bash
# 检查主题目录结构
ls -la themes/hugo-book/

# 确认config.toml中的theme配置
grep "theme" config.toml
```

### 问题3：中文字符显示异常

**解决方案：**
在config.toml中设置正确的语言编码：
```toml
languageCode = "zh-cn"
defaultContentLanguage = "zh"
```

### 问题4：GitHub Pages部署失败

**检查清单：**
- 仓库名格式：`username.github.io`
- 分支设置：使用`gh-pages`分支或`main`分支的`/docs`目录
- baseURL配置正确

## 🚀 第五步：部署到GitHub Pages

### 5.1 创建GitHub仓库

1. 创建名为 `username.github.io` 的公开仓库
2. 克隆到本地或关联现有项目

### 5.2 配置GitHub Actions部署

创建 `.github/workflows/gh-pages.yml`：

```yaml
name: GitHub Pages

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-22.04
    permissions:
      contents: write
    concurrency:
      group: "$&#123;&#123; github.workflow &#125;&#125;-$&#123;&#123; github.ref &#125;&#125;"
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.150.0'
          extended: true

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        if: $&#123;&#123; github.ref == 'refs/heads/main' &#125;&#125;
        with:
          github_token: $&#123;&#123; secrets.GITHUB_TOKEN &#125;&#125;
          publish_dir: ./public
```

### 5.3 推送代码

```bash
# 添加所有文件
git add .

# 提交变更
git commit -m "初始化Hugo博客"

# 添加远程仓库
git remote add origin https://github.com/your-username/your-username.github.io.git

# 推送到主分支
git push -u origin main
```

## 📊 性能优化建议

### 6.1 图片优化
- 使用WebP格式
- 设置合适的图片尺寸
- 启用懒加载

### 6.2 构建优化
```bash
# 生产环境构建
hugo --minify --gc

# 启用资源压缩
hugo --minify
```

## 📚 扩展功能

### 7.1 添加评论系统
- Disqus
- Gitalk
- Utterances

### 7.2 SEO优化
- 设置meta标签
- 添加sitemap
- 配置robots.txt

### 7.3 分析统计
- Google Analytics
- 百度统计

## 🎉 总结

通过以上步骤，您已经成功搭建了一个功能完整的Hugo博客。记住以下关键点：

✅ **使用Hugo Extended版本**  
✅ **正确配置主题和语言**  
✅ **建立清晰的内容结构**  
✅ **配置自动化部署**  

现在开始您的博客创作之旅吧！

## 🔗 相关链接

- [Hugo官方文档](https://gohugo.io/documentation/)
- [Hugo Book主题文档](https://hugo-book-demo.netlify.app/)
- [GitHub Pages文档](https://docs.github.com/en/pages)
- [Markdown语法指南](https://www.markdownguide.org/)
