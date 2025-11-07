---
layout: default
title: Winscope使用手册
parent: 开发工具
nav_order: 5
---

# Winscope使用手册

## 文档信息
- **版本**: v1.0
- **创建日期**: 2025-01-XX
- **适用范围**: Android系统窗口和Surface调试
- **工具说明**: Winscope是Android官方提供的窗口和Surface分析工具，用于调试窗口层级、动画、SurfaceFlinger等问题

---

## 工具概述

Winscope（Window Scope）是Android开发者工具集的一部分，主要用于：
- 分析窗口层级结构
- 调试窗口动画问题
- 追踪SurfaceFlinger事件
- 分析窗口焦点和可见性
- 调试窗口透明度、位置、大小等属性

---

## 核心功能

### 1. 窗口层级分析（Window Hierarchy）
- 查看所有窗口的层级关系
- 分析窗口Z-order顺序
- 检查窗口显示状态（可见性、焦点状态）
- 查看窗口属性（透明度、位置、大小）

### 2. 窗口动画追踪（Window Animation）
- 捕获窗口过渡动画
- 分析动画性能问题
- 调试动画卡顿或异常
- 查看动画轨迹和时序

### 3. SurfaceFlinger事件追踪
- 追踪Surface创建和销毁
- 分析合成器（Composer）事件
- 调试显示刷新问题
- 查看Buffer队列状态

### 4. 窗口属性监控
- 实时监控窗口属性变化
- 追踪焦点切换
- 分析窗口可见性变化
- 调试窗口裁剪区域

---

## 解决的问题

### 1. 窗口显示问题
- **问题**: 窗口不显示、部分显示、位置错误
- **解决**: 通过窗口层级分析，找到窗口被遮挡、层级错误、裁剪区域不正确等问题

### 2. 窗口动画问题
- **问题**: 动画卡顿、不流畅、异常跳转
- **解决**: 通过动画追踪，分析动画时序、帧率、轨迹异常

### 3. 窗口焦点问题
- **问题**: 焦点切换不正确、键盘无法输入
- **解决**: 通过焦点事件追踪，找到焦点切换逻辑错误

### 4. 窗口层级问题
- **问题**: 窗口被遮挡、显示顺序错误
- **解决**: 通过层级分析，找到Z-order设置错误

### 5. Surface相关问题
- **问题**: 黑屏、花屏、显示异常
- **解决**: 通过SurfaceFlinger事件分析，找到Surface创建、更新、合成问题

### 6. 多窗口/分屏问题
- **问题**: 分屏窗口显示异常、多窗口交互问题
- **解决**: 通过窗口层级和属性分析，找到多窗口配置问题

---

## 快速开始（Web界面）

### 方式1：启动开发服务器（推荐用于开发调试）

```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm start
```

启动后会自动打开浏览器访问 `http://localhost:8080/`

### 方式2：使用生产构建版本

如果已经运行了 `npm run build:prod`，可以启动一个简单的HTTP服务器：

```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope/dist/prod
python3 -m http.server 8080
# 或使用Node.js
npx serve -p 8080
```

然后在浏览器访问 `http://localhost:8080/`

### Web界面使用

打开浏览器后，Winscope界面提供两种方式获取追踪数据：

#### 方式A：收集痕迹（实时录制）

**步骤1：启动Winscope ADB代理**

在终端运行（需要Python 3.10+和ADB）：

```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
python3 src/adb/winscope_proxy.py
```

代理启动后会显示类似输出：
```
Winscope token: 10066d0f85ed857215dd4fb9099b490e0c719cae0a7353de9b75cc17a4c438ca
Starting Winscope proxy server on port 5544...
```

**步骤2：获取并配置Token**

Token是连接Winscope代理的身份验证凭证，有四种获取方式：

**方式1：从代理启动输出中获取**

代理启动时会在终端输出Token，直接复制即可。

**方式2：使用一键启动脚本**

```bash
# 仅获取Token，不启动服务
/mnt/01_lixin_workspace/scripts/start_winscope.sh --token
```

