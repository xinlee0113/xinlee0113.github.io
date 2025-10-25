---
layout: default
title: Android源码快速参考手册
parent: Android源码学习
nav_order: 2
---

# Android源码快速参考手册

## 📍 核心目录结构速查

```
/mnt/01_lixin_workspace/master-w/
├── frameworks/base/              # Android Framework核心
│   ├── core/java/               # Framework Java核心API
│   │   ├── android/app/         # 四大组件、AMS、PMS等
│   │   ├── android/os/          # Handler、Binder、System等
│   │   ├── android/view/        # View系统、Window等
│   │   └── android/content/     # Context、ContentProvider等
│   ├── services/                # 系统服务实现
│   │   ├── core/java/           # 核心服务
│   │   │   ├── com/android/server/am/    # ActivityManager
│   │   │   ├── com/android/server/wm/    # WindowManager
│   │   │   └── com/android/server/pm/    # PackageManager
│   │   └── java/com/android/server/      # SystemServer
│   ├── api/                     # 公开API定义
│   └── cmds/                    # 命令行工具（am、pm等）
│
├── frameworks/native/            # Native框架
│   ├── libs/binder/             # Binder C++实现
│   ├── libs/gui/                # GUI系统（Surface、BufferQueue）
│   ├── libs/ui/                 # UI基础（PixelFormat、Region等）
│   ├── services/                # Native服务
│   │   ├── surfaceflinger/      # SurfaceFlinger
│   │   └── inputflinger/        # InputFlinger
│   └── cmds/servicemanager/     # ServiceManager
│
├── frameworks/av/                # 音视频框架
│   ├── services/audioflinger/   # AudioFlinger
│   ├── services/camera/         # Camera服务
│   ├── media/                   # 媒体框架
│   │   ├── libstagefright/      # 编解码框架
│   │   └── codec2/              # Codec2.0
│   └── drm/                     # DRM框架
│
├── system/                       # 系统核心组件
│   ├── core/                    # 核心库
│   │   ├── init/                # Init进程
│   │   ├── liblog/              # 日志库
│   │   ├── libutils/            # 工具库
│   │   └── rootdir/             # init.rc等启动脚本
│   ├── vold/                    # 卷管理守护进程
│   └── netd/                    # 网络守护进程
│
├── art/                         # Android Runtime
│   ├── runtime/                 # 运行时核心
│   │   ├── gc/                  # 垃圾回收
│   │   ├── jni/                 # JNI实现
│   │   └── interpreter/         # 解释器
│   ├── compiler/                # AOT编译器
│   └── dex2oat/                 # dex2oat工具
│
├── bionic/                      # C库实现
│   ├── libc/                    # C标准库
│   ├── libm/                    # 数学库
│   └── linker/                  # 动态链接器
│
├── packages/                    # 系统应用
│   ├── apps/                    # 系统应用
│   │   ├── Settings/            # 设置应用
│   │   ├── Launcher3/           # Launcher
│   │   └── SystemUI/            # 系统UI
│   └── services/                # 系统服务应用
│
├── hardware/                    # HAL层
│   ├── interfaces/              # HIDL接口定义
│   └── libhardware/             # HAL库
│
├── kernel/                      # Linux内核
│   ├── drivers/android/         # Android驱动
│   │   ├── binder.c             # Binder驱动
│   │   └── ashmem.c             # 匿名共享内存
│   └── prebuilts/               # 预编译内核
│
└── miui/                        # MIUI定制层
    ├── frameworks/              # MIUI框架定制
    └── system/                  # MIUI系统应用
```

---

## 🎯 核心类速查表

### 1. 四大组件相关

