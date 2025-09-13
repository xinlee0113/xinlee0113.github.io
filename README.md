# 我的个人博客

使用 Hugo 静态网站生成器构建的个人博客，自动部署到 GitHub Pages。

## 🚀 特性

- **Hugo 静态网站生成器**: 快速、现代的网站构建工具
- **响应式设计**: 支持桌面和移动设备
- **自动部署**: 使用 GitHub Actions 自动构建和部署
- **Simple 主题**: 简洁优雅的博客主题
- **中文支持**: 完整的中文内容支持

## 📁 项目结构

```
my_hugo_blog/
├── .github/workflows/    # GitHub Actions 工作流
├── content/             # 网站内容
│   ├── docs/           # 文档页面
│   │   ├── tech/       # 技术分享
│   │   └── notes/      # 学习笔记
├── themes/             # Hugo 主题
│   ├── simple/         # 自定义简单主题
│   └── hugo-book/      # Hugo Book 主题 (submodule)
├── public/             # 生成的静态文件
├── config.toml         # Hugo 配置文件
└── README.md           # 项目说明
```

## 🛠️ 本地开发

### 前置要求

- Hugo Extended 版本 0.121.1+
- Git

### 运行步骤

1. 克隆仓库：
   ```bash
   git clone --recursive https://github.com/xinlee0113/xinlee0113.github.io.git
   cd xinlee0113.github.io
   ```

2. 启动本地服务器：
   ```bash
   hugo server -D
   ```

3. 访问 `http://localhost:1313` 查看网站

### 添加新文章

```bash
# 创建新的技术分享文章
hugo new docs/tech/my-new-post.md

# 创建新的学习笔记
hugo new docs/notes/my-new-note.md
```

## 📝 内容管理

- **技术分享**: 存放在 `content/docs/tech/` 目录
- **学习笔记**: 存放在 `content/docs/notes/` 目录
- **页面配置**: 每个 Markdown 文件的 Front Matter 包含标题、日期、标签等信息

## 🚀 部署

本项目使用 GitHub Actions 自动部署：

1. 推送代码到 `master` 分支
2. GitHub Actions 自动构建网站
3. 部署到 GitHub Pages
4. 访问 `https://xinlee0113.github.io` 查看网站

## ⚙️ 配置说明

### 网站配置

主要配置在 `config.toml` 文件中：

- `baseURL`: 网站基础URL
- `title`: 网站标题
- `theme`: 使用的主题
- `languageCode`: 语言设置

### 主题配置

当前使用 `simple` 主题，支持：
- 响应式布局
- 文章列表
- 标签系统
- 分类管理

## 🔧 技术栈

- **Hugo**: v0.121.1 (Extended)
- **主题**: Simple + Hugo Book
- **部署**: GitHub Actions + GitHub Pages
- **语言**: 中文

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**🌐 网站地址**: https://xinlee0113.github.io
