---
layout: default
title: Android源码学习路线图
parent: Android源码学习
nav_order: 1
---

# Android源码科学学习路线图

## 📚 学习原则

1. **自顶向下**：从应用层→Framework→Native→Kernel
2. **问题驱动**：带着具体问题阅读源码
3. **模块聚焦**：每次深入一个模块，建立完整认知
4. **实践验证**：修改代码→编译→验证→总结

---

## 🎯 阶段一：Framework核心机制（建议4-6周）

### 1.1 四大组件启动流程

#### Activity启动流程
**关键文件路径：**
```
frameworks/base/core/java/android/app/
├── Activity.java                    # Activity基类
├── ActivityThread.java              # 应用主线程
├── Instrumentation.java             # 监控类
└── ContextImpl.java                 # Context实现

frameworks/base/services/core/java/com/android/server/
├── am/ActivityManagerService.java   # AMS核心
├── am/ActivityStack.java            # Activity栈管理
└── wm/ActivityRecord.java           # Activity记录
```

**学习任务：**
- [ ] 绘制Activity启动时序图（从startActivity到onCreate）
- [ ] 理解进程创建流程（zygote fork机制）
- [ ] 分析生命周期回调机制
- [ ] 实践：添加日志追踪完整启动流程

#### Service启动流程
**关键文件：**
```
frameworks/base/services/core/java/com/android/server/am/
├── ActiveServices.java              # Service管理
└── ServiceRecord.java               # Service记录
```

#### BroadcastReceiver机制
**关键文件：**
```
frameworks/base/services/core/java/com/android/server/am/
├── BroadcastQueue.java              # 广播队列
└── BroadcastRecord.java             # 广播记录
```

---

### 1.2 Binder进程间通信（IPC）

**核心概念：**
- Client/Server架构
- ServiceManager注册与查询
- Binder驱动（内核态）
- Java层封装

**关键文件：**
```
frameworks/base/core/java/android/os/
├── Binder.java                      # Java层Binder
├── IBinder.java                     # Binder接口
└── Parcel.java                      # 数据打包

frameworks/native/libs/binder/
├── Binder.cpp                       # Native Binder
├── IPC ThreadState.cpp               # 线程状态管理
└── ProcessState.cpp                 # 进程状态管理

kernel/drivers/android/
└── binder.c                         # Binder驱动
```

**学习任务：**
- [ ] 理解AIDL自动生成代码机制
- [ ] 追踪一次跨进程调用全流程
- [ ] 分析Binder线程池模型
- [ ] 实践：自己实现一个AIDL服务

---

### 1.3 Handler消息机制

**核心类：**
```
frameworks/base/core/java/android/os/
├── Handler.java                     # 消息发送与处理
├── Looper.java                      # 消息循环
├── Message.java                     # 消息对象
└── MessageQueue.java                # 消息队列
```

**关键问题：**
- 一个线程有几个Looper？几个MessageQueue？
- Message如何与Handler绑定？
- 如何避免内存泄漏？
- IdleHandler的使用场景？

**学习任务：**
- [ ] 绘制Handler机制UML类图
- [ ] 分析postDelayed的实现原理
- [ ] 理解同步屏障机制
- [ ] 实践：实现HandlerThread源码

---

## 🎯 阶段二：系统服务深入（建议6-8周）

### 2.1 WindowManagerService（WMS）

**核心职责：**
- 窗口添加、删除、更新
- 窗口层级（Z-Order）管理
- 输入事件分发
- 动画控制

**关键文件：**
```
frameworks/base/services/core/java/com/android/server/wm/
├── WindowManagerService.java        # WMS核心
├── WindowState.java                 # 窗口状态
├── WindowToken.java                 # 窗口令牌
└── DisplayContent.java              # 屏幕内容管理
```

**学习路径：**
1. Window添加流程（Dialog、Activity、Toast）
2. Surface创建与绑定
3. 窗口动画实现
4. 触摸事件分发机制

---

### 2.2 PackageManagerService（PMS）

