# Android源码学习文档站

[![Deploy Jekyll site to Pages](https://github.com/xinlee0113/xinlee0113.github.io/actions/workflows/pages.yml/badge.svg)](https://github.com/xinlee0113/xinlee0113.github.io/actions/workflows/pages.yml)

📚 一个基于Jekyll的Android源码学习文档站，支持PlantUML图表在线渲染。

## 🌟 特性

- ✅ **Markdown写作** - 使用Markdown编写文档，简单高效
- ✅ **PlantUML支持** - 内置PlantUML渲染，绘制UML图表
- ✅ **全文搜索** - 基于Just the Docs主题的强大搜索功能
- ✅ **响应式设计** - 支持桌面和移动端访问
- ✅ **自动部署** - GitHub Actions自动构建和部署
- ✅ **零成本** - 完全免费的GitHub Pages托管

## 📖 在线访问

🔗 [https://xinlee0113.github.io](https://xinlee0113.github.io)

## 🚀 快速开始

### 前置要求

- Ruby 3.1+
- Bundler
- Git

### 本地运行

1. **克隆仓库**

```bash
git clone https://github.com/xinlee0113/xinlee0113.github.io.git
cd xinlee0113.github.io
```

2. **安装依赖**

```bash
bundle install
```

3. **启动本地服务器**

```bash
bundle exec jekyll serve
```

4. **访问网站**

打开浏览器访问：`http://localhost:4000`

### 快速脚本

使用提供的自动化脚本：

```bash
# 安装依赖并启动服务器
bash scripts/local_serve.sh
```

## 📁 目录结构

```
github-pages/
├── _config.yml              # Jekyll配置文件
├── Gemfile                  # Ruby依赖管理
├── index.md                 # 首页
├── docs/                    # 文档目录
│   ├── android-source/      # Android源码学习
│   │   ├── index.md
│   │   ├── learning-roadmap.md
│   │   ├── quick-reference.md
│   │   └── activity-launch-analysis.md
│   ├── jira/                # 问题分析
│   │   ├── index.md
│   │   └── analysis-process.md
│   ├── tools/               # 开发工具
│   │   ├── index.md
│   │   ├── settings-build-script.md
│   │   └── source-analysis-tools.md
│   └── plantuml-guide.md    # PlantUML使用指南
├── _includes/               # 可复用组件
│   └── plantuml.html        # PlantUML支持
├── _layouts/                # 布局模板
│   └── default.html
├── assets/                  # 静态资源
│   └── css/
│       └── custom.css       # 自定义样式
└── .github/
    └── workflows/
        └── pages.yml        # GitHub Actions配置
```

## 📝 编写文档

### 创建新文档

1. 在相应目录下创建`.md`文件
2. 添加Front Matter：

```markdown
---
layout: default
title: 文档标题
parent: 父级页面标题
nav_order: 1
---

# 文档标题

文档内容...
```

### 使用PlantUML

#### 方法1：图片链接

```markdown
![时序图](http://www.plantuml.com/plantuml/svg/ENCODED_STRING)
```

#### 方法2：代码块

在文档中使用\`\`\`plantuml代码块（需要配合插件）。

详细说明请参考：[PlantUML使用指南](docs/plantuml-guide.md)

## 🚢 部署到GitHub Pages

### 步骤1：创建GitHub仓库

1. 在GitHub上创建新仓库（公开仓库）
2. 仓库名可以是任意名称

### 步骤2：推送代码

```bash
git add .
git commit -m "Initial commit: 搭建Android源码学习文档站"
git branch -M main
git remote add origin https://github.com/xinlee0113/xinlee0113.github.io.git
git push -u origin main
```

### 步骤3：启用GitHub Pages

1. 进入仓库的 **Settings** → **Pages**
2. Source选择 **GitHub Actions**
3. 等待自动部署完成（约2-3分钟）
4. 访问 `https://xinlee0113.github.io`

### 步骤4：配置网站设置

编辑 `_config.yml` 文件：

```yaml
title: Android源码学习文档站
description: Android源码分析、学习笔记、技术文档
baseurl: ""  # username.github.io格式，必须留空！
url: "https://xinlee0113.github.io"
```

重新推送更改：

```bash
git add _config.yml
git commit -m "Update site configuration"
git push
```

## 🛠️ 自定义配置

### 修改主题样式

编辑 `assets/css/custom.css` 自定义样式。

### 修改导航顺序

在文档的Front Matter中设置 `nav_order`:

```yaml
---
nav_order: 1  # 数字越小越靠前
---
```

### 添加搜索功能

搜索功能默认启用，可在 `_config.yml` 中配置：

```yaml
search_enabled: true
search:
  heading_level: 2
  previews: 3
```

## 📊 技术栈

- **Jekyll 4.3+** - 静态网站生成器
- **Just the Docs** - Jekyll主题
- **PlantUML** - UML图表绘制
- **GitHub Pages** - 静态网站托管
- **GitHub Actions** - 自动化部署

## 🤝 贡献指南

欢迎贡献文档和改进建议！

1. Fork本仓库
2. 创建特性分支：`git checkout -b feature/new-doc`
3. 提交更改：`git commit -m '添加新文档'`
4. 推送分支：`git push origin feature/new-doc`
5. 提交Pull Request

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

## 📧 联系方式

- 📮 Email: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/xinlee0113/xinlee0113.github.io/issues)

## 🙏 致谢

- [Jekyll](https://jekyllrb.com/) - 强大的静态网站生成器
- [Just the Docs](https://just-the-docs.github.io/just-the-docs/) - 优秀的文档主题
- [PlantUML](https://plantuml.com/) - 简洁的UML绘图工具
- [GitHub Pages](https://pages.github.com/) - 免费的静态网站托管服务

---

⭐ 如果这个项目对您有帮助，欢迎Star支持！

