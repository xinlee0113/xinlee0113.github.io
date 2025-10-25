---
layout: default
title: Settings编译脚本使用说明
parent: 开发工具
nav_order: 1
---

# Settings 编译和安装脚本使用说明

## 📦 脚本文件

### 1. `make_settings.sh` - 编译脚本
负责同步代码和编译 Settings APK

### 2. `install_settings.sh` - 安装启动脚本
负责安装 Settings APK 到设备并启动

---

## 🚀 快速开始

### 最常用的工作流程

```bash
# 1. 同步最新代码并完整编译（首次使用或解决问题）
./make_settings.sh --full --sync

# 2. 安装到设备并启动
./install_settings.sh
```

---

## 📖 详细使用说明

### 编译脚本 (make_settings.sh)

#### 基本用法

```bash
# 快速编译（默认，2-5分钟）⚡
./make_settings.sh

# 完整编译（45分钟）
./make_settings.sh --full

# 同步代码后快速编译
./make_settings.sh --sync

# 同步代码后完整编译（推荐用于解决问题）
./make_settings.sh --full --sync

# 查看帮助
./make_settings.sh --help
```

#### 编译模式对比

| 模式 | 命令 | 耗时 | 适用场景 |
|------|------|------|---------|
| 快速编译 | `./make_settings.sh` | 2-5分钟 | 日常开发，改了少量代码 |
| 完整编译 | `./make_settings.sh --full` | 45分钟 | 首次编译，依赖变更 |
| 同步+快速 | `./make_settings.sh --sync` | 5-10分钟 | 代码有更新，快速验证 |
| 同步+完整 | `./make_settings.sh --full --sync` | 50分钟 | 解决编译问题的最佳选择 |

#### 自动功能

- ✅ **自动检测设备**：连接设备后自动识别产品型号
- ✅ **智能选择编译目标**：根据设备自动选择 lunch target
- ✅ **代码同步**：自动同步 Settings 相关的 5 个依赖模块
- ✅ **错误处理**：编译失败自动回退到默认配置

---

### 安装脚本 (install_settings.sh)

#### 基本用法

```bash
# 安装并启动 Settings
./install_settings.sh

# 查看帮助
./install_settings.sh --help
```

#### 自动功能

- ✅ **设备信息检测**：显示设备型号、芯片平台、MIUI版本等
- ✅ **APK匹配验证**：检查编译的APK是否与设备匹配
- ✅ **智能安装方式**：
  - 优先使用轻量级更新（只杀进程，5秒）
  - 失败时自动降级为重启系统服务（15秒）
  - 首次使用自动处理 overlayfs 重启
- ✅ **安装验证**：检查安装状态、版本信息、APK路径
- ✅ **自动启动**：安装成功后自动启动 Settings 并验证进程

---

## 🔧 Settings 依赖模块

脚本会自动同步以下模块（使用 `--sync` 参数时）：

1. `platform/packages/apps/MiuiSettingsAosp` - Settings 主模块
2. `platform/packages/apps/MiuiSettings` - MIUI Settings 定制
3. `platform/packages/apps/MiuiSystemUISettings` - SystemUI 设置集成
4. `platform/packages/apps/SettingsCommon` - Settings 通用库
5. `platform/packages/apps/MiuiSettingsLib` - Settings 基础库

---

## 💡 使用场景和建议

### 场景1：日常开发（修改了代码）

```bash
# 快速编译（只改了几行代码）
./make_settings.sh

# 安装测试
./install_settings.sh
```

**耗时**：约 3-8 分钟

---

### 场景2：首次编译项目

```bash
# 同步代码并完整编译
./make_settings.sh --full --sync

# 安装测试
./install_settings.sh
```

**耗时**：约 50 分钟

---

### 场景3：出现编译问题（如 ClassCastException）

```bash
# 1. 清理编译缓存
rm -rf out/target/product/missi/obj/APPS/Settings_intermediates
rm -rf out/target/product/missi/system_ext/priv-app/Settings

# 2. 同步代码并完整重新编译
./make_settings.sh --full --sync

# 3. 安装测试
./install_settings.sh
```

**耗时**：约 50 分钟

---

### 场景4：代码有更新（拉取了最新代码）

```bash
# 同步依赖并快速编译
./make_settings.sh --sync

# 安装测试
./install_settings.sh
```

**耗时**：约 5-10 分钟

