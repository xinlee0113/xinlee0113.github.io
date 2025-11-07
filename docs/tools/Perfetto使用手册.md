---
layout: default
title: Perfetto使用手册
parent: 开发工具
nav_order: 4
---

# Perfetto使用手册

## 文档信息
- **版本**: v1.0
- **创建日期**: 2025-01-XX
- **适用范围**: Android系统性能分析和调试
- **工具说明**: Perfetto是Google开发的下一代性能分析工具，替代Systrace，用于系统级性能追踪和分析

---

## 工具概述

Perfetto是Android系统性能分析的综合工具，由Google开发，用于：
- 系统级性能追踪
- CPU、内存、I/O性能分析
- 应用程序性能分析
- 系统调用追踪
- 帧率分析和渲染性能
- 网络性能分析
- 电量消耗分析

---

## 核心功能

### 1. 系统追踪（System Tracing）
- 追踪CPU调度和性能
- 追踪进程和线程活动
- 追踪内核事件
- 追踪Binder调用
- 追踪内存分配和释放

### 2. 应用性能分析（App Performance）
- 追踪应用启动时间
- 分析应用主线程性能
- 追踪UI渲染性能
- 分析内存使用情况
- 追踪网络请求

### 3. 帧率分析（Frame Rate）
- 分析界面刷新率
- 追踪丢帧情况
- 分析渲染性能
- 调试卡顿问题

### 4. 内存分析（Memory）
- 追踪内存分配
- 分析内存泄漏
- 追踪GC事件
- 分析内存增长趋势

### 5. 电量分析（Power）
- 追踪CPU频率变化
- 分析唤醒锁（Wake Lock）
- 追踪传感器使用
- 分析后台活动

### 6. 网络分析（Network）
- 追踪网络请求
- 分析网络延迟
- 追踪DNS解析
- 分析数据传输

---

## 解决的问题

### 1. 应用卡顿问题
- **问题**: 应用界面卡顿、响应慢
- **解决**: 通过CPU调度追踪，找到主线程阻塞、耗时操作、锁竞争等问题

### 2. 应用启动慢
- **问题**: 应用启动时间过长
- **解决**: 通过启动追踪，分析启动流程中的耗时操作，优化启动逻辑

### 3. 内存泄漏问题
- **问题**: 应用内存持续增长，最终OOM
- **解决**: 通过内存追踪，找到未释放的对象、内存泄漏点

### 4. 帧率问题
- **问题**: 界面刷新率低、掉帧
- **解决**: 通过帧率追踪，找到渲染瓶颈、GPU性能问题

### 5. 耗电问题
- **问题**: 应用耗电量大
- **解决**: 通过电量追踪，找到CPU高频运行、唤醒锁持有时间过长等问题

### 6. 系统性能问题
- **问题**: 系统整体性能下降
- **解决**: 通过系统级追踪，找到系统资源竞争、进程调度问题

### 7. 网络性能问题
- **问题**: 网络请求慢、超时
- **解决**: 通过网络追踪，分析网络延迟、DNS解析、数据传输问题

---

## 使用步骤

### 第一步：环境准备

#### 1.1 安装Perfetto工具

**方式1：通过Web界面（推荐）**
```
直接在浏览器访问：https://ui.perfetto.dev/
无需安装，打开即用
```

**方式2：命令行工具**
```bash
# 下载perfetto命令行工具
# 从 https://github.com/google/perfetto/releases 下载

# 解压并添加到PATH
unzip perfetto-linux-x86_64.zip
export PATH=$PATH:$(pwd)/perfetto/bin
```

**方式3：Android Studio集成**
```
Android Studio -> Profiler -> System Trace
自动使用Perfetto引擎
```

#### 1.2 确认设备连接

```bash
# 检查ADB连接
adb devices

# 确认设备已连接
List of devices attached
e229623c	device
```

#### 1.3 检查设备支持

```bash
# 检查设备是否支持Perfetto
adb shell perfetto --help

# 如果命令不存在，可能需要：
# 1. Android 9.0 (API 28)及以上版本
# 2. 启用开发者选项
# 3. 安装Perfetto HAL
```

### 第二步：配置追踪

#### 2.1 基本配置

Perfetto使用配置文件（.txt格式）定义追踪内容：