**方式3：直接查看Token文件**

```bash
cat ~/.config/winscope/.token
```

Token文件位置：`~/.config/winscope/.token`

**方式4：从代理日志中获取**

```bash
tail -f /tmp/winscope_logs/winscope_proxy.log
```

Token会自动保存到 `~/.config/winscope/.token` 文件中，首次启动代理时自动生成。

**步骤3：在Web界面输入Token**

- 在左侧"收集痕迹"面板中
- 找到"Enter Winscope proxy token"输入框
- 粘贴刚才获取的Token（64个十六进制字符）
- 点击"Connect"按钮连接代理
- 连接成功后，界面会显示"Select a device:"

**步骤4：选择要录制的内容**

- Window Manager（窗口管理器）
- SurfaceFlinger（Surface合成器）
- Transitions（窗口过渡动画）

**步骤5：点击"开始录制"**

- 在设备上复现问题
- 录制完成后点击"停止"

**步骤6：自动分析**

- 追踪数据会自动加载到分析界面

#### 方式B：上传轨迹文件（离线分析）

**步骤1：准备.winscope文件**

- 从设备导出的.winscope文件
- 或之前保存的追踪文件

**步骤2：上传文件**

- 在右侧"上传轨迹"面板中
- 拖放.winscope文件到上传区域
- 或点击上传区域选择文件

**步骤3：自动加载分析**

- 文件上传后自动加载到分析界面

---

## 使用步骤（详细版）

### 第一步：环境准备

#### 1.1 安装Winscope工具

```bash
# 方式1：通过Android Studio安装
# Android Studio -> Tools -> SDK Manager -> SDK Tools
# 勾选 "Winscope" 并安装

# 方式2：直接从源码编译（需要Android源码环境）
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm install
npm run build:prod
```

#### 1.2 确认设备连接

```bash
# 检查ADB连接
adb devices

# 确认设备已连接并授权
List of devices attached
e229623c	device
```

#### 1.3 启动Winscope

**开发模式（推荐）：**
```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm start
# 自动打开 http://localhost:8080/
```

**生产模式：**
```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope/dist/prod
python3 -m http.server 8080
# 然后访问 http://localhost:8080/
```

#### 1.4 Token生成和配置

**什么是Token？**

Token是Winscope代理服务器的身份验证凭证，用于确保Web界面与代理服务器之间的安全连接。Token是一个64位的十六进制字符串。

**Token存储位置**

Token自动保存在用户配置目录中：
```
~/.config/winscope/.token
```

**Token生成机制**

1. **首次启动代理时自动生成**：当第一次运行 `winscope_proxy.py` 时，如果Token文件不存在，代理会自动生成一个新的Token并保存到文件中。

2. **Token重用**：如果Token文件已存在，代理会读取并使用现有的Token，不会重新生成。

3. **Token格式**：Token是使用 `secrets.token_hex(32)` 生成的256位随机十六进制字符串。

**获取Token的方法**

**方法1：从代理启动输出获取**

启动代理时，Token会显示在终端输出中：

```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
python3 src/adb/winscope_proxy.py
```

输出示例：
```
Winscope token: 10066d0f85ed857215dd4fb9099b490e0c719cae0a7353de9b75cc17a4c438ca
Starting Winscope proxy server on port 5544...
```

**方法2：使用一键启动脚本**

```bash
# 仅获取Token，不启动服务
/mnt/01_lixin_workspace/scripts/start_winscope.sh --token
```

输出示例：
```
==========================================
[SUCCESS] Winscope Token 获取成功
==========================================

🔑 Token: 10066d0f85ed857215dd4fb9099b490e0c719cae0a7353de9b75cc17a4c438ca

💡 使用方法:
  1. 在 Winscope Web 界面中找到 'Enter Winscope proxy token' 输入框
  2. 复制上面的 Token 并粘贴到输入框
  3. 点击 'Connect' 按钮连接代理

📋 快速复制命令:
  echo "10066d0f85ed857215dd4fb9099b490e0c719cae0a7353de9b75cc17a4c438ca" | xclip -selection clipboard
  或者手动复制上面的 Token
```