| 组件 | 核心类 | 文件路径 |
|------|--------|----------|
| **Activity** | Activity | `frameworks/base/core/java/android/app/Activity.java` |
| | ActivityThread | `frameworks/base/core/java/android/app/ActivityThread.java` |
| | Instrumentation | `frameworks/base/core/java/android/app/Instrumentation.java` |
| | ActivityTaskManagerService | `frameworks/base/services/core/java/com/android/server/wm/ActivityTaskManagerService.java` |
| | ActivityStarter | `frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java` |
| | ActivityRecord | `frameworks/base/services/core/java/com/android/server/wm/ActivityRecord.java` |
| **Service** | Service | `frameworks/base/core/java/android/app/Service.java` |
| | ActiveServices | `frameworks/base/services/core/java/com/android/server/am/ActiveServices.java` |
| | ServiceRecord | `frameworks/base/services/core/java/com/android/server/am/ServiceRecord.java` |
| **Broadcast** | BroadcastReceiver | `frameworks/base/core/java/android/content/BroadcastReceiver.java` |
| | BroadcastQueue | `frameworks/base/services/core/java/com/android/server/am/BroadcastQueue.java` |
| | BroadcastRecord | `frameworks/base/services/core/java/com/android/server/am/BroadcastRecord.java` |
| **ContentProvider** | ContentProvider | `frameworks/base/core/java/android/content/ContentProvider.java` |
| | ContentProviderRecord | `frameworks/base/services/core/java/com/android/server/am/ContentProviderRecord.java` |

### 2. 系统服务

| 服务名 | 类名 | 文件路径 | 主要职责 |
|--------|------|----------|----------|
| **ActivityManager** | ActivityManagerService | `frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java` | 进程、四大组件管理 |
| **ActivityTaskManager** | ActivityTaskManagerService | `frameworks/base/services/core/java/com/android/server/wm/ActivityTaskManagerService.java` | Activity、Task管理 |
| **WindowManager** | WindowManagerService | `frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java` | 窗口管理、焦点管理 |
| **PackageManager** | PackageManagerService | `frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java` | 应用安装、查询 |
| **PowerManager** | PowerManagerService | `frameworks/base/services/core/java/com/android/server/power/PowerManagerService.java` | 电源、休眠管理 |
| **InputManager** | InputManagerService | `frameworks/base/services/core/java/com/android/server/input/InputManagerService.java` | 输入事件分发 |
| **DisplayManager** | DisplayManagerService | `frameworks/base/services/core/java/com/android/server/display/DisplayManagerService.java` | 显示设备管理 |
| **LocationManager** | LocationManagerService | `frameworks/base/services/core/java/com/android/server/location/LocationManagerService.java` | 位置服务 |
| **NotificationManager** | NotificationManagerService | `frameworks/base/services/core/java/com/android/server/notification/NotificationManagerService.java` | 通知管理 |
| **AlarmManager** | AlarmManagerService | `frameworks/base/services/core/java/com/android/server/AlarmManagerService.java` | 闹钟、定时任务 |

### 3. Binder IPC

| 组件 | 文件路径 | 说明 |
|------|----------|------|
| **Java层** |
| IBinder | `frameworks/base/core/java/android/os/IBinder.java` | Binder接口定义 |
| Binder | `frameworks/base/core/java/android/os/Binder.java` | Binder实现类 |
| ServiceManager | `frameworks/base/core/java/android/os/ServiceManager.java` | 服务管理器 |
| Parcel | `frameworks/base/core/java/android/os/Parcel.java` | 数据打包 |
| **Native层** |
| Binder.cpp | `frameworks/native/libs/binder/Binder.cpp` | Native Binder实现 |
| BpBinder.cpp | `frameworks/native/libs/binder/BpBinder.cpp` | Binder代理 |
| IPCThreadState.cpp | `frameworks/native/libs/binder/IPCThreadState.cpp` | IPC线程状态 |
| ProcessState.cpp | `frameworks/native/libs/binder/ProcessState.cpp` | 进程状态 |
| **Kernel层** |
| binder.c | `kernel/drivers/android/binder.c` | Binder驱动 |

### 4. Handler消息机制

| 类名 | 文件路径 | 说明 |
|------|----------|------|
| Handler | `frameworks/base/core/java/android/os/Handler.java` | 消息处理器 |
| Looper | `frameworks/base/core/java/android/os/Looper.java` | 消息循环 |
| MessageQueue | `frameworks/base/core/java/android/os/MessageQueue.java` | 消息队列 |
| Message | `frameworks/base/core/java/android/os/Message.java` | 消息对象 |
| MessageQueue.cpp | `frameworks/base/core/jni/android_os_MessageQueue.cpp` | Native实现 |