**创建配置文件 trace_config.txt**：
```text
buffers: {
    size_kb: 63488
    fill_policy: DISCARD
}

data_sources: {
    config {
        name: "linux.ftrace"
        target_buffer: 0
        ftrace_config {
            ftrace_events: "sched/sched_switch"
            ftrace_events: "sched/sched_waking"
            ftrace_events: "power/suspend_resume"
            ftrace_events: "power/cpu_frequency"
            ftrace_events: "power/cpu_idle"
            ftrace_events: "power/gpu_frequency"
            ftrace_events: "irq/irq_handler_entry"
            ftrace_events: "irq/irq_handler_exit"
            ftrace_events: "irq/softirq_entry"
            ftrace_events: "irq/softirq_exit"
            atrace_categories: "gfx"
            atrace_categories: "input"
            atrace_categories: "view"
            atrace_categories: "webview"
            atrace_categories: "wm"
            atrace_categories: "am"
            atrace_categories: "sm"
            atrace_categories: "audio"
            atrace_categories: "video"
            atrace_categories: "camera"
            atrace_categories: "hal"
            atrace_categories: "app"
            atrace_categories: "res"
            atrace_categories: "dalvik"
            atrace_categories: "rs"
            atrace_categories: "bionic"
            atrace_categories: "power"
            atrace_categories: "pm"
            atrace_categories: "ss"
            atrace_categories: "database"
            atrace_categories: "network"
            atrace_categories: "adb"
            atrace_categories: "vibrator"
            atrace_categories: "aidl"
            atrace_categories: "nnapi"
            atrace_categories: "binder_driver"
            atrace_categories: "binder_lock"
            atrace_categories: "disk"
            atrace_categories: "mmc"
            atrace_categories: "load"
            atrace_categories: "sync"
            atrace_categories: "workq"
            atrace_categories: "memreclaim"
            atrace_categories: "regulators"
            atrace_categories: "binder"
            atrace_categories: "idle"
            atrace_categories: "sched"
        }
    }
    config {
        name: "linux.process_stats"
        target_buffer: 0
        process_stats_config {
            scan_all_processes_on_start: true
        }
    }
    config {
        name: "android.surfaceflinger.frame"
        target_buffer: 0
    }
    config {
        name: "android.java_hprof"
        target_buffer: 0
        java_hprof_config {
            process_cmdline: "com.android.provision"
        }
    }
}

duration_ms: 10000
```

#### 2.2 常用配置模板

**卡顿分析配置**：
```text
buffers: {
    size_kb: 63488
    fill_policy: DISCARD
}

data_sources: {
    config {
        name: "linux.ftrace"
        ftrace_config {
            ftrace_events: "sched/sched_switch"
            ftrace_events: "sched/sched_waking"
            atrace_categories: "gfx"
            atrace_categories: "view"
            atrace_categories: "wm"
            atrace_categories: "am"
            atrace_categories: "app"
        }
    }
    config {
        name: "android.surfaceflinger.frame"
    }
}

duration_ms: 30000
```

**内存分析配置**：
```text
buffers: {
    size_kb: 63488
}

data_sources: {
    config {
        name: "linux.ftrace"
        ftrace_config {
            ftrace_events: "kmem/kmalloc"
            ftrace_events: "kmem/kmalloc_node"
            ftrace_events: "kmem/kfree"
            atrace_categories: "dalvik"
            atrace_categories: "memreclaim"
        }
    }
    config {
        name: "android.java_hprof"
        java_hprof_config {
            process_cmdline: "com.android.provision"
        }
    }
}

duration_ms: 60000
```

**启动时间分析配置**：
```text
buffers: {
    size_kb: 63488
}

data_sources: {
    config {
        name: "linux.ftrace"
        ftrace_config {
            atrace_categories: "am"
            atrace_categories: "app"
            atrace_categories: "gfx"
            atrace_categories: "view"
        }
    }
}

duration_ms: 15000
```

#### 2.3 配置文件说明

**关键参数**：
- `buffers.size_kb`: 缓冲区大小（KB）
- `duration_ms`: 追踪时长（毫秒）
- `fill_policy`: 缓冲区满时的策略（DISCARD/RING_BUFFER）
- `atrace_categories`: 要追踪的类别
- `ftrace_events`: 要追踪的内核事件

**常用atrace类别**：
- `gfx`: 图形渲染
- `input`: 输入事件
- `view`: View系统
- `wm`: 窗口管理
- `am`: Activity管理
- `app`: 应用程序
- `dalvik`: Dalvik虚拟机
- `power`: 电源管理
- `network`: 网络
- `disk`: 磁盘I/O

### 第三步：开始录制

#### 3.1 使用配置文件录制

```bash
# 方式1：使用配置文件录制
adb shell perfetto \
  -c - -o /data/misc/perfetto-traces/trace.perfetto-trace \
  < trace_config.txt

# 方式2：指定配置文件路径
adb push trace_config.txt /data/local/tmp/
adb shell perfetto \
  -c /data/local/tmp/trace_config.txt \
  -o /data/misc/perfetto-traces/trace.perfetto-trace
```