**方法3：直接查看Token文件**

```bash
cat ~/.config/winscope/.token
```

**方法4：从代理日志中获取**

如果使用一键启动脚本，Token会记录在日志文件中：

```bash
tail -f /tmp/winscope_logs/winscope_proxy.log
```

**在Web界面中配置Token**

1. **打开Winscope Web界面**
   - 访问 `http://localhost:8080/`
   - 确保代理已启动

2. **找到Token输入框**
   - 在左侧"收集痕迹"面板中
   - 查找"Enter Winscope proxy token"或"Winscope proxy token"输入框
   - 如果代理未连接，会显示"Proxy authorization required"

3. **输入Token**
   - 复制获取的Token（完整64个字符）
   - 粘贴到输入框中
   - 确保没有多余的空格或换行符

4. **连接代理**
   - 点击"Connect"按钮
   - 连接成功后，界面会显示"Select a device:"
   - 如果Token错误，会显示"Bad token"错误

**Token验证机制**

- Web界面通过HTTP请求头 `Winscope-Token` 发送Token
- 代理服务器验证Token是否与保存的Token匹配
- 验证通过后，允许Web界面访问代理的API接口

**常见问题**

**Q1: Token验证失败怎么办？**

如果遇到"Bad token"错误：

1. 检查Token是否正确复制（64个字符，无空格）
2. 确认代理正在运行
3. 确认Token文件中的Token与代理使用的Token一致
4. 如果问题持续，可以删除Token文件重新生成：
   ```bash
   rm ~/.config/winscope/.token
   # 重新启动代理时会自动生成新Token
   ```

**Q2: Token文件不存在怎么办？**

如果Token文件不存在：

1. 启动代理会自动生成Token文件
2. 或手动创建目录和文件：
   ```bash
   mkdir -p ~/.config/winscope
   python3 -c "import secrets; print(secrets.token_hex(32))" > ~/.config/winscope/.token
   ```

**Q3: 如何更新Token？**

如果需要更新Token：

```bash
# 方法1：删除旧Token文件，重新启动代理
rm ~/.config/winscope/.token
python3 src/adb/winscope_proxy.py

# 方法2：手动生成新Token
python3 -c "import secrets; print(secrets.token_hex(32))" > ~/.config/winscope/.token
```

**Q4: Token是否可以多人共享？**

可以，但需要注意安全：

- 同一Token文件可以被多个Web界面客户端使用
- 建议仅在内网环境中共享Token
- 不要将Token泄露到公共网络

**Q5: Token的有效期是多久？**

Token没有有效期限制，会一直有效直到：
- Token文件被删除
- 手动更新Token
- 重新生成Token文件

### 第二步：开始录制

#### 2.1 打开录制界面

启动Winscope后，界面会显示录制选项：
- Window Manager（窗口管理器）
- SurfaceFlinger（Surface合成器）
- Transitions（窗口过渡动画）

#### 2.2 选择录制类型

根据问题类型选择要录制的内容：

**窗口层级问题**：
- 勾选 Window Manager
- 勾选 Transitions（用于分析窗口切换）

**Surface显示问题**：
- 勾选 SurfaceFlinger
- 勾选 Window Manager（关联窗口信息）

**动画问题**：
- 勾选 Transitions
- 勾选 Window Manager

#### 2.3 开始录制

```bash
# 方式1：通过界面操作
# 点击 "Record" 按钮

# 方式2：通过命令行
winscope record --window-manager --transitions
```

录制开始后，Winscope会：
1. 连接到目标设备
2. 开始捕获窗口和Surface事件
3. 界面显示录制状态（正在录制中）

### 第三步：复现问题

在设备上执行能复现问题的操作：
- 打开应用
- 切换窗口
- 触发动画
- 执行能引起问题的操作