### 5. View系统

| 组件 | 文件路径 | 说明 |
|------|----------|------|
| **Java层** |
| View | `frameworks/base/core/java/android/view/View.java` | View基类 |
| ViewGroup | `frameworks/base/core/java/android/view/ViewGroup.java` | ViewGroup基类 |
| ViewRootImpl | `frameworks/base/core/java/android/view/ViewRootImpl.java` | View树根节点 |
| Choreographer | `frameworks/base/core/java/android/view/Choreographer.java` | 帧调度器 |
| Surface | `frameworks/base/core/java/android/view/Surface.java` | 绘制表面 |
| WindowManager | `frameworks/base/core/java/android/view/WindowManager.java` | 窗口管理接口 |
| **Native层** |
| SurfaceFlinger.cpp | `frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp` | 显示合成服务 |
| BufferQueue.cpp | `frameworks/native/libs/gui/BufferQueue.cpp` | 缓冲队列 |
| Layer.cpp | `frameworks/native/services/surfaceflinger/Layer.cpp` | 图层管理 |

### 6. 启动流程

| 阶段 | 关键类/文件 | 路径 |
|------|-------------|------|
| **Bootloader** | | 设备特定 |
| **Kernel** | kernel | `kernel/` |
| **Init** | init.cpp | `system/core/init/init.cpp` |
| | init.rc | `system/core/rootdir/init.rc` |
| **Zygote** | ZygoteInit.java | `frameworks/base/core/java/com/android/internal/os/ZygoteInit.java` |
| | app_process | `frameworks/base/cmds/app_process/` |
| **SystemServer** | SystemServer.java | `frameworks/base/services/java/com/android/server/SystemServer.java` |
| | SystemServiceManager.java | `frameworks/base/services/core/java/com/android/server/SystemServiceManager.java` |
| **Launcher** | Launcher.java | `packages/apps/Launcher3/src/com/android/launcher3/Launcher.java` |

---

## 🔧 常用命令速查

### 1. ADB调试命令

```bash
# 查看日志
adb logcat                                    # 实时日志
adb logcat -b main -b system -b crash        # 多buffer日志
adb logcat -s ActivityManager:V              # 过滤特定Tag
adb logcat *:E                                # 只显示错误级别

# 进程管理
adb shell ps -A                               # 查看所有进程
adb shell ps -A | grep system_server          # 查找system_server
adb shell kill -9 <pid>                       # 杀死进程

# 系统服务
adb shell service list                        # 列出所有系统服务
adb shell dumpsys                             # dump所有服务
adb shell dumpsys activity                    # dump AMS
adb shell dumpsys window                      # dump WMS
adb shell dumpsys package <pkg>               # dump应用信息
adb shell dumpsys meminfo <pkg>               # 内存信息
adb shell dumpsys gfxinfo <pkg>               # 图形信息

# Activity管理
adb shell am start -n <pkg>/<activity>        # 启动Activity
adb shell am force-stop <pkg>                 # 强制停止应用
adb shell am kill <pkg>                       # 杀死应用进程
adb shell am stack list                       # 列出Activity栈

# 包管理
adb shell pm list packages                    # 列出所有包
adb shell pm path <pkg>                       # 查看包路径
adb shell pm clear <pkg>                      # 清除应用数据
adb shell pm disable <pkg>                    # 禁用应用

# 属性操作
adb shell getprop                             # 查看所有属性
adb shell getprop ro.build.version.sdk        # 查看SDK版本
adb shell setprop <key> <value>               # 设置属性

# 文件操作
adb push <local> <remote>                     # 上传文件
adb pull <remote> <local>                     # 下载文件
adb shell ls /system/framework/               # 列出framework jar
```

### 2. 源码编译命令