#### 3.2 使用Web界面录制

1. 打开 https://ui.perfetto.dev/
2. 点击 "Record new trace"
3. 选择设备
4. 选择追踪类别（或使用自定义配置）
5. 设置录制时长
6. 点击 "Start recording"

#### 3.3 使用Android Studio录制

1. 打开Android Studio
2. 连接设备
3. 打开 Profiler 窗口
4. 选择设备和应用
5. 点击 "System Trace" 按钮
6. 选择追踪类别
7. 点击 "Record" 开始录制

#### 3.4 使用命令行简化录制

```bash
# 快速录制（使用默认配置）
adb shell perfetto -t 10s -o /data/misc/perfetto-traces/trace.perfetto-trace

# 录制特定类别
adb shell perfetto \
  -t 30s \
  -o /data/misc/perfetto-traces/trace.perfetto-trace \
  -b 64mb \
  -a com.android.provision \
  -c gfx,view,input,am,app
```

**参数说明**：
- `-t`: 录制时长（如：10s, 30s, 1m）
- `-o`: 输出文件路径
- `-b`: 缓冲区大小
- `-a`: 要追踪的应用包名
- `-c`: 追踪类别（逗号分隔）

### 第四步：复现问题

在设备上执行能复现问题的操作：
- 打开应用
- 执行导致卡顿的操作
- 触发内存泄漏的操作
- 执行启动流程

**建议**：
- 在录制开始前就准备好操作步骤
- 问题复现后等待几秒再停止录制
- 记录关键操作的时间点

### 第五步：停止录制并导出

#### 5.1 停止录制

**命令行方式**：
```bash
# 如果在命令行模式，按 Ctrl+C 停止
# 或等待指定时长自动停止
```

**Web界面方式**：
- 点击 "Stop recording" 按钮

**Android Studio方式**：
- 点击 "Stop" 按钮

#### 5.2 导出追踪文件

**命令行导出**：
```bash
# 从设备拉取追踪文件
adb pull /data/misc/perfetto-traces/trace.perfetto-trace ./trace.perfetto-trace

# 或指定其他路径
adb pull /data/local/tmp/trace.perfetto-trace ./
```

**Web界面导出**：
- 录制完成后自动下载
- 或点击下载按钮手动下载

**Android Studio导出**：
- File -> Export -> Perfetto Trace

### 第六步：分析追踪结果

#### 6.1 打开追踪文件

**方式1：Web界面（推荐）**
```
访问 https://ui.perfetto.dev/
点击 "Open trace file"
选择追踪文件
```

**方式2：Android Studio**
```
打开 Profiler
导入追踪文件
```

#### 6.2 界面概览

Perfetto界面主要区域：

**时间轴视图**：
- 显示时间线
- 可以缩放、拖动
- 显示所有追踪事件

**进程和线程视图**：
- 左侧显示进程和线程列表
- 可以展开/折叠
- 可以筛选特定进程

**事件视图**：
- 显示选中时间范围内的事件
- 可以查看事件详情
- 可以搜索事件

**统计视图**：
- 显示事件统计信息
- CPU使用率
- 内存使用情况
- 帧率统计

#### 6.3 关键分析功能

**时间选择**：
```
# 拖动鼠标选择时间范围
# 或使用键盘快捷键：
- W: 放大
- S: 缩小
- A: 左移
- D: 右移
```

**进程筛选**：
```
# 在搜索框输入进程名
输入: com.android.provision

# 或使用过滤器
Filter: process_name == "com.android.provision"
```

**事件搜索**：
```
# 搜索特定事件
输入: Choreographer#doFrame

# 搜索特定标签
输入: tag:view
```

**关键指标查看**：
```
# CPU使用率
点击: CPU调度视图

# 帧率
点击: Frame timeline

# 内存使用
点击: Memory timeline

# 线程状态
点击: Thread State
```

#### 6.4 性能分析技巧

**分析卡顿**：
1. 找到卡顿的时间点（通过帧率下降）
2. 查看该时间点的CPU调度
3. 检查主线程（main thread）状态
4. 查看是否有长时间运行的任务
5. 检查是否有锁竞争

**分析启动时间**：
1. 找到应用启动的开始时间（Activity创建）
2. 找到首页显示的时间（第一帧）
3. 分析启动过程中的耗时操作
4. 查看主线程的阻塞情况
5. 检查初始化操作

