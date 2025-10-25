# GitHub Pages部署指南

本指南将帮助您将Jekyll网站部署到GitHub Pages。

## 📋 前提条件

- ✅ 已有GitHub账号
- ✅ 已安装Git
- ✅ 网站已在本地测试通过

---

## 🚀 部署步骤

### 步骤1：创建GitHub仓库

1. 登录GitHub，点击右上角 **+** → **New repository**

2. 填写仓库信息：
   - **Repository name**: 选择一个名称（如 `android-docs`）
   - **Description**: Android源码学习文档站
   - **Public**: 必须选择公开（GitHub Pages要求）
   - ❌ 不要勾选 "Initialize this repository with a README"

3. 点击 **Create repository**

---

### 步骤2：修改网站配置

编辑 `_config.yml` 文件，更新以下配置：

```yaml
# 网站标题和描述（根据需要修改）
title: Android源码学习文档站
description: Android源码分析、学习笔记、技术文档

# 重要：根据仓库类型设置baseurl
# 如果仓库名是 username.github.io，则留空：baseurl: ""
# 如果仓库名是其他（如 android-docs），则填写：baseurl: "/android-docs"
baseurl: "/REPOSITORY_NAME"  # 替换为您的仓库名

# 您的GitHub Pages URL
url: "https://YOUR_USERNAME.github.io"  # 替换为您的GitHub用户名

# 作者信息（可选）
author:
  name: "Your Name"
  email: "your.email@example.com"
```

**示例：**
```yaml
# 如果用户名是 zhangsan，仓库名是 android-docs
baseurl: "/android-docs"
url: "https://zhangsan.github.io"
```

---

### 步骤3：推送代码到GitHub

在网站根目录执行：

```bash
# 1. 添加所有文件到暂存区
git add .

# 2. 提交更改
git commit -m "Initial commit: 搭建Android源码学习文档站"

# 3. 重命名分支为main（GitHub Pages默认使用main分支）
git branch -M main

# 4. 添加远程仓库（替换为您的GitHub用户名和仓库名）
git remote add origin https://github.com/YOUR_USERNAME/REPOSITORY_NAME.git

# 5. 推送到GitHub
git push -u origin main
```

**如果推送时要求输入账号密码：**
- GitHub已不支持密码认证，需要使用Personal Access Token
- 参考下方"生成Personal Access Token"部分

---

### 步骤4：启用GitHub Pages

1. 进入GitHub仓库页面

2. 点击 **Settings**（设置）

3. 在左侧边栏找到 **Pages**

4. 在 **Build and deployment** 部分：
   - **Source**: 选择 **GitHub Actions**（推荐）
   - 或选择 **Deploy from a branch** → 选择 **main** 分支

5. 点击 **Save**（如果使用branch模式）

6. 等待2-3分钟，页面会显示：
   ```
   Your site is live at https://YOUR_USERNAME.github.io/REPOSITORY_NAME/
   ```

---

### 步骤5：验证部署

1. 访问显示的URL

2. 检查以下内容：
   - ✅ 首页正常显示
   - ✅ 导航链接正常工作
   - ✅ 文档页面可以访问
   - ✅ 搜索功能正常
   - ✅ PlantUML图表正常渲染

---

## 🔧 常见问题

### 问题1：网站显示404错误

**原因**：`baseurl`配置不正确

**解决方法**：
- 如果仓库名是 `username.github.io`，设置 `baseurl: ""`
- 如果仓库名是其他（如 `android-docs`），设置 `baseurl: "/android-docs"`

---

### 问题2：样式和资源加载失败

**原因**：资源路径不正确

**解决方法**：
- 确保 `_config.yml` 中的 `url` 和 `baseurl` 正确
- 重新推送代码触发构建：
  ```bash
  git commit --allow-empty -m "Trigger rebuild"
  git push
  ```

---

### 问题3：GitHub Actions构建失败

**查看构建日志**：
1. 进入仓库的 **Actions** 标签
2. 点击失败的workflow
3. 查看错误信息