```bash
# 初始化环境
source build/envsetup.sh
lunch <target>                                # 选择编译目标

# 完整编译
make -j8                                      # 完整编译（8线程）
make clean                                    # 清理

# 模块编译
mmm <module_path>                             # 编译指定模块
mm                                            # 编译当前目录模块
mmma <module_path>                            # 编译模块及依赖
mma                                           # 编译当前目录及依赖

# 示例
mmm frameworks/base/services                  # 编译services
mmm packages/apps/Settings                    # 编译Settings

# 编译特定目标
make systemimage                              # 编译system镜像
make bootimage                                # 编译boot镜像
make vendorimage                              # 编译vendor镜像
```

### 3. 代码搜索命令

```bash
# grep搜索
grep -r "class ActivityManagerService" frameworks/
grep -rn "startActivity" frameworks/base/core/java/android/app/

# find搜索
find frameworks/ -name "*.java" | xargs grep -l "ActivityManagerService"
find . -name "ActivityManagerService.java"

# 搜索AIDL
find . -name "*.aidl" | xargs grep "interface"

# 搜索配置文件
find . -name "AndroidManifest.xml"
find . -name "Android.bp"
```

---

## 📊 关键流程速查

### 1. Activity启动流程

```
Launcher.onClick()
  ↓
Activity.startActivity()
  ↓
Instrumentation.execStartActivity()
  ↓
ActivityTaskManager.getService().startActivity()  [Binder IPC]
  ↓
ATMS.startActivityAsUser()
  ↓
ActivityStarter.execute()
  ↓
判断进程是否存在
  ↓ (不存在)
Zygote.fork()  [Socket]
  ↓
ActivityThread.main()
  ↓
ActivityThread.attach()
  ↓
ATMS.attachApplication()  [Binder IPC]
  ↓
ATMS.realStartActivityLocked()
  ↓
ApplicationThread.scheduleLaunchActivity()  [Binder回调]
  ↓
ActivityThread.handleLaunchActivity()
  ↓
Activity.onCreate()
  ↓
Activity.onStart()
  ↓
Activity.onResume()
  ↓
WindowManager.addView(DecorView)
  ↓
Activity可见
```

### 2. Service启动流程

```
Context.startService()
  ↓
ContextImpl.startService()
  ↓
ActivityManager.getService().startService()  [Binder IPC]
  ↓
ActiveServices.startServiceLocked()
  ↓
判断进程是否存在
  ↓ (存在)
ActiveServices.realStartServiceLocked()
  ↓
ApplicationThread.scheduleCreateService()  [Binder回调]
  ↓
ActivityThread.handleCreateService()
  ↓
Service.onCreate()
  ↓
Service.onStartCommand()
```

### 3. Broadcast发送流程

```
Context.sendBroadcast()
  ↓
ContextImpl.sendBroadcast()
  ↓
ActivityManager.getService().broadcastIntent()  [Binder IPC]
  ↓
AMS.broadcastIntent()
  ↓
BroadcastQueue.scheduleBroadcastsLocked()
  ↓
BroadcastQueue.processNextBroadcast()
  ↓
ApplicationThread.scheduleReceiver()  [Binder回调]
  ↓
ActivityThread.handleReceiver()
  ↓
BroadcastReceiver.onReceive()
```

### 4. View绘制流程

```
Activity.setContentView()
  ↓
PhoneWindow.setContentView()
  ↓
DecorView.addView()
  ↓
WindowManagerGlobal.addView()
  ↓
ViewRootImpl.setView()
  ↓
ViewRootImpl.requestLayout()
  ↓
ViewRootImpl.scheduleTraversals()
  ↓
Choreographer.postCallback()
  ↓
等待VSYNC信号
  ↓
ViewRootImpl.performTraversals()
  ├─> performMeasure() → View.measure() → onMeasure()
  ├─> performLayout() → View.layout() → onLayout()
  └─> performDraw() → View.draw() → onDraw()
  ↓
Surface.lockCanvas()
  ↓
Canvas绘制
  ↓
Surface.unlockCanvasAndPost()
  ↓
SurfaceFlinger合成显示
```

### 5. Binder通信流程