建议操作时间：
- 窗口层级问题：5-10秒足够
- 动画问题：完整动画周期即可
- 复杂问题：10-30秒

### 第四步：停止录制并分析

#### 4.1 停止录制

```bash
# 方式1：通过界面操作
# 点击 "Stop" 按钮

# 方式2：通过命令行快捷键
# 按 Ctrl+C（如果在命令行模式）
```

#### 4.2 查看录制结果

停止录制后，Winscope会自动打开分析界面，显示：

**窗口层级视图**：
- 以树形结构显示所有窗口
- 每个窗口显示：包名、窗口类型、层级、可见性等
- 可以展开/折叠查看窗口层级

**时间线视图**：
- 显示窗口事件的时间线
- 包括：创建、销毁、显示、隐藏、焦点切换等
- 可以拖动时间轴查看不同时刻的状态

**动画轨迹视图**：
- 显示窗口动画的轨迹
- 可以播放动画，查看每一帧的状态

#### 4.3 关键分析功能

**窗口筛选**：
```
# 通过包名筛选
输入: com.android.provision

# 通过窗口类型筛选
选择: Application Window

# 通过层级筛选
输入: z-order > 1000
```

**时间点定位**：
```
# 拖动时间轴到问题发生时刻
# 查看该时刻的窗口状态

# 或使用时间跳转
输入时间: 00:05.123
```

**窗口属性查看**：
```
# 点击窗口节点
# 查看详细属性：
- 位置：x, y, width, height
- 层级：z-order, layer
- 状态：visible, focused, drawn
- 标志：FLAG_xxx
```

**事件详情**：
```
# 点击时间线上的事件
# 查看事件详情：
- 事件类型
- 触发时间
- 相关窗口
- 事件参数
```

### 第五步：导出和分析

#### 5.1 导出数据

```bash
# 导出为文件
File -> Export -> Window Hierarchy (JSON)
File -> Export -> Timeline (CSV)

# 保存截图
File -> Save Screenshot
```

#### 5.2 分析方法

**窗口层级问题分析**：
1. 找到问题窗口节点
2. 检查窗口层级（z-order）是否正确
3. 检查父窗口是否遮挡
4. 检查窗口裁剪区域
5. 对比正常情况下的层级结构

**动画问题分析**：
1. 找到动画时间线
2. 检查动画起始和结束状态
3. 分析动画帧率（是否掉帧）
4. 检查动画轨迹是否异常
5. 对比正常动画的时序

**Surface问题分析**：
1. 查看SurfaceFlinger事件时间线
2. 检查Surface创建/销毁顺序
3. 分析Buffer提交频率
4. 检查合成器事件

---

## 典型使用场景

### 场景1：窗口不显示问题

**问题描述**：应用窗口打开后不显示

**分析步骤**：
1. 录制从打开应用到窗口应该显示的过程
2. 在窗口层级视图中查找应用窗口
3. 检查窗口属性：
   - `visible = false` → 窗口未设置为可见
   - `z-order` 太低 → 被其他窗口遮挡
   - `alpha = 0` → 窗口完全透明
   - `width/height = 0` → 窗口大小为0
4. 查看时间线，找到窗口创建和显示事件
5. 检查是否有隐藏窗口的事件

**常见根因**：
- 窗口FLAG未正确设置
- 窗口层级设置错误
- 窗口被其他窗口遮挡
- 窗口透明度设置错误

### 场景2：窗口动画卡顿

**问题描述**：窗口切换动画不流畅

**分析步骤**：
1. 录制包含动画的操作过程
2. 在动画轨迹视图中查看动画
3. 检查动画帧率（FPS）
4. 分析动画每一帧的时间间隔
5. 找到卡顿的时间点
6. 查看该时间点的系统事件

**常见根因**：
- 主线程阻塞
- Surface更新不及时
- Buffer队列阻塞
- 系统资源紧张

### 场景3：窗口焦点问题

**问题描述**：点击窗口后焦点未切换