**常见错误**：
- **Gemfile依赖问题**：检查 `Gemfile` 语法
- **Jekyll配置错误**：检查 `_config.yml` 语法
- **Markdown语法错误**：检查文档的Front Matter

---

### 问题4：推送代码时提示权限错误

**生成Personal Access Token**：

1. 登录GitHub，点击右上角头像 → **Settings**

2. 左侧边栏拉到最下面，点击 **Developer settings**

3. 点击 **Personal access tokens** → **Tokens (classic)**

4. 点击 **Generate new token** → **Generate new token (classic)**

5. 填写信息：
   - **Note**: Jekyll Site Deploy Token
   - **Expiration**: 选择有效期
   - **Select scopes**: 勾选 **repo**

6. 点击 **Generate token**，复制生成的token

7. 使用token推送：
   ```bash
   git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/REPOSITORY_NAME.git
   git push
   ```

---

## 🔄 更新网站内容

### 添加新文档

1. 在相应目录创建 `.md` 文件
2. 添加Front Matter
3. 编写内容
4. 提交并推送

```bash
git add docs/new-doc.md
git commit -m "Add new document"
git push
```

GitHub Actions会自动构建并部署更新。

### 修改现有文档

1. 编辑文档
2. 提交并推送

```bash
git add docs/modified-doc.md
git commit -m "Update document"
git push
```

---

## 📊 监控部署状态

### 查看Actions构建日志

1. 进入仓库的 **Actions** 标签
2. 查看最新的workflow运行
3. 点击可查看详细日志

### 构建徽章

在 `README.md` 中添加构建状态徽章：

```markdown
[![Deploy Jekyll site to Pages](https://github.com/YOUR_USERNAME/REPOSITORY_NAME/actions/workflows/pages.yml/badge.svg)](https://github.com/YOUR_USERNAME/REPOSITORY_NAME/actions/workflows/pages.yml)
```

---

## 🌐 自定义域名（可选）

如果您有自己的域名：

### 1. 添加CNAME文件

在仓库根目录创建 `CNAME` 文件：

```
docs.yourdomain.com
```

### 2. 配置DNS

在域名提供商处添加DNS记录：

```
类型: CNAME
主机: docs (或您想要的子域名)
值: YOUR_USERNAME.github.io
```

### 3. 更新配置

修改 `_config.yml`：

```yaml
url: "https://docs.yourdomain.com"
baseurl: ""
```

### 4. 在GitHub Pages设置中填入自定义域名

---

## 📚 进阶配置

### 启用HTTPS（推荐）

在GitHub Pages设置中：
- ✅ 勾选 **Enforce HTTPS**

### 配置SEO

在 `_config.yml` 中添加：

```yaml
plugins:
  - jekyll-seo-tag
  - jekyll-sitemap
```

### Google Analytics（可选）

添加跟踪代码到 `_config.yml`：

```yaml
google_analytics: UA-XXXXXXXXX-X
```

---

## 🛠️ 故障排除

### 完全重新部署

如果网站出现问题，可以尝试完全重新部署：

```bash
# 1. 清理本地构建文件
rm -rf _site .jekyll-cache

# 2. 重新构建
bundle exec jekyll build

# 3. 提交并推送（触发重新部署）
git add .
git commit -m "Rebuild site"
git push
```

### 联系支持

如果遇到无法解决的问题：
- 查看GitHub Pages官方文档：https://docs.github.com/pages
- 在仓库中创建Issue
- 访问Jekyll官方文档：https://jekyllrb.com/docs/

---

## ✅ 部署检查清单

部署前请确认：

- [ ] `_config.yml` 中的 `url` 和 `baseurl` 已正确设置
- [ ] 所有文档都有正确的Front Matter
- [ ] 本地测试通过（`bundle exec jekyll serve`）
- [ ] GitHub Actions workflow文件存在
- [ ] 仓库设置为Public
- [ ] GitHub Pages已启用
- [ ] 推送代码成功
- [ ] 构建和部署成功（无错误）
- [ ] 在线访问正常

---

**祝部署顺利！🎉**

如有问题，欢迎在Issues中提问。

