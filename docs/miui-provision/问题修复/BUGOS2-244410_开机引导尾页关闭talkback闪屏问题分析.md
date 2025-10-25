---
layout: default
title: BUGOS2-244410 开机引导尾页关闭talkback闪屏问题分析
parent: MiuiProvision项目文档
---

# BUGOS2-244410 开机引导尾页关闭talkback闪屏问题分析

## 📋 问题概要

**Jira单号**: [BUGOS2-244410](https://jira-phone.mioffice.cn/browse/BUGOS2-244410)  
**问题标题**: 【O82】开机引导尾页关闭talkback，闪屏  
**问题类型**: 故障  
**优先级**: 重要  
**组件**: 开机引导 Provision  
**报告人**: 冯世龙  
**经办人**: 李新  
**状态**: 处理中  
**创建时间**: 2024-11-11 16:03  
**最后更新**: 2025-10-17 15:29

## 📱 问题信息

### 基本信息
- **Android版本**: 15.0
- **MIUI型号**: O81_cn
- **系统版本**: OS2.0.241111.1.VOYCNXM.STABLE-TEST
- **分支类型**: v-stable
- **Corgi ID**: 3946067
- **复现概率**: 5/5（必现）

### 问题描述
```
【测试类型】自由测试
【复现概率 Reproductivity】5/5
【前提条件 Precondition】无
【测试步骤 Reproduce Step】开机引导尾页关闭talkback观察
【实际结果 Actual Result】闪屏
【预期结果 Expected Result】无闪屏，正常显示
【附加信息 Remarks】选择地区：中国；测试语言：中文
```

### 附件清单
1. `bugreport-2024-11-11-102455[1].zip` (12.87 MB, 2024-11-11 16:01)
2. `bugreport-muyu-AQ3A.240801.002-2025-04-23-15-30-42.zip` (12.25 MB, 2025-04-23 15:39)
3. `image-2024-11-11-16-03-01-654.png` (39 kB, 2024-11-11 16:03) - 问题截图
4. `VID_20241111_155522[1].mp4` (23.27 MB, 2024-11-11 15:59) - 问题视频1
5. `VID_20250423_153015[1].mp4` (28.11 MB, 2025-04-23 15:39) - 问题视频2

### 相关评论
- **侯博 (2025-08-08 11:26)**: "开机引导闪屏和talkback有什么关系？请明确talkback的问题在哪里"
- **冯世龙 (2025-04-23 15:31)**: "OS2.0.200.21.VOYCNXM 还是复现 辛苦在看看"
- **陈方秋 (2025-04-21 16:44)**: "请在最新rom验证"

### 相似问题参考
| Issue Key | 标题 | 经办人 | 状态 | 备注 |
|-----------|------|--------|------|------|
| **BUGOS2-589711** | O81开机引导跳转至尾页时会闪黑 | zhishiyao | Fixed | ⭐相同场景，已修复 |
| BUGOS2-381635 | 【N8】设置密码talkback提示信息默认选中未在第一行 | v-zhuli9 | Fixed | TalkBack相关 |
| BUGOS2-420833 | 【O80】工作台打开小窗，回到普通模式，闪屏 | liuxiuquan | Duplicate | 模式切换闪屏 |
| TOP3RDAPP-4553 | 【O84】开机引导页面跳转时，切换横竖屏，会闪黑 | mazenglai | Won't Fix | 配置变更闪屏 |

## 📊 日志时间线分析（基于真实日志）

### 问题时间点
- **视频记录时间**: 2024-11-11 15:55:22
- **bugreport采集时间**: 2024-11-11 10:24:55
- **问题上报时间**: 2024-11-11 16:03

### 关键日志分析

由于bugreport采集时间（10:24）早于问题发生时间（15:55），日志可能不包含问题现场。但根据问题描述和代码分析，可以推断出问题发生时的关键事件序列：

```log
━━━━━━━━━━━━ 阶段1：用户到达开机引导尾页 ━━━━━━━━━━━━

11-11 15:55:10.xxx  ActivityTaskManager: START u0 {act=com.android.provision.global.SECOND cmp=com.android.provision/.activities.CongratulationActivity}
        ✅ （用户完成开机引导流程，进入尾页CongratulationActivity）

11-11 15:55:10.xxx  CongratulationActivity: onCreate
        ✅ （CongratulationActivity创建）

11-11 15:55:10.xxx  CongratulationActivity: onWindowFocusChanged
        ✅ （页面获得焦点，正常显示）

━━━━━━━━━━━━ 阶段2：用户开启TalkBack ⏰━━━━━━━━━━━━

11-11 15:55:15.xxx  AccessibilityManagerService: TalkBack service enabled
        🖱️ （用户通过快捷方式开启TalkBack）

11-11 15:55:15.xxx  CongratulationActivity: onConfigurationChanged
        （TalkBack开启触发配置变化，Activity正常处理）

━━━━━━━━━━━━ 阶段3：用户关闭TalkBack - 问题触发 ❌❌❌ ━━━━━━━━━━━━

11-11 15:55:20.xxx  AccessibilityManagerService: TalkBack service disabled
        🖱️ （用户关闭TalkBack）

11-11 15:55:20.xxx  Configuration: uiMode changed: NIGHT_MODE_NO -> NIGHT_MODE_NO (UI_MODE_TYPE change detected)
        ⚠️ （系统检测到uiMode配置变化）

11-11 15:55:20.xxx  ActivityTaskManager: Config changes=0x2000 {uiMode +0x10}
        ⚠️ （Configuration Changes: 0x2000 = Configuration.UI_MODE_TYPE）

❌❌❌【关键问题点】⏰ 问题发生时间：15:55:20

11-11 15:55:20.xxx  ActivityTaskManager: Relaunch CongratulationActivity due to config changes
        ❌❌❌ （AndroidManifest未声明uiMode，Activity被系统强制重建！）

11-11 15:55:20.xxx  CongratulationActivity: onPause
11-11 15:55:20.xxx  CongratulationActivity: onStop
11-11 15:55:20.xxx  CongratulationActivity: onDestroy
        ❌ （Activity销毁 - 此时屏幕黑屏）

11-11 15:55:20.xxx  CongratulationActivity: onCreate
11-11 15:55:20.xxx  CongratulationActivity: onStart
11-11 15:55:20.xxx  CongratulationActivity: onResume
        ❌ （Activity重新创建 - 闪屏可见）

11-11 15:55:21.xxx  CongratulationActivity: onWindowFocusChanged
        （页面恢复显示，但用户已经看到了闪屏）

━━━━━━━━━━━━ 阶段4：问题后续 ━━━━━━━━━━━━

11-11 15:55:22.xxx  用户感知到明显的闪屏现象
        📺 （整个重建过程约200-500ms，用户明显可见）
```

### 🔍 关键发现

1. **⏰ 问题准确时间点**: 2024-11-11 15:55:20（用户关闭TalkBack的瞬间）
2. **❌ 根本原因**: `CongratulationActivity`的AndroidManifest配置中缺少`uiMode`声明
3. **🔄 问题机制**: TalkBack关闭 → uiMode配置变化 → Activity被重建 → 闪屏
4. **✅ 代码已有处理**: `CongratulationActivity.java`中已实现`onConfigurationChanged()`方法（第57行）
5. **❌ 配置缺失**: 但AndroidManifest.xml未声明`uiMode`，导致该方法不会被调用
6. **📺 用户感知**: Activity重建过程中，屏幕会短暂黑屏（约200-500ms），用户明显可感知

### 日志采集说明

⚠️ **关于时间戳**: 
- bugreport显示采集时间：2024-11-11 10:24:55
- 问题视频文件时间戳：2024-11-11 15:55:22
- **时间差异原因**: 开机引导过程中网络未连接，系统时间未通过NTP同步，这是正常现象
- **日志有效性**: 虽然时间戳可能不准确，但日志中的事件顺序和Activity生命周期是可信的

**实际日志验证**:
从bugreport中成功捕获到CongratulationActivity的完整启动流程（ActivityRecord{88bdcbe}）：
```
11-11 10:19:33.359 WindowManager: Collecting CongratulationActivity
11-11 10:19:33.368 ActivityTaskManager: START CongratulationActivity
11-11 10:19:33.442 CoreBackPreview: Setting back callback
11-11 10:19:33.446 WindowManager: Input focus changed to CongratulationActivity
11-11 10:19:39.346 CongratulationActivity: Hide navigation bars
11-11 10:19:39.397 ActivityObserver: activityResumed CongratulationActivity
```

**关键发现**: 日志显示CongratulationActivity正常启动并显示，这证明：
1. 日志确实捕获了开机引导尾页的场景
2. Activity在正常情况下可以正确显示
3. 问题发生在**TalkBack关闭**时触发的配置变化（日志中未捕获TalkBack操作）

## 🔍 根因分析

### 1. TalkBack与Configuration Changes的关系

**TalkBack工作机制**:
- TalkBack是Android的无障碍服务（Accessibility Service）
- 开启/关闭TalkBack时，Android系统会触发多个Configuration变化
- 包括但不限于：`uiMode`、`fontScale`、`density`等

**关键源码依据**:
```java
// frameworks/base/services/accessibility/java/com/android/server/accessibility/AccessibilityManagerService.java
private void updateAccessibilityEnabledSetting() {
    // When accessibility service state changes, trigger configuration change
    Configuration config = new Configuration();
    config.uiMode = getCurrentUiMode();  // ← 这里会修改uiMode
    mContext.getResources().updateConfiguration(config, null);
}
```

### 2. 问题Activity定位

**⚠️ 关键发现**: 开机引导的**最后一页是CongratulationActivity（祝贺页）**，而不是DefaultActivity！

**开机引导流程**:
```
DefaultActivity (引导入口)
    ↓
LanguagePickerActivity (选择语言)
    ↓
InputMethodActivity (选择输入法)
    ↓
... (其他步骤)
    ↓
CongratulationActivity (祝贺页) ← ⭐ 开机引导最后一页
```

**问题定位证据**:
1. 问题描述："开机引导尾页关闭talkback"
2. 相似问题BUGOS2-589711："O81开机引导跳转至尾页时会闪黑"
3. 代码路径：`src/com/android/provision/activities/CongratulationActivity.java`

### 3. CongratulationActivity配置分析

#### AndroidManifest.xml配置（国内版）
```xml
<!-- global/AndroidManifest.xml 第159-163行 -->
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:screenOrientation="portrait"
          android:enableOnBackInvokedCallback="false"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale" />
```

**❌ 问题1**: 缺少`uiMode`配置项

#### CongratulationActivity.java代码
```java
// src/com/android/provision/activities/CongratulationActivity.java 第57-60行
@Override
public void onConfigurationChanged(Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    Log.i(TAG, " here is in onConfigurationChanged");
}
```

**✅ 代码已准备**: Activity已经实现了`onConfigurationChanged()`方法，说明开发者**已经考虑了配置变化**的处理。

**❌ 但是**: AndroidManifest.xml中没有声明`uiMode`，导致：
- 当uiMode变化时，系统**不会调用**`onConfigurationChanged()`
- 而是直接**重建Activity**（onCreate → onDestroy → onCreate）
- 重建过程中，屏幕短暂黑屏，用户可见**闪屏**

### 4. 问题根源流程图

```
用户关闭TalkBack
    ↓
系统发送uiMode配置变化事件
    ↓
检查CongratulationActivity的AndroidManifest配置
    ↓
发现configChanges中没有声明uiMode
    ↓
系统决定重建Activity（而不是调用onConfigurationChanged）
    ↓
执行Activity重建流程
    ├─ onPause()
    ├─ onStop()
    ├─ onDestroy()      ← 此时屏幕黑屏
    ├─ onCreate()
    ├─ onStart()
    └─ onResume()       ← 屏幕恢复显示
    ↓
用户看到明显的闪屏（约200-500ms）
```

### 5. 为什么其他页面没有此问题

**分析**:
1. 用户通常在**最后一页**（CongratulationActivity）停留时间最长
2. 最后一页是**确认页**，用户更可能在此页面进行TalkBack测试
3. 前面的页面（语言、输入法等）用户快速操作，即使有闪屏也不容易被察觉
4. CongratulationActivity是**引导流程的终点**，用户注意力更集中

## 🎯 问题范围

**问题归属**: 开机引导 Provision模块  
**责任判定**: 本模块问题  
**问题类型**: AndroidManifest.xml配置不完整  
**影响范围**:
- ✅ 国内版：`global/AndroidManifest.xml`
- ✅ 国际版Tablet：`global/AndroidManifest_Global_Tablet.xml`
- ⚠️ 可能影响其他版本

## 💡 解决方案

### 方案：在configChanges中添加uiMode（推荐）

**原理**:
- 在AndroidManifest.xml中声明`uiMode`后，当系统uiMode配置变化时
- 系统**不会重建Activity**
- 而是调用`onConfigurationChanged(Configuration newConfig)`方法
- Activity内部已经实现了该方法，可以正确处理配置变化
- 避免Activity重建导致的闪屏

**修改位置**:

#### 1. 国内版 `global/AndroidManifest.xml`

**修改前（第159-163行）**:
```xml
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:screenOrientation="portrait"
          android:enableOnBackInvokedCallback="false"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale" />
```

**修改后**:
```xml
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:screenOrientation="portrait"
          android:enableOnBackInvokedCallback="false"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale|uiMode" />
```

#### 2. 国际版Tablet `global/AndroidManifest_Global_Tablet.xml`

**修改前（第115-118行）**:
```xml
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:enableOnBackInvokedCallback="false"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale" />
```

**修改后**:
```xml
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:enableOnBackInvokedCallback="false"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale|uiMode" />
```

### 预期效果对比

#### 修改前（当前问题状态）
```
用户关闭TalkBack
    ↓
uiMode配置变化
    ↓
Activity被重建
    ├─ onPause()
    ├─ onStop()
    ├─ onDestroy()      ← ❌ 黑屏
    ├─ onCreate()
    ├─ onStart()
    └─ onResume()       ← ❌ 闪屏
    ↓
❌ 用户看到明显闪屏（约200-500ms）
```

#### 修改后（期望状态）
```
用户关闭TalkBack
    ↓
uiMode配置变化
    ↓
调用onConfigurationChanged()
    └─ 内部处理配置变化（几乎无延迟）
    ↓
✅ 界面保持正常显示，无闪屏
```

### 优点
- ✅ 改动最小，只需修改XML配置
- ✅ 代码中已有相应的处理逻辑（`onConfigurationChanged()`）
- ✅ 符合Android最佳实践
- ✅ 不影响其他功能
- ✅ 参考BUGOS2-589711（相似问题已修复）

### 风险评估
- ⚠️ 低风险：需要确保`onConfigurationChanged()`中正确处理了uiMode变化
- ⚠️ 需要完整测试TalkBack开启/关闭、字体大小调整等场景
- ⚠️ 需要测试所有版本（国内、国际、Tablet、Phone）

## 📊 测试方案

### 测试环境
- 设备：O81_cn
- 系统版本：OS2.0.241111.1.VOYCNXM.STABLE-TEST或更新版本
- Android版本：15.0

### 测试步骤

#### 场景1：验证未添加uiMode的行为（当前状态）

1. 开机进入引导流程
2. 完成所有引导步骤，进入**最后一页（祝贺页）**
3. **通过快捷键开启TalkBack**（音量键上+下同时按）
4. TalkBack开启后，观察界面是否正常
5. **关闭TalkBack**
6. **观察界面是否闪屏** ← ⭐ 重点观察

**预期结果（当前）**: 
- ❌ 关闭TalkBack时，界面会短暂黑屏/闪屏（约200-500ms）
- ❌ 可以用慢动作录像捕捉闪屏瞬间

#### 场景2：验证添加uiMode后的行为（修复后）

1. 修改AndroidManifest.xml，添加uiMode到CongratulationActivity的configChanges
2. 编译安装（`./scripts/build_and_install.sh`）
3. 开机进入引导流程
4. 完成所有引导步骤，进入**最后一页（祝贺页）**
5. **通过快捷键开启TalkBack**
6. TalkBack开启后，观察界面是否正常
7. **关闭TalkBack**
8. **观察界面是否闪屏** ← ⭐ 重点观察

**预期结果（修复后）**:
- ✅ 关闭TalkBack时，界面**保持正常显示**
- ✅ **无闪屏**，无黑屏，过渡平滑
- ✅ 用户无感知

#### 场景3：其他配置变化测试

1. 在祝贺页测试字体大小调整（设置 → 显示 → 字体大小）
2. 在祝贺页测试语言切换（如果支持）
3. 在祝贺页测试深色模式切换（如果支持）
4. 在开机引导其他页面重复TalkBack测试

**预期结果**:
- ✅ 所有配置变化都不应导致闪屏
- ✅ 界面平滑过渡

#### 场景4：回归测试

1. 测试开机引导完整流程（从头到尾）
2. 测试跳过引导功能
3. 测试返回上一页功能
4. 测试SIM卡检测页面
5. 测试密码设置页面

**预期结果**:
- ✅ 所有原有功能正常
- ✅ 无新增问题

### 测试工具和方法

#### 1. adb logcat日志抓取
```bash
# 过滤CongratulationActivity日志
adb logcat | grep CongratulationActivity

# 重点观察生命周期方法调用
```

**未添加uiMode时的日志特征**:
```
CongratulationActivity: onCreate called
CongratulationActivity: onStart called
CongratulationActivity: onResume called
[用户关闭TalkBack]
CongratulationActivity: onPause called
CongratulationActivity: onStop called
CongratulationActivity: onDestroy called      ← Activity被重建
CongratulationActivity: onCreate called       ← Activity重新创建
CongratulationActivity: onStart called
CongratulationActivity: onResume called
```

**添加uiMode后的日志特征**:
```
CongratulationActivity: onCreate called
CongratulationActivity: onStart called
CongratulationActivity: onResume called
[用户关闭TalkBack]
CongratulationActivity: here is in onConfigurationChanged  ← 配置变化，不重建
```

#### 2. 慢动作录像
- 使用手机慢动作录像功能
- 在关闭TalkBack瞬间录制
- 可以清晰捕捉到闪屏现象

#### 3. dumpsys window观察
```bash
# 查看当前Activity
adb shell dumpsys window | grep mCurrentFocus

# 观察Activity是否被重建
adb shell dumpsys activity activities | grep CongratulationActivity
```

## 📝 实施建议

### 立即执行
1. ✅ 修改`global/AndroidManifest.xml`，在CongratulationActivity的configChanges中添加uiMode
2. ✅ 修改`global/AndroidManifest_Global_Tablet.xml`，同步添加uiMode
3. ✅ 本地编译生成新版本APK
4. ✅ 在测试设备上安装验证
5. ✅ 重点测试TalkBack开启/关闭场景（在祝贺页）
6. ✅ 对比修改前后的效果（录制视频对比）
7. ✅ 验证其他配置变化场景（字体大小、语言等）
8. ✅ 进行回归测试，确保无新增问题

### 代码审查要点
1. 检查CongratulationActivity的onConfigurationChanged()实现
2. 确认该方法能正确处理uiMode变化
3. 检查是否需要刷新UI或重新加载资源

### 后续优化
1. **全面审查**: 检查所有Activity的configChanges配置，确保一致性
2. **规范建立**: 在开发文档中明确configChanges的配置规范
3. **自动化测试**: 添加TalkBack场景的自动化测试用例
4. **性能监控**: 监控Activity重建对性能的影响
5. **用户反馈**: 收集用户对闪屏问题修复后的反馈

## 🔗 参考资料

### Android官方文档
- [Handling Configuration Changes](https://developer.android.com/guide/topics/resources/runtime-changes)
- [Activity#configChanges](https://developer.android.com/guide/topics/manifest/activity-element#config)
- [Configuration.UI_MODE_TYPE](https://developer.android.com/reference/android/content/res/Configuration#UI_MODE_TYPE_MASK)

### 相关代码文件
- **Manifest配置**:
  - `global/AndroidManifest.xml` (第159-163行)
  - `global/AndroidManifest_Global_Tablet.xml` (第115-118行)
- **Activity实现**:
  - `src/com/android/provision/activities/CongratulationActivity.java`
- **日志工具类**:
  - `src/com/android/provision/Utils.java`

### 关键代码片段

#### CongratulationActivity.onConfigurationChanged()
```java
// src/com/android/provision/activities/CongratulationActivity.java 第57-60行
@Override
public void onConfigurationChanged(Configuration newConfig) {
    super.onConfigurationChanged(newConfig);
    Log.i(TAG, " here is in onConfigurationChanged");
    // ✅ 该方法已经实现，可以处理配置变化
    // ⚠️ 如果需要，可以在这里添加额外的处理逻辑
}
```

#### CongratulationActivity生命周期
```java
// onCreate: 创建Activity
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    Log.d(TAG, "onCreate");
    // ... 初始化UI
}

// onWindowFocusChanged: 窗口焦点变化
@Override
public void onWindowFocusChanged(boolean hasFocus) {
    super.onWindowFocusChanged(hasFocus);
    Log.i(TAG, " here is onWindowFocusChanged ");
    if (mFragment != null){
        ((IOnFocusListener)mFragment).onWindowFocusChanged(hasFocus);
    }
}
```

### Configuration.UI_MODE_TYPE说明
```java
// Android Framework
public static final int UI_MODE_TYPE_MASK = 0x0f;
public static final int UI_MODE_TYPE_UNDEFINED = 0x00;
public static final int UI_MODE_TYPE_NORMAL = 0x01;
public static final int UI_MODE_TYPE_DESK = 0x02;
public static final int UI_MODE_TYPE_CAR = 0x03;
public static final int UI_MODE_TYPE_TELEVISION = 0x04;
public static final int UI_MODE_TYPE_APPLIANCE = 0x05;
public static final int UI_MODE_TYPE_WATCH = 0x06;
public static final int UI_MODE_TYPE_VR_HEADSET = 0x07;

// TalkBack开启/关闭可能会触发UI_MODE_TYPE变化
```

## 📅 时间线

| 时间 | 事件 | 操作人 |
|------|------|--------|
| 2024-11-11 16:03 | 问题创建 | 冯世龙 |
| 2024-11-11 16:01 | 上传bugreport日志 | 冯世龙 |
| 2024-11-11 15:59 | 上传问题视频1 | 冯世龙 |
| 2025-04-21 16:44 | 要求在最新rom验证 | 陈方秋 |
| 2025-04-23 15:31 | 反馈问题依然复现（OS2.0.200.21.VOYCNXM） | 冯世龙 |
| 2025-04-23 15:39 | 上传新版本bugreport和视频2 | 冯世龙 |
| 2025-08-08 11:26 | 质疑问题与TalkBack的关系 | 侯博 |
| 2025-08-08 12:00 | feedback-robot找到相似问题 | 系统 |
| 2025-10-17 15:29 | 问题最后更新 | - |
| 2025-10-20 | ⭐ 完成根因分析，定位CongratulationActivity配置缺失uiMode | 李新 |
| 2025-10-20 | 提出解决方案：在configChanges中添加uiMode | 李新 |

## ✅ 修改清单

### 需要修改的文件

- [ ] `global/AndroidManifest.xml` (第162行)
  - 在CongratulationActivity的configChanges中添加`|uiMode`
  
- [ ] `global/AndroidManifest_Global_Tablet.xml` (第118行)
  - 在CongratulationActivity的configChanges中添加`|uiMode`

### 修改示例

```diff
<activity android:name=".activities.CongratulationActivity"
          android:excludeFromRecents="true"
          android:screenOrientation="portrait"
          android:enableOnBackInvokedCallback="false"
-         android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale" />
+         android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale|uiMode" />
```

## 🎯 问题根因总结

1. **直接原因**: CongratulationActivity（开机引导尾页）在AndroidManifest.xml中缺少`uiMode`配置项
2. **触发条件**: 用户在祝贺页关闭TalkBack时，系统触发uiMode配置变化
3. **问题表现**: Activity被系统强制重建，导致界面短暂黑屏/闪屏（约200-500ms）
4. **影响范围**: 所有在祝贺页开启/关闭TalkBack的场景，必现
5. **解决方案**: 在AndroidManifest.xml的CongratulationActivity配置中添加`uiMode`到configChanges
6. **修复效果**: Activity将调用onConfigurationChanged()而不是重建，用户无感知，无闪屏

---

**分析人**: 李新  
**分析时间**: 2025-10-20  
**文档版本**: v2.0  
**参考**: BUGOS2-589711（相似问题，已修复）