**分析步骤**：
1. 录制点击操作过程
2. 查看时间线上的焦点事件
3. 检查焦点切换顺序
4. 对比点击事件和焦点事件的时间
5. 检查窗口的焦点标志（FLAG_NOT_FOCUSABLE等）

**常见根因**：
- 窗口设置了FLAG_NOT_FOCUSABLE
- 窗口未获得焦点权限
- 焦点切换逻辑错误

### 场景4：多窗口显示异常

**问题描述**：分屏模式下窗口显示位置错误

**分析步骤**：
1. 录制进入分屏模式的过程
2. 查看分屏窗口的层级关系
3. 检查每个窗口的位置和大小
4. 查看窗口裁剪区域
5. 对比正常分屏的窗口配置

**常见根因**：
- 窗口位置计算错误
- 窗口大小未适配分屏
- 窗口裁剪区域设置错误

---

## 注意事项

### 1. 性能影响

**录制对性能的影响**：
- Winscope录制会消耗一定的系统资源
- 可能影响动画流畅度
- 建议只在调试时使用

**优化建议**：
- 录制时间尽量短（5-30秒）
- 只录制必要的事件类型
- 避免在高负载场景下录制

### 2. 数据准确性

**时间戳问题**：
- Winscope的时间戳是相对时间（从录制开始）
- 与系统日志时间可能不完全对齐
- 需要结合logcat日志分析

**事件捕获**：
- 某些快速事件可能被遗漏
- 事件顺序是准确的，但时间间隔可能有误差
- 建议结合系统日志验证

### 3. 设备兼容性

**Android版本要求**：
- Android 9.0 (API 28)及以上版本支持完整功能
- 低版本可能功能受限
- 部分功能需要root权限

**权限要求**：
- 需要USB调试权限
- 部分功能需要root权限
- 需要设备支持开发者选项

### 4. 录制时机

**开始录制的时机**：
- 在问题复现前就开始录制
- 确保捕获到完整的初始化过程
- 避免错过关键事件

**停止录制的时机**：
- 问题复现后立即停止
- 避免录制过多无关数据
- 保留问题发生后的少量时间用于分析

### 5. 数据解读

**窗口层级解读**：
- Z-order越大，窗口越靠前
- 子窗口的层级相对于父窗口
- 某些系统窗口可能不在层级树中

**时间线解读**：
- 事件顺序是准确的
- 时间间隔可能有误差（毫秒级）
- 需要结合代码逻辑分析

### 6. 常见误区

**误区1：只看窗口层级**
- 窗口不显示可能是其他原因（透明度、大小等）
- 需要综合查看多个属性

**误区2：忽略时间线**
- 窗口层级是静态的，时间线显示动态变化
- 问题可能发生在某个时间点

**误区3：不对比正常情况**
- 只有对比正常和异常情况，才能找到差异
- 建议同时录制正常场景作为参考

---

## 编译故障排除

### 问题1：编译失败 - 类型转换错误

**错误信息**：
```
error: implicit conversion changes signedness: 'int' to 'uint32_t' 
[-Werror,-Wsign-conversion]
```

**原因**：
- Perfetto依赖项编译时启用了严格的类型检查
- `-Weverything` 和 `-Werror` 标志将警告当作错误
- 代码中存在隐式类型转换（int到uint32_t）

**解决方案**：

**方案1：修改构建配置（推荐）**

修改Perfetto的构建配置文件，禁用sign-conversion警告：

文件位置：`external/perfetto/gn/standalone/BUILD.gn`

在第103行附近添加：
```gn
"-Wno-sign-conversion",  # Disable sign conversion warnings
```

修改后的配置应该类似：
```gn
cflags += [
  "-Wno-unknown-sanitizers",
  "-Wno-unknown-warning-option",
  "-Wno-unsafe-buffer-usage",
  "-Wno-sign-conversion",  # Disable sign conversion warnings
  
  "-Wno-switch-default",
]
```

然后重新编译：
```bash
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm run build:prod
```

**方案2：使用预编译版本**

如果不想修改源码，可以使用预编译的Perfetto版本：
- 从官方下载预编译的trace_processor
- 或使用Docker镜像