**分析内存**：
1. 查看内存增长趋势
2. 找到内存增长的时间点
3. 查看该时间点的内存分配
4. 检查是否有大对象分配
5. 分析GC事件

**分析帧率**：
1. 查看帧率时间线
2. 找到掉帧的时间点
3. 查看该时间点的渲染事件
4. 检查是否有耗时绘制
5. 分析GPU使用情况

---

## 典型使用场景

### 场景1：应用卡顿分析

**问题描述**：应用界面滑动时卡顿

**分析步骤**：
1. 录制包含滑动操作的追踪（30秒）
2. 配置追踪类别：gfx, view, input, app
3. 在Web界面打开追踪文件
4. 找到卡顿的时间点（帧率下降）
5. 查看该时间点的主线程状态
6. 检查是否有耗时操作：
   - 长时间运行的函数
   - 频繁的GC
   - 锁竞争
   - 网络请求
7. 查看渲染线程是否被阻塞
8. 分析具体原因并优化

**常见根因**：
- 主线程执行耗时操作
- 频繁创建对象导致GC
- View布局过于复杂
- 图片加载和处理耗时

### 场景2：应用启动慢分析

**问题描述**：应用启动时间过长

**分析步骤**：
1. 录制从点击应用到首页显示的过程
2. 配置追踪类别：am, app, gfx, view
3. 找到Activity创建的时间点
4. 找到第一帧显示的时间点
5. 分析启动过程中的耗时操作：
   - Application.onCreate()
   - Activity.onCreate()
   - 布局加载
   - 数据初始化
6. 查看主线程的阻塞情况
7. 优化耗时操作（异步化、延迟加载）

**常见根因**：
- Application初始化耗时
- 同步加载大量数据
- 复杂布局加载
- 阻塞主线程的操作

### 场景3：内存泄漏分析

**问题描述**：应用内存持续增长

**分析步骤**：
1. 录制较长时间的追踪（1-2分钟）
2. 配置内存追踪：java_hprof, ftrace内存事件
3. 查看内存增长趋势
4. 找到内存增长的时间点
5. 查看该时间点的内存分配
6. 分析哪些对象在增长
7. 找到内存泄漏的代码位置
8. 修复内存泄漏

**常见根因**：
- 静态引用持有Context
- 监听器未注销
- 集合对象持续增长
- 匿名内部类持有外部引用

### 场景4：帧率问题分析

**问题描述**：界面刷新率低，掉帧严重

**分析步骤**：
1. 录制界面操作过程
2. 配置追踪类别：gfx, view, wm
3. 查看帧率时间线
4. 找到掉帧的时间点
5. 查看该时间点的渲染事件
6. 检查是否有耗时绘制：
   - 复杂View绘制
   - 图片解码
   - 动画计算
7. 查看GPU使用情况
8. 优化渲染性能

**常见根因**：
- View绘制过于复杂
- 图片尺寸过大
- 动画计算耗时
- GPU性能瓶颈

---

## 注意事项

### 1. 性能影响

**录制对性能的影响**：
- Perfetto录制会消耗一定的系统资源
- 可能影响应用性能（5-10%）
- 建议只在调试时使用

**优化建议**：
- 只追踪必要的类别
- 缩短录制时长
- 使用较小的缓冲区
- 避免在高负载场景下录制

### 2. 数据准确性

**时间戳问题**：
- Perfetto的时间戳是系统时间
- 可能与应用日志时间不完全对齐
- 需要结合logcat日志分析

**事件捕获**：
- 某些快速事件可能被遗漏
- 事件顺序是准确的
- 时间间隔可能有误差（微秒级）

### 3. 设备兼容性

**Android版本要求**：
- Android 9.0 (API 28)及以上版本支持完整功能
- Android 8.1及以下版本功能受限
- 某些功能需要root权限

**权限要求**：
- 需要USB调试权限
- 部分功能需要root权限
- 需要设备支持开发者选项

### 4. 文件大小

**追踪文件大小**：
- 追踪文件可能很大（几十MB到几GB）
- 取决于录制时长和类别
- 需要足够的存储空间

**优化建议**：
- 缩短录制时长
- 只选择必要的类别
- 使用较小的缓冲区
- 及时清理旧的追踪文件

### 5. 配置文件

**配置文件语法**：
- 使用Protobuf文本格式
- 语法严格，容易出错
- 建议使用模板或Web界面生成

**常见错误**：
- 缺少逗号或分号
- 类别名称错误
- 缓冲区大小设置错误

### 6. 分析方法

**避免只看表面**：
- 不要只看单个事件
- 要分析事件序列和上下文
- 要对比正常和异常情况