---

### 场景5：只重新安装（不编译）

```bash
# 直接安装已编译的 APK
./install_settings.sh
```

**耗时**：约 10-30 秒

---

## 🎯 ninja vs make 编译对比

### ninja 快速编译

**原理**：直接使用预生成的 .ninja 文件，跳过依赖检查

**优点**：
- ⚡ 速度快（2-5分钟）
- 适合日常开发

**缺点**：
- ❌ 不检查依赖变化
- ❌ 可能导致不一致（如 ClassCastException）

**适用场景**：
- 只改了 Settings 自己的代码
- 修改量小（几行到几十行）
- 没有依赖库变更

---

### make 完整编译

**原理**：完整检查所有依赖，重新生成 .ninja 文件

**优点**：
- ✅ 保证一致性
- ✅ 重新检查依赖
- ✅ 解决大部分编译问题

**缺点**：
- 🐌 速度慢（45分钟）

**适用场景**：
- 首次编译
- 依赖库有变更
- 出现类型转换等奇怪错误
- Android SDK 升级

---

## ⚠️ 常见问题

### Q1: ClassCastException 错误

**现象**：Settings 启动后返回桌面或开机引导界面

**原因**：增量编译导致代码不一致

**解决方案**：
```bash
rm -rf out/target/product/missi/obj/APPS/Settings_intermediates
rm -rf out/target/product/missi/system_ext/priv-app/Settings
./make_settings.sh --full --sync
```

---

### Q2: APK 与设备不匹配

**现象**：脚本警告 "APK 编译产品与设备产品不匹配"

**原因**：编译的产品与当前设备不一致

**解决方案**：
```bash
# 脚本会自动检测设备并选择正确的编译目标
# 重新编译即可
./make_settings.sh --sync
```

---

### Q3: 安装失败 "not updateable"

**现象**：`adb install` 报错 "Package com.android.settings are not updateable"

**原因**：Settings 是系统应用，不能用普通安装方式

**解决方案**：脚本已自动处理，使用 `adb push` 方式安装

---

### Q4: overlayfs 需要重启

**现象**：首次使用时提示 "Now reboot your device"

**原因**：系统需要启用 overlayfs

**解决方案**：脚本会自动重启设备，等待约 1 分钟

---

## 📊 脚本特性总结

### make_settings.sh

| 特性 | 说明 |
|------|------|
| 代码同步 | 自动同步 5 个依赖模块 |
| 设备检测 | 自动识别设备并选择编译目标 |
| 智能编译 | 支持 ninja 快速编译和 make 完整编译 |
| 错误处理 | 编译失败自动回退 |
| 进度显示 | 彩色日志 + 耗时统计 |

### install_settings.sh

| 特性 | 说明 |
|------|------|
| 设备检测 | 显示完整设备信息（型号、芯片、版本等）|
| APK匹配 | 验证 APK 与设备是否匹配 |
| 智能安装 | 自动选择最优安装方式 |
| 安装验证 | 检查包状态、版本、路径 |
| 自动启动 | 启动 Settings 并验证进程和界面 |

---

## 🔄 推荐工作流程

```bash
# 🌅 早上开始工作
./make_settings.sh --sync          # 同步最新代码并编译
./install_settings.sh              # 安装测试

# 💻 日常开发
# ... 修改代码 ...
./make_settings.sh                 # 快速编译
./install_settings.sh              # 安装测试

# 🐛 遇到问题时
./make_settings.sh --full --sync   # 完整重新编译
./install_settings.sh              # 安装测试

# 🌙 下班前
git add .
git commit -m "xxx"
git push
```

---

## 📝 注意事项

1. **首次使用建议**：`./make_settings.sh --full --sync`
2. **日常开发**：`./make_settings.sh` （快速编译）
3. **出现问题**：`./make_settings.sh --full --sync` （完整编译）
4. **设备要求**：需要 root 权限，开启 USB 调试
5. **编译环境**：确保已执行 `source build/envsetup.sh`

---

## 🎉 总结

- ⚡ **快速**：ninja 编译只需 2-5 分钟
- 🔧 **智能**：自动检测设备，自动选择编译目标
- 🔄 **完整**：支持代码同步，确保依赖最新
- ✅ **可靠**：完整编译解决一切问题
- 🚀 **方便**：一键编译 + 一键安装

**Happy Coding!** 🎈