**方案3：临时禁用警告（不推荐）**

临时设置环境变量（仅用于测试）：
```bash
export CXXFLAGS="-Wno-sign-conversion"
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm run build:prod
```

### 问题2：编译失败 - 缺少依赖

**错误信息**：
```
error: 'xxx' file not found
```

**解决方案**：
```bash
# 安装构建依赖
cd /mnt/01_lixin_workspace/master-w/external/perfetto
tools/install-build-deps --ui

# 安装Node.js依赖
cd /mnt/01_lixin_workspace/master-w/development/tools/winscope
npm install
```

### 问题3：编译失败 - 内存不足

**错误信息**：
```
terminate called after throwing an instance of 'std::bad_alloc'
```

**解决方案**：
- 增加交换空间
- 减少并行编译线程数
- 清理临时文件释放空间

### 问题4：编译失败 - 权限问题

**错误信息**：
```
Permission denied
```

**解决方案**：
- 检查文件权限
- 确保有写入权限
- 使用sudo（如需要）

---

## 常见问题FAQ

### Q1: Winscope无法连接到设备？

**原因**：
- ADB未连接
- USB调试未开启
- 设备未授权

**解决**：
```bash
# 检查ADB连接
adb devices

# 重新连接设备
adb kill-server
adb start-server
adb devices
```

### Q2: 录制过程中设备卡顿？

**原因**：
- 录制事件过多
- 系统资源紧张

**解决**：
- 减少录制事件类型
- 缩短录制时间
- 关闭其他占用资源的应用

### Q3: 窗口层级树中找不到目标窗口？

**原因**：
- 窗口可能在录制开始前就已创建
- 窗口可能不在当前显示的层级中
- 窗口类型不在捕获范围内

**解决**：
- 更早开始录制
- 检查窗口类型筛选
- 查看所有窗口类型

### Q4: 时间线事件不完整？

**原因**：
- 缓冲区溢出
- 录制时间过长
- 事件过多

**解决**：
- 缩短录制时间
- 分段录制
- 只选择必要的事件类型

### Q5: 动画轨迹不准确？

**原因**：
- 采样频率不够
- 动画太快

**解决**：
- 使用慢动作复现
- 增加采样频率（如果支持）

---

## 最佳实践

### 1. 录制前准备

- 确保设备连接稳定
- 关闭不必要的应用
- 明确要分析的问题
- 准备复现步骤

### 2. 录制过程

- 在问题复现前开始录制
- 执行完整的复现步骤
- 问题复现后立即停止
- 记录关键时间点

### 3. 分析过程

- 先看整体结构，再看细节
- 对比正常和异常情况
- 结合代码逻辑分析
- 验证分析结论

### 4. 问题定位

- 从窗口层级开始
- 查看关键时间点
- 分析事件序列
- 综合多个视角

### 5. 文档记录

- 保存关键的层级截图
- 记录问题时间点
- 记录分析结论
- 保存导出数据

---

## 相关资源

### 官方文档
- Android官方文档：https://developer.android.com/topic/performance/winscope
- GitHub仓库：https://github.com/android/winscope

### 相关工具
- **Perfetto**：系统性能分析工具
- **Systrace**：系统调用追踪工具
- **GPU Profile**：GPU性能分析工具

### 相关命令
```bash
# 窗口相关ADB命令
adb shell dumpsys window windows
adb shell dumpsys window displays
adb shell dumpsys SurfaceFlinger

# 日志相关
adb logcat | grep -i window
adb logcat | grep -i surface
```

---

## 总结

Winscope是Android窗口和Surface调试的强大工具，通过合理使用可以快速定位：
- 窗口显示问题
- 动画性能问题
- 窗口焦点问题
- Surface相关问题

关键要点：
1. 正确选择录制类型
2. 把握好录制时机
3. 综合多个视角分析
4. 结合代码和日志验证

熟练掌握Winscope可以大大提高窗口相关问题的调试效率。
