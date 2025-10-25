---
layout: default
title: OemPostActivity Crash 根因分析
parent: MiuiProvision项目文档
---

# OemPostActivity Crash 根因分析

## 问题基本信息

- 日志路径: `logs/bug1/bugreport-annibale_eea-BP2A.250605.031.A3-2025-10-17-10-41-47.txt`
- 机型: annibale (POCO F8 Pro)
- ROM版本: OS3.0.0.9.WPKEUXM (国际版)
- 发生时间: 2025-10-17 10:41:06.857
- 崩溃进程: com.android.provision (PID: 14697)
- 崩溃Activity: OemPostActivity

## Crash堆栈信息

```
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: FATAL EXCEPTION: main
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: Process: com.android.provision, PID: 14697
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: java.lang.RuntimeException: Unable to start activity ComponentInfo{com.android.provision/com.android.provision.global.OemPostActivity}: android.content.ActivityNotFoundException: No Activity found to handle Intent { act=com.android.wizard.NEXT xflg=0x4 (has extras) }
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:4703)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.ActivityThread.handleLaunchActivity(ActivityThread.java:4933)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.ActivityThread.handleRelaunchActivityInner(ActivityThread.java:7170)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.ActivityThread.handleRelaunchActivity(ActivityThread.java:7061)
...
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: Caused by: android.content.ActivityNotFoundException: No Activity found to handle Intent { act=com.android.wizard.NEXT xflg=0x4 (has extras) }
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.Instrumentation.checkStartActivityResult(Instrumentation.java:2490)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.Instrumentation.execStartActivity(Instrumentation.java:2025)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at android.app.Activity.startActivityForResult(Activity.java:6155)
...
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at com.android.provision.Utils.goToNextPage(SourceFile:929)
10-17 10:41:06.857  1000 14697 14697 E AndroidRuntime: 	at com.android.provision.global.OemPostActivity.onCreate(SourceFile:58)
```

## 关键日志时间线

```log
10-17 10:41:06.432  启动OemPostActivity
1000  3246  7901 I CamOpt_Service: notifyActivityStart: intent = Intent { act=com.android.setupwizard.OEM_POST_SETUP flg=0x4000000 xflg=0x4 (has extras) }

10-17 10:41:06.437  ActivityTaskManager记录启动
1000  3246  7901 I ActivityTaskManager: START u0 {act=com.android.setupwizard.OEM_POST_SETUP flg=0x4000000 xflg=0x4 cmp=com.android.provision/.global.OemPostActivity (has extras)} with LAUNCH_MULTIPLE from uid 10271 from pid 7204 callingPackage com.google.android.setupwizard

10-17 10:41:06.443  OemPostActivity.onCreate开始执行
1000 14697 14697 D OemPostActivity: onCreate:

10-17 10:41:06.443  预加载管理器运行
1000 14697 14697 D PreLoadLog: PreLoadManager run:class com.android.provision.global.OemPostActivity

10-17 10:41:06.857  Crash发生
1000 14697 14697 E AndroidRuntime: FATAL EXCEPTION: main
1000 14697 14697 E AndroidRuntime: Process: com.android.provision, PID: 14697
1000 14697 14697 E AndroidRuntime: Caused by: android.content.ActivityNotFoundException: No Activity found to handle Intent { act=com.android.wizard.NEXT xflg=0x4 (has extras) }
```

## 代码分析

### OemPostActivity.onCreate (第58行)

```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    Log.d(TAG, "onCreate: ");
    super.onCreate(savedInstanceState);
    CspAutoSwitchManager.checkTailLandRing(getApplicationContext());
    Utils.enableStatusBar(this, true);
    ImmersiveUtils.disableImmersion(this);
    setAlarm();
    Utils.sendProvisionCompleteBroadcast(this);
    // ... 其他代码 ...
    
    Utils.goToNextPage(this, getIntent(), RESULT_OK);  // 第58行 - 崩溃点
    // ... 后续代码 ...
    finish();
}
```

### Utils.goToNextPage (第923-930行)

```java
public static void goToNextPage(android.app.Activity activity, Intent originIntent, int resultCode) {
    int arbitraryRequestCode = REQUEST_CODE_BACK_FROM_GOOGLE_WIZARD;
    if (activity == null || originIntent == null) {
        throw new IllegalArgumentException("fragment or originIntent cannot be null when go to next page in SetupWizard");
    }
    Intent nextIntent = WizardManagerHelper.getNextIntent(originIntent, resultCode);
    activity.startActivityForResult(nextIntent, arbitraryRequestCode);  // 第929行 - 崩溃点
}
```

### WizardManagerHelper.getNextIntent (第16-30行)

```java
public static Intent getNextIntent(Intent originalIntent, int resultCode, Intent data) {
    Intent intent = new Intent(ACTION_NEXT);  // ACTION_NEXT = "com.android.wizard.NEXT"
    copyWizardManagerExtras(originalIntent, intent);
    intent.putExtra(EXTRA_RESULT_CODE, resultCode);
    if (data != null && data.getExtras() != null) {
        intent.putExtras(data.getExtras());
    }
    intent.putExtra(EXTRA_THEME, originalIntent.getStringExtra(EXTRA_THEME));
    return intent;
}
```