**核心职责：**
- APK安装、卸载、更新
- 包信息管理
- 权限验证
- 组件信息查询

**关键文件：**
```
frameworks/base/services/core/java/com/android/server/pm/
├── PackageManagerService.java       # PMS核心
├── PackageParser.java               # APK解析
└── Settings.java                    # 包配置存储
```

**学习任务：**
- [ ] APK安装全流程分析
- [ ] AndroidManifest.xml解析机制
- [ ] 四大组件注册与查询流程
- [ ] 实践：hook PMS拦截应用安装

---

### 2.3 ActivityManagerService（AMS）

**核心职责：**
- 四大组件生命周期管理
- 进程优先级调度
- OOM_ADJ机制
- 任务栈管理

**关键文件：**
```
frameworks/base/services/core/java/com/android/server/am/
├── ActivityManagerService.java      # AMS核心
├── ProcessRecord.java               # 进程记录
├── ActivityStack.java               # Activity栈
└── OomAdjuster.java                 # 内存调整
```

---

## 🎯 阶段三：图形显示系统（建议4-6周）

### 3.1 SurfaceFlinger

**核心职责：**
- Surface合成
- 垂直同步（VSync）
- 三重缓冲
- 硬件加速

**关键文件：**
```
frameworks/native/services/surfaceflinger/
├── SurfaceFlinger.cpp               # SF核心
├── Layer.cpp                        # 图层
└── BufferQueue.cpp                  # 缓冲队列
```

**学习任务：**
- [ ] 理解生产者-消费者模型
- [ ] 分析VSync信号传递机制
- [ ] 研究黄油计划（Project Butter）
- [ ] 实践：dumpsys SurfaceFlinger分析

---

### 3.2 View绘制流程

**三大流程：**
1. **measure**：测量View大小
2. **layout**：确定View位置
3. **draw**：绘制View内容

**关键类：**
```
frameworks/base/core/java/android/view/
├── View.java                        # View基类
├── ViewGroup.java                   # ViewGroup基类
└── ViewRootImpl.java                # View树根节点
```

**学习任务：**
- [ ] 自定义View的三大流程
- [ ] 硬件加速原理
- [ ] invalidate()与requestLayout()区别
- [ ] 实践：实现复杂自定义View

---

## 🎯 阶段四：Native层与HAL（建议6-8周）

### 4.1 Native Binder

**关键文件：**
```
frameworks/native/libs/binder/
├── Binder.cpp
├── BpBinder.cpp                     # Proxy端
├── BBinder.cpp                      # Native端
└── IPCThreadState.cpp               # 线程状态
```

---

### 4.2 AudioFlinger

**音频系统核心服务**
```
frameworks/av/services/audioflinger/
└── AudioFlinger.cpp
```

---

### 4.3 MediaCodec

**多媒体编解码**
```
frameworks/av/media/libstagefright/
└── MediaCodec.cpp
```

---

### 4.4 HAL层（Hardware Abstraction Layer）

**典型HAL模块：**
```
hardware/libhardware/modules/
├── camera/                          # 相机HAL
├── sensors/                         # 传感器HAL
└── audio/                           # 音频HAL
```

---

## 🎯 阶段五：Linux Kernel层（建议4-6周）

### 5.1 Binder驱动

**关键文件：**
```
kernel/drivers/android/
├── binder.c                         # Binder驱动核心
└── binder_alloc.c                   # 内存分配
```

**学习任务：**
- [ ] 理解mmap一次拷贝原理
- [ ] 分析Binder线程唤醒机制
- [ ] 研究Binder内存映射

---

### 5.2 LowMemoryKiller

**低内存杀手机制**
```
kernel/drivers/staging/android/
└── lowmemorykiller.c
```

---

### 5.3 WakeLock

**电源管理**
```
kernel/kernel/power/
└── wakelock.c
```

---

## 🎯 阶段六：系统启动流程（建议2-3周）

### 启动顺序