**综合多个视角**：
- CPU调度 + 应用逻辑
- 内存使用 + 代码逻辑
- 帧率 + 渲染事件

---

## 常见问题FAQ

### Q1: Perfetto无法连接到设备？

**原因**：
- ADB未连接
- USB调试未开启
- 设备不支持Perfetto

**解决**：
```bash
# 检查ADB连接
adb devices

# 检查Perfetto支持
adb shell perfetto --help

# 如果命令不存在，可能需要：
# 1. 升级Android版本
# 2. 安装Perfetto HAL
```

### Q2: 录制过程中设备卡顿？

**原因**：
- 追踪类别过多
- 缓冲区太大
- 系统资源紧张

**解决**：
- 减少追踪类别
- 减小缓冲区大小
- 关闭其他应用

### Q3: 追踪文件太大？

**原因**：
- 录制时间过长
- 追踪类别过多
- 缓冲区太大

**解决**：
- 缩短录制时间
- 减少追踪类别
- 使用较小的缓冲区
- 分段录制

### Q4: 无法找到特定事件？

**原因**：
- 事件未被捕获
- 类别未选择
- 时间范围不对

**解决**：
- 检查配置文件中是否包含相应类别
- 扩大时间范围
- 检查事件名称是否正确

### Q5: 时间戳不准确？

**原因**：
- 系统时间不同步
- 设备时钟漂移

**解决**：
- 同步系统时间
- 使用相对时间分析
- 结合logcat日志分析

---

## 最佳实践

### 1. 录制前准备

- 明确要分析的问题
- 准备复现步骤
- 选择适当的追踪类别
- 设置合适的录制时长

### 2. 录制过程

- 在问题复现前开始录制
- 执行完整的复现步骤
- 问题复现后等待几秒再停止
- 记录关键时间点

### 3. 分析过程

- 先看整体趋势，再看细节
- 对比正常和异常情况
- 结合代码逻辑分析
- 验证分析结论

### 4. 问题定位

- 从关键指标开始（CPU、内存、帧率）
- 找到问题发生的时间点
- 分析该时间点的事件序列
- 定位到具体的代码位置

### 5. 优化验证

- 修复问题后重新录制
- 对比修复前后的性能
- 验证优化效果
- 记录优化经验

---

## 高级技巧

### 1. 自定义追踪配置

创建针对特定问题的配置：
```text
# 只追踪特定进程
data_sources: {
    config {
        name: "linux.ftrace"
        ftrace_config {
            target_pid: 12345
        }
    }
}
```

### 2. 事件过滤

在分析时使用过滤器：
```
# 过滤特定进程
process_name == "com.android.provision"

# 过滤特定线程
thread_name == "main"

# 过滤特定标签
tag == "view"
```

### 3. 时间同步

结合logcat日志分析：
```bash
# 录制时同时抓取logcat
adb logcat > logcat.txt &

# 在Perfetto中找到关键时间点
# 在logcat中找到对应时间点的日志
```

### 4. 对比分析

对比正常和异常情况：
- 在同一界面打开两个追踪文件
- 对比关键指标
- 找出差异点

### 5. 自动化脚本

创建自动化录制脚本：
```bash
#!/bin/bash
# 自动录制并导出
adb shell perfetto -t 30s -o /data/misc/perfetto-traces/trace.perfetto-trace
sleep 35
adb pull /data/misc/perfetto-traces/trace.perfetto-trace ./trace_$(date +%Y%m%d_%H%M%S).perfetto-trace
```

---

## 相关资源

### 官方文档
- Perfetto官方文档：https://perfetto.dev/
- Web界面：https://ui.perfetto.dev/
- GitHub仓库：https://github.com/google/perfetto

### 相关工具
- **Winscope**：窗口和Surface分析工具
- **Systrace**：旧版性能追踪工具（已被Perfetto替代）
- **Android Studio Profiler**：集成性能分析工具

### 相关命令
```bash
# 系统信息
adb shell dumpsys cpuinfo
adb shell dumpsys meminfo
adb shell dumpsys gfxinfo

# 日志相关
adb logcat | grep -i perfetto
adb logcat | grep -i trace
```

---

## 总结

Perfetto是Android系统性能分析的强大工具，通过合理使用可以快速定位：
- 应用卡顿问题
- 启动时间问题
- 内存泄漏问题
- 帧率问题
- 电量消耗问题

关键要点：
1. 正确配置追踪类别
2. 把握好录制时机和时长
3. 综合多个视角分析
4. 结合代码和日志验证

熟练掌握Perfetto可以大大提高性能问题的调试效率。
