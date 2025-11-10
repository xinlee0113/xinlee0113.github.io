# PlantUML本地部署可行性评估

## 📋 问题背景

当前博客使用 **Kroki.io** 远程服务渲染 PlantUML 图表，但遇到 "Failed to fetch" 错误，可能原因：
- 网络连接问题
- CORS策略限制
- 服务器不可用
- 防火墙或代理阻止

**需求**：将 PlantUML 渲染引擎部署到 GitHub Pages，避免网络依赖。

---

## 🔍 方案分析

### 方案1：客户端JavaScript渲染（推荐 ⭐⭐⭐⭐⭐）

#### 可行性：✅ **高度可行**

#### 技术方案
使用 **plantuml-encoder** + **plantuml.js** 在浏览器中直接渲染：

```javascript
// 使用 plantuml-encoder 编码
import { encode } from 'plantuml-encoder';
import { plantuml } from 'plantuml.js';

// 在浏览器中直接渲染
const encoded = encode(plantumlCode);
const svg = plantuml.render(encoded);
```

#### 优点
- ✅ **完全离线**：无需网络请求
- ✅ **快速响应**：本地渲染，无网络延迟
- ✅ **GitHub Pages兼容**：纯静态文件，完全支持
- ✅ **无服务器依赖**：不依赖外部服务
- ✅ **隐私保护**：数据不离开浏览器

#### 缺点
- ⚠️ **文件大小**：需要引入 plantuml.js（约 2-3MB）
- ⚠️ **性能**：复杂图表可能渲染较慢
- ⚠️ **功能限制**：可能不支持所有 PlantUML 特性

#### 实施难度：⭐⭐（中等）
- 需要引入 JavaScript 库
- 需要修改现有渲染脚本
- 需要处理浏览器兼容性

---

### 方案2：构建时预渲染（推荐 ⭐⭐⭐⭐）

#### 可行性：✅ **高度可行**

#### 技术方案
在 **GitHub Actions** 构建时使用 PlantUML 工具生成 SVG/PNG，然后部署静态文件：

```yaml
# .github/workflows/jekyll.yml
- name: Render PlantUML
  run: |
    find docs -name "*.md" -exec grep -l "```plantuml" {} \; | \
    while read file; do
      # 提取 PlantUML 代码块
      # 使用 plantuml.jar 渲染为 SVG
      # 替换代码块为图片链接
    done
```

#### 优点
- ✅ **完全静态**：所有图表都是静态图片
- ✅ **性能最优**：无需运行时渲染
- ✅ **兼容性好**：所有浏览器都支持图片
- ✅ **无依赖**：不依赖任何外部服务

#### 缺点
- ⚠️ **构建时间**：每次构建需要渲染所有图表
- ⚠️ **维护成本**：修改 PlantUML 代码需要重新构建
- ⚠️ **文件管理**：需要管理生成的图片文件

#### 实施难度：⭐⭐⭐（较高）
- 需要配置 GitHub Actions
- 需要编写脚本提取和渲染 PlantUML
- 需要修改 Markdown 文件

---

### 方案3：自托管 Kroki 服务（不推荐 ❌）

#### 可行性：❌ **不可行（GitHub Pages限制）**

#### 技术方案
在 GitHub Pages 上部署 Kroki 服务。

#### 为什么不可行
- ❌ **GitHub Pages 限制**：只支持静态文件，不支持服务器端应用
- ❌ **Kroki 架构**：Kroki 是后端服务，需要运行 Java/Python/Node.js 等
- ❌ **资源需求**：需要服务器资源运行多个图表库

#### 替代方案
如果需要自托管，可以考虑：
- 使用 **Vercel/Netlify** 等支持 Serverless Functions 的平台
- 使用 **Docker** 在自己的服务器上部署
- 使用 **GitHub Actions** 作为"服务器"（但只能用于构建时）

---

### 方案4：混合方案（推荐 ⭐⭐⭐⭐）

#### 可行性：✅ **高度可行**

#### 技术方案
结合方案1和方案2：
- **构建时**：预渲染常用/复杂图表为静态图片
- **运行时**：使用 JavaScript 渲染简单/动态图表

```javascript
// 优先使用预渲染的图片
if (preRenderedImageExists) {
  showImage(preRenderedImage);
} else {
  // 回退到客户端渲染
  renderWithJavaScript(plantumlCode);
}
```

#### 优点
- ✅ **最佳性能**：常用图表预渲染，快速加载
- ✅ **灵活性**：支持动态渲染
- ✅ **容错性**：有多个回退方案

#### 缺点
- ⚠️ **复杂度**：需要维护两套渲染逻辑

---

## 📊 方案对比

| 方案 | 可行性 | 实施难度 | 性能 | 维护成本 | 推荐度 |
|------|--------|----------|------|----------|--------|
| **客户端JS渲染** | ✅ 高 | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **构建时预渲染** | ✅ 高 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **自托管Kroki** | ❌ 低 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **混合方案** | ✅ 高 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 🎯 推荐方案

### 短期方案（快速解决）：客户端JavaScript渲染

**理由**：
1. 实施简单，可以快速解决 "Failed to fetch" 问题
2. 完全离线，不依赖任何外部服务
3. GitHub Pages 完全支持

**实施步骤**：
1. 引入 `plantuml-encoder` 和 `plantuml.js` 库
2. 修改 `_includes/plantuml.html` 脚本
3. 使用本地渲染替代远程请求

### 长期方案（最佳实践）：构建时预渲染

**理由**：
1. 性能最优，用户体验最好
2. 完全静态，SEO友好
3. 不依赖浏览器JavaScript

**实施步骤**：
1. 配置 GitHub Actions
2. 编写 PlantUML 提取和渲染脚本
3. 自动替换代码块为图片

---

## 📝 技术细节

### 客户端渲染库选择

1. **plantuml-encoder** (npm)
   - 用于编码 PlantUML 代码
   - 大小：~10KB

2. **plantuml.js** (npm)
   - 浏览器端 PlantUML 渲染器
   - 大小：~2-3MB（可压缩）
   - 支持大部分 PlantUML 特性

3. **@plantuml/plantuml-encoder** (npm)
   - 官方编码库
   - 更可靠

### 构建时渲染工具

1. **plantuml.jar**
   - Java 版本，功能最全
   - 需要 Java 环境

2. **node-plantuml**
   - Node.js 版本
   - 更轻量

3. **Docker 镜像**
   - `plantuml/plantuml-server` 官方镜像
   - 环境隔离，易于使用

---

## ⚠️ 注意事项

1. **文件大小**：客户端渲染库会增加页面大小，建议使用 CDN 或压缩
2. **浏览器兼容**：确保目标浏览器支持所需的 JavaScript 特性
3. **性能优化**：复杂图表可能需要较长时间渲染，考虑添加加载提示
4. **错误处理**：需要完善的错误处理和回退机制

---

## 🚀 下一步行动

1. **评估当前需求**：确定需要渲染的 PlantUML 图表数量和复杂度
2. **选择方案**：根据需求选择客户端渲染或构建时预渲染
3. **实施测试**：在测试环境验证方案可行性
4. **逐步迁移**：逐步替换现有远程渲染方案

---

## 📚 参考资源

- [Kroki.io 官网](https://kroki.io/)
- [Kroki GitHub](https://github.com/yuzutech/kroki)
- [PlantUML 官网](https://plantuml.com/)
- [plantuml-encoder npm](https://www.npmjs.com/package/plantuml-encoder)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

**评估日期**：2025-11-10  
**评估人**：AI Assistant  
**状态**：待实施