```
[Client进程]
Proxy.transact()
  ↓
BinderProxy.transact()
  ↓
JNI: android_os_BinderProxy_transact()
  ↓
BpBinder::transact()
  ↓
IPCThreadState::transact()
  ↓
IPCThreadState::writeTransactionData()
  ↓
IPCThreadState::waitForResponse()
  ↓
ioctl(BINDER_WRITE_READ)
  ↓
[Binder驱动]
binder_ioctl()
  ↓
binder_thread_write()
  ↓
binder_transaction()
  ↓
唤醒目标进程
  ↓
[Server进程]
IPCThreadState::waitForResponse()
  ↓
IPCThreadState::executeCommand()
  ↓
BBinder::transact()
  ↓
Stub.onTransact()
  ↓
执行服务端方法
  ↓
返回结果（反向流程）
```

---

## 🛠️ 调试技巧速查

### 1. 添加日志

```java
// Java层
import android.util.Log;
Log.d(TAG, "message");
Log.e(TAG, "error", exception);

// Native层
#include <utils/Log.h>
ALOGD("message");
ALOGE("error");
```

### 2. 追踪方法调用

```java
// 打印堆栈
Log.d(TAG, "Stack trace:", new Exception());

// 或使用
android.util.Log.getStackTraceString(new Throwable())
```

### 3. Systrace分析

```bash
# 录制trace
python systrace.py -t 10 -o trace.html am wm view dalvik sched gfx

# 在代码中添加trace点
Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "myMethod");
// ... code ...
Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
```

### 4. 性能分析

```bash
# CPU Profiler
adb shell am profile start <pkg> <output_file>
adb shell am profile stop <pkg>

# Memory Profiler
adb shell am dumpheap <pkg> <output_file>

# StrictMode
StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
    .detectAll()
    .penaltyLog()
    .build());
```

---

## 📖 学习资源速查

### 1. 在线源码浏览
- **AndroidXRef**: http://androidxref.com/
- **CS Android**: https://cs.android.com/
- **Android Source**: https://source.android.com/

### 2. 官方文档
- **Android Developers**: https://developer.android.com/
- **Source Documentation**: https://source.android.com/docs

### 3. 推荐博客
- **Gityuan**: http://gityuan.com/
- **老罗博客**: https://blog.csdn.net/Luoshengyang

### 4. 工具推荐
- **Android Studio**: IDE
- **Source Insight**: C/C++代码阅读
- **VSCode + Clangd**: 代码跳转
- **Beyond Compare**: 代码对比
- **PlantUML**: UML图绘制

---

## 🔍 常见问题速查

### Q1: 如何快速定位系统服务？
```bash
# 查看服务列表
adb shell service list

# 找到服务名后，在源码中搜索
grep -r "ServiceManager.addService(\"service_name\"" frameworks/
```

### Q2: 如何追踪Binder调用？
```bash
# 启用Binder追踪
adb shell am trace-ipc start
# 执行操作
adb shell am trace-ipc stop --dump-file /data/local/tmp/ipc-trace.txt
adb pull /data/local/tmp/ipc-trace.txt
```

### Q3: 如何查看Activity栈？
```bash
adb shell dumpsys activity activities
```

### Q4: 如何分析ANR？
```bash
# 1. 查看traces文件
adb pull /data/anr/traces.txt

# 2. 分析主线程堆栈
grep "main" traces.txt -A 50
```

### Q5: 如何查看内存占用？
```bash
adb shell dumpsys meminfo <pkg>
```

---

## ⚡ 快捷键速查（Android Studio）

| 快捷键 | 功能 |
|--------|------|
| `Ctrl + N` | 查找类 |
| `Ctrl + Shift + N` | 查找文件 |
| `Ctrl + Alt + Shift + N` | 查找符号（方法/变量） |
| `Ctrl + B` | 跳转到定义 |
| `Ctrl + Alt + B` | 跳转到实现 |
| `Ctrl + H` | 查看类层次结构 |
| `Ctrl + F12` | 查看类结构 |
| `Alt + F7` | 查找用法 |
| `Ctrl + Shift + F` | 全局搜索 |
| `Ctrl + Shift + R` | 全局替换 |

---

**文档版本：** v1.0  
**更新日期：** 2025-10-25  
**维护者：** AI Assistant