## 根因分析

### 问题本质

OemPostActivity在onCreate时直接调用`Utils.goToNextPage()`创建了一个隐式Intent（action=`com.android.wizard.NEXT`），期望由Google SetupWizard的WizardManagerActivity来处理。但是在这个时间点，系统中**没有任何Activity能够处理这个Intent**，导致ActivityNotFoundException。

### 为什么WizardManagerActivity无法处理Intent

从日志可以看出，在10:41:06之前，WizardManagerActivity一直在正常处理`com.android.wizard.NEXT` Intent。关键问题在于：

1. **OemPostActivity是作为开机引导流程的最后一步**被SetupWizard启动的
2. **SetupWizard可能已经结束了引导流程**，不再监听`com.android.wizard.NEXT` action
3. **OemPostActivity尝试返回到已经不存在的SetupWizard流程**

### Intent声明问题

查看AndroidManifest中的WizardManagerActivity声明，可能存在以下情况之一：
- WizardManagerActivity的intent-filter可能有条件限制（如特定的category或data）
- SetupWizard在OEM_POST_SETUP阶段后已经disable了对NEXT action的监听
- Intent传递的extras不完整，导致WizardManagerActivity无法匹配

### 设计缺陷

OemPostActivity的设计存在问题：

```java
Utils.goToNextPage(this, getIntent(), RESULT_OK);  // 尝试跳转到下一页
finish();  // 立即finish自己
```

这种设计假设：
1. 一定存在"下一页"可以跳转
2. SetupWizard一定还在运行并能处理NEXT Intent

但实际上，作为开机引导的最后一个Activity，OemPostActivity**不应该尝试跳转到下一页**，而应该：
1. 完成自己的收尾工作
2. 直接finish
3. 让系统自然进入桌面

## 解决方案

### 方案1：捕获异常并处理（推荐）

在OemPostActivity.onCreate中添加try-catch，如果goToNextPage失败，直接finish：

```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    Log.d(TAG, "onCreate: ");
    super.onCreate(savedInstanceState);
    // ... 现有代码 ...
    
    try {
        Utils.goToNextPage(this, getIntent(), RESULT_OK);
    } catch (ActivityNotFoundException e) {
        // 如果没有下一页可以跳转（已经是最后一步），直接finish
        Log.w(TAG, "No next page found, this is the last step of setup wizard", e);
    }
    
    finish();
    Utils.abnormalFlowFinishedTag = true;
}
```

### 方案2：检查Intent有效性

在调用goToNextPage之前，检查Intent是否包含必要的extras：

```java
Intent originIntent = getIntent();
if (originIntent != null && originIntent.hasExtra("scriptUri")) {
    try {
        Utils.goToNextPage(this, originIntent, RESULT_OK);
    } catch (ActivityNotFoundException e) {
        Log.w(TAG, "Cannot navigate to next page", e);
    }
} else {
    Log.i(TAG, "No scriptUri in intent, skip goToNextPage");
}
finish();
```

### 方案3：修改goToNextPage方法

在Utils.goToNextPage中添加Intent可解析性检查：

```java
public static void goToNextPage(android.app.Activity activity, Intent originIntent, int resultCode) {
    int arbitraryRequestCode = REQUEST_CODE_BACK_FROM_GOOGLE_WIZARD;
    if (activity == null || originIntent == null) {
        throw new IllegalArgumentException("fragment or originIntent cannot be null when go to next page in SetupWizard");
    }
    
    Intent nextIntent = WizardManagerHelper.getNextIntent(originIntent, resultCode);
    
    // 检查是否有Activity可以处理这个Intent
    PackageManager pm = activity.getPackageManager();
    if (nextIntent.resolveActivity(pm) != null) {
        activity.startActivityForResult(nextIntent, arbitraryRequestCode);
    } else {
        Log.w(TAG, "No activity found to handle next intent, skip navigation");
    }
}
```

## 影响范围

这个问题会导致：
1. 开机引导流程在最后一步崩溃
2. 用户可能无法正常完成开机引导
3. 需要重启设备重新进入引导流程

## 复现步骤

从日志分析，这个问题在以下场景下必现：
1. 国际版ROM
2. 走完整个Google SetupWizard流程
3. 到达OemPostActivity（开机引导的最后一步）
4. OemPostActivity尝试调用goToNextPage时crash

## 测试建议

修复后需要测试：
1. 完整走完开机引导流程，确保能正常进入桌面
2. 测试OemPostActivity是否正确处理"无下一页"的情况
3. 测试各种引导流程场景（有/无Google账号、有/无网络等）

## 相关文件

- `src/com/android/provision/global/OemPostActivity.java` (第58行)
- `src/com/android/provision/Utils.java` (第923-930行)
- `src/com/android/provision/global/WizardManagerHelper.java` (第16-30行)