```
1. Bootloader
   ↓
2. Kernel（init进程）
   ↓
3. init进程解析init.rc
   ↓
4. Zygote进程启动
   ↓
5. SystemServer启动
   ↓
6. 各系统服务启动（AMS、WMS、PMS...）
   ↓
7. Launcher启动
```

**关键文件：**
```
system/core/init/
├── init.cpp                         # init进程
└── init.rc                          # 启动脚本

frameworks/base/core/java/com/android/internal/os/
├── ZygoteInit.java                  # Zygote入口
└── RuntimeInit.java                 # 运行时初始化

frameworks/base/services/java/com/android/server/
└── SystemServer.java                # 系统服务启动
```

---

## 📝 学习方法建议

### 1. 搭建源码阅读环境

**推荐工具：**
- **Android Studio**：导入源码（需要生成IDE项目文件）
- **Source Insight**：代码跳转神器
- **VSCode + C/C++ Extension**：轻量级，适合Native代码
- **在线源码**：
  - http://aospxref.com/
  - https://cs.android.com/

---

### 2. 绘制流程图

**推荐工具：**
- **PlantUML**：代码生成UML图
- **Draw.io**：在线绘图工具
- **Excalidraw**：手绘风格流程图

**必绘图表：**
- Activity启动时序图
- Binder通信序列图
- View绘制流程图
- Handler消息机制类图

---

### 3. 实践验证

**修改源码实验：**
```bash
# 1. 修改代码添加日志
# 2. 编译单个模块
mmm frameworks/base/services/core
# 3. 推送到设备
adb push out/target/product/xxx/system/framework/services.jar /system/framework/
# 4. 重启验证
adb reboot
```

---

### 4. 建立知识图谱

**推荐工具：**
- **Obsidian**：双向链接笔记
- **Notion**：在线协作文档
- **Markdown + Git**：版本控制笔记

**笔记模板：**
```markdown
# 模块名称

## 核心职责
- 职责1
- 职责2

## 关键类
- 类名1：作用
- 类名2：作用

## 关键流程
1. 步骤1
2. 步骤2

## 重点问题
- 问题1：答案
- 问题2：答案

## 相关模块
- [[模块A]]
- [[模块B]]
```

---

## 🎓 进阶资源

### 书籍推荐
1. 《Android系统源代码情景分析》- 罗升阳
2. 《深入理解Android》系列 - 邓凡平
3. 《Android框架揭秘》- 金泰延

### 博客推荐
- Gityuan（源码分析第一人）：http://gityuan.com/
- 罗升阳博客：https://blog.csdn.net/luoshengyang

### 视频课程
- 慕课网：Android Framework系统架构
- 极客时间：Android开发高手课

---

## 📊 学习进度追踪

### 阶段一：Framework核心 (4-6周)
- [ ] Activity启动流程
- [ ] Service启动流程
- [ ] Binder IPC机制
- [ ] Handler消息机制

### 阶段二：系统服务 (6-8周)
- [ ] WindowManagerService
- [ ] PackageManagerService
- [ ] ActivityManagerService

### 阶段三：图形显示 (4-6周)
- [ ] SurfaceFlinger
- [ ] View绘制流程

### 阶段四：Native层 (6-8周)
- [ ] Native Binder
- [ ] AudioFlinger
- [ ] MediaCodec
- [ ] HAL层

### 阶段五：Kernel层 (4-6周)
- [ ] Binder驱动
- [ ] LowMemoryKiller
- [ ] WakeLock

### 阶段六：系统启动 (2-3周)
- [ ] init进程
- [ ] Zygote进程
- [ ] SystemServer

---

## 💡 学习建议

1. **不要试图一次学完**：循序渐进，每个阶段打好基础再进入下一阶段
2. **理论结合实践**：看源码→画流程图→写Demo→修改源码验证
3. **建立系统认知**：理解模块间的关系，建立完整的知识体系
4. **定期总结回顾**：每周总结学习内容，定期回顾已学知识
5. **参与社区讨论**：在技术论坛提问、回答问题，加深理解

---

**祝学习愉快！持续精进！** 🚀
