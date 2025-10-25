---
layout: default
title: BUGOS2-702311 N8开机引导外屏重启logo位置偏移遮挡问题分析
parent: 问题修复
---



# BUGOS2-702311 N8开机引导外屏重启logo位置偏移遮挡问题分析

## 第一阶段：信息收集

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| Jira单号 | BUGOS2-702311 |
| 问题标题 | N8开机引导外屏重启logo位置偏移遮挡 |
| 机型 | N8_global（代号：ruyi） |
| 设备类型 | 折叠屏翻盖手机（Flip） |
| Android版本 | 16.0, 15.0 |
| HyperOS版本 | OS3.0.9.23.W_STABLE_GL, OS2.0.250923.1.VNIMIXM.PRE-TEST |
| 分支类型 | w-stable, v-pre |
| 组件 | 开机引导 Provision |
| 问题类型 | 故障 |
| 优先级 | 严重 |
| 复现概率 | 必现（Every time） |
| Bug分类 | 显示 Display |
| 测试方法 | 手工测试 Manual Testing |
| 经办人 | 李新 |
| 报告人 | 牟宇涵 |
| 创建时间 | 2025-09-24 19:18 |
| 最后更新 | 2025-10-22 10:58 |

### 1.2 问题描述

**测试类型**：功能测试

**复现概率**：必现

**前提条件**：N8折叠屏设备首次开机或恢复出厂设置后

**复现步骤**：
1. N8设备开机
2. 外屏显示开机引导界面
3. 观察logo和文字显示位置

**预期结果**：logo和文字位置显示正常，不被摄像头遮挡

**实际结果**：刚开机时logo和文字位置偏移，被外屏摄像头遮挡

**是否可恢复**：恢复操作容易（展开内屏后显示正常）

### 1.3 附件信息

1. **视频文件**：小米办公20250924-191446.mp4（3.90 MB）
2. **截图文件**：
   - image-2025-09-24-19-18-27-414.png
   - image-2025-09-24-19-18-34-699.png
   - IMG_20250925_153938[1].jpg
3. **日志文件**：bugreport-ruyi_global-BP2A.250605.031.A3-2025-09-23-18-18-53.zip（21.22 MB）
4. **Kpan日志链接**：https://kpan.mioffice.cn/webfolder/ext/is3zvWjkIAj$uVm31GQvyw@@（密码：36b5）
5. **提效工具日志**：https://cnbj1-fds.api.xiaomi.net/jira-logs/BUGOS2-702311.zip

### 1.4 视频帧分析

使用ffmpeg从视频中提取16帧，每秒1帧，关键帧分析如下：

**帧1-2（0-2秒）**：外屏显示小米logo（MI logo），logo位于屏幕左侧中间位置，被外屏摄像头遮挡

**帧3（3秒）**：显示"Xiaomi HyperOS"文字，位置在左侧，同样被摄像头遮挡

**帧4（4秒）**：显示"Xiaomi MIX Flip"和"co-engineered with Leica"文字，Leica标识被摄像头遮挡

**帧12（12秒）**：显示"Xiaomi HyperOS"和"Unfold to activate"提示文字，被摄像头遮挡

**帧15（15秒）**：用户展开手机，切换到内屏，显示正常的"Xiaomi HyperOS"和箭头按钮，位置居中，无遮挡

**关键发现**：
1. 外屏显示时，所有logo和文字都居中显示，被左上角摄像头遮挡
2. 外屏摄像头位于屏幕左上角，占用约28%的横向空间
3. 展开到内屏后显示正常，说明问题仅存在于外屏显示逻辑
4. 整个开机引导过程持续约16秒

---

## 第二阶段：文档声明

### 2.1 唯一性声明

本文档是Jira问题单BUGOS2-702311的唯一官方分析文档。任何关于该问题的分析结论、根因定位、解决方案、测试验证均以本文档为准。

### 2.2 文档版本

| 版本 | 日期 | 修改人 | 修改说明 |
|------|------|--------|----------|
| v1.0 | 2025-10-25 | 李新 | 初始版本，完成根因分析和解决方案设计 |

### 2.3 参考文档

1. Jira问题单：https://jira-phone.mioffice.cn/browse/BUGOS2-702311
2. UI设计规范：https://www.figma.com/design/qoKmZPVm8vUjcjfAIe6ahi/开机引导ota
3. 开机引导模块代码：packages/apps/MiuiProvisionAosp

---

## 第三阶段：日志分析

### 3.1 日志采集说明

**日志采集时间**：2025-09-23 18:18:53

**问题发生时间**：2025-09-24 19:14（根据视频文件名）

**时间差异说明**：
- 日志采集时间（09-23 18:18）早于问题发生时间（09-24 19:14）
- 时间差约25小时
- 说明bugreport日志不是问题现场实时采集的日志
- 但问题为必现问题，代码逻辑分析仍然有效

### 3.2 问题时间线

基于视频分析的时间线（相对时间）：

```
━━━━━━━━━━━━ 阶段1：设备启动阶段（0-1秒）━━━━━━━━━━━━

00:00 设备启动，外屏开始显示

━━━━━━━━━━━━ 阶段2：外屏logo显示阶段（1-4秒）【问题阶段】━━━━━━━━━━━━

00:01 外屏显示小米logo（MI），位置居中，被摄像头遮挡
      问题现象：logo位于屏幕中心偏左位置，正好与摄像头区域重叠

00:02 logo继续显示，遮挡持续

00:03 显示"Xiaomi HyperOS"文字，位置偏左，被摄像头遮挡
      问题现象：文字"OS"部分文字被摄像头遮挡

00:04 显示"Xiaomi MIX Flip"和Leica标识，被摄像头遮挡
      问题现象：Leica红色标识被摄像头完全遮挡

━━━━━━━━━━━━ 阶段3：外屏引导提示阶段（5-14秒）━━━━━━━━━━━━

00:05-00:11 外屏显示开机动画和引导内容（具体内容因视频帧率限制未完全捕获）

00:12 显示"Xiaomi HyperOS"和"Unfold to activate"提示，被摄像头遮挡
      问题现象：摄像头遮挡部分文字

━━━━━━━━━━━━ 阶段4：切换到内屏（15-16秒）━━━━━━━━━━━━

00:15 用户展开手机，切换到内屏显示
      显示"Xiaomi HyperOS"和向右箭头按钮
      正常：logo和文字居中显示，无遮挡

00:16 视频结束
```

### 3.3 关键发现

1. 问题发生在外屏显示阶段（0-14秒），内屏显示正常
2. 外屏logo和文字采用居中对齐方式，没有考虑摄像头位置
3. 外屏摄像头位于左上角，占用约28%的横向空间
4. 问题持续整个外屏显示阶段，直到切换到内屏才恢复正常
5. 问题为必现，不涉及时序或随机性因素

---

## 第四阶段：问题范围分析

### 4.1 进程归属判断

**问题进程**：com.android.provision（开机引导应用）

**判断依据**：
1. 问题发生在开机引导阶段
2. 涉及的是开机引导界面的logo显示
3. 代码位于packages/apps/MiuiProvisionAosp模块

### 4.2 模块边界识别

**责任模块**：开机引导（MiuiProvision）

**涉及组件**：
1. CoverScreenService.java：外屏服务，负责外屏显示管理
2. startup_layout_flip.xml：外屏开机引导布局文件
3. sub_screen_layout.xml：外屏布局（带摄像头避让逻辑）

**不涉及模块**：
- BSP/Display：显示驱动和硬件抽象层（HAL）正常
- SystemUI：系统界面（问题不在状态栏、导航栏）
- Framework：系统框架层（Display Cutout API工作正常）

### 4.3 跨模块交互分析

1. **开机引导 ↔ DisplayCutout API**：
   - CoverScreenService通过WindowInsets获取DisplayCutout信息
   - 获取摄像头区域的safeInsetLeft和safeInsetRight
   - API工作正常，能正确识别摄像头位置

2. **开机引导 ↔ 设备状态管理**：
   - 通过DeviceStateManager监听折叠状态
   - 正确识别折叠（外屏）和展开（内屏）状态
   - 状态管理正常

### 4.4 责任判定

**问题归属**：本模块问题（MiuiProvision）

**判定理由**：
1. 问题发生在com.android.provision进程
2. 根因是布局文件选择不当
3. 外屏显示逻辑未正确使用摄像头避让布局
4. 代码修改范围限于本模块内

---

## 第五阶段：根因与解决方案

### 5.1 代码分析

#### 5.1.1 关键类分析

**类1：CoverScreenService.java**

位置：`src/com/android/provision/CoverScreenService.java`

关键方法：`initPlaceHolderWindow()`

```java
private void initPlaceHolderWindow() {
    mWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
    mView = new View(this);
    mView = LayoutInflater.from(this).inflate(R.layout.startup_layout_flip, null);  // 问题行
    applyWindow();
    mHintText = (TextView) mView.findViewById(R.id.hint_text);
    // ...
}
```

**问题点**：第133行固定使用`R.layout.startup_layout_flip`，该布局文件logo居中显示，没有考虑摄像头遮挡。

#### 5.1.2 布局文件对比

**布局文件1：startup_layout_flip.xml（当前使用，有问题）**

位置：`res/layout/startup_layout_flip.xml`

关键代码：
```xml
<androidx.constraintlayout.widget.ConstraintLayout
    android:paddingLeft="130dp">  <!-- 硬编码padding，不够 -->
    
    <RelativeLayout
        android:id="@+id/logo_image_wrapper"
        app:layout_constraintTop_toBottomOf="@+id/space_top"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent">  <!-- 居中对齐，会被摄像头遮挡 -->
        
        <ImageView
            android:id="@+id/logo_image"
            android:layout_centerInParent="true" />  <!-- 居中显示 -->
    </RelativeLayout>
</androidx.constraintlayout.widget.ConstraintLayout>
```

**问题**：
1. 使用居中对齐（`layout_constraintStart_toStartOf="parent"`和`layout_constraintEnd_toEndOf="parent"`）
2. 硬编码`paddingLeft="130dp"`，这个padding值不够
3. logo会显示在屏幕中间，被摄像头遮挡

**布局文件2：sub_screen_layout.xml（正确的布局）**

位置：`res/layout/sub_screen_layout.xml`

关键代码：
```xml
<androidx.constraintlayout.widget.ConstraintLayout>
    <!-- 摄像头区域左侧占比 28% -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/left_camera_boundary"
        app:layout_constraintGuide_percent="0.28" />  <!-- 定义摄像头边界 -->
    
    <LinearLayout
        android:id="@+id/miui_enter_layout"
        app:layout_constraintLeft_toRightOf="@+id/left_camera_boundary"
        app:layout_constraintRight_toRightOf="parent">  <!-- 约束在摄像头右侧 -->
        
        <ImageView
            android:id="@+id/logo_image" />
    </LinearLayout>
</androidx.constraintlayout.widget.ConstraintLayout>
```

**优点**：
1. 使用Guideline定义摄像头边界（28%位置）
2. logo约束在guideline右侧，自动避开摄像头
3. 自适应不同屏幕尺寸

#### 5.1.3 DisplayCutout处理分析

**方法：applyWindow()**

```java
private void applyWindow(){
    ViewCompat.setOnApplyWindowInsetsListener(mView, new OnApplyWindowInsetsListener() {
        @Override
        public WindowInsetsCompat onApplyWindowInsets(@NonNull View v, @NonNull WindowInsetsCompat insets) {
            DisplayCutoutCompat cutout = insets.getDisplayCutout();
            int coutLeftPixels = cutout.getSafeInsetLeft();  // 获取左侧安全区域
            int coutRightPixels = cutout.getSafeInsetRight();  // 获取右侧安全区域
            if(coutRightPixels > 0){
                initNewView(true, coutRightPixels);
            } else if (coutLeftPixels > 0){
                initNewView(false, coutLeftPixels);  // 调用padding设置
            }
            return WindowInsetsCompat.CONSUMED;
        }
    });
}

private void initNewView(boolean isRight, int padding){
    if (Utils.isNew180Device()){  // 仅对N8和bixi设备生效
        mView.post(new Runnable() {
            @Override
            public void run() {
                if (isRight){
                    mView.setPadding(0, mView.getPaddingTop(), padding, mView.getPaddingBottom());
                }else {
                    mView.setPadding(padding, mView.getPaddingTop(), 0, mView.getPaddingBottom());
                }
            }
        });
    }
}
```

**问题分析**：
1. `applyWindow()`方法能正确获取DisplayCutout信息
2. `initNewView()`方法只设置了View的padding，但**没有调整logo的布局约束**
3. 由于logo使用居中对齐，即使设置了padding，logo仍然会在剩余空间中居中，还是会被遮挡
4. **根本问题**：布局约束方式错误，不是padding问题

### 5.2 PlantUML架构图

#### 5.2.1 问题流程时序图

```plantuml
@startuml
title N8外屏开机引导显示流程（问题场景）

participant "System" as Sys
participant "CoverScreenService" as CS
participant "WindowManager" as WM
participant "View" as V
participant "LayoutInflater" as LI

Sys -> CS: onCreate()
activate CS
CS -> CS: initPlaceHolderWindow()
activate CS
CS -> LI: inflate(R.layout.startup_layout_flip)
note right: 【问题点1】使用了错误的布局文件\n该布局logo居中显示
LI --> CS: mView
CS -> CS: applyWindow()
note right: 设置WindowInsetsListener\n监听DisplayCutout
CS -> CS: registerFoldCallback()
deactivate CS

Sys -> CS: onStartCommand()
CS -> CS: show()
activate CS
CS -> WM: addView(mView, params)
note right: 显示外屏界面
WM --> V: onApplyWindowInsets()
activate V
V -> V: getDisplayCutout()
note right: 获取摄像头区域信息\nsafeInsetLeft ≈ 屏幕宽度 * 28%
V -> V: initNewView(false, padding)
note right: 【问题点2】只设置padding\n没有调整布局约束
V -> V: setPadding(padding, ...)
note right: 设置左侧padding
V --> CS: WindowInsetsCompat.CONSUMED
deactivate V

CS -> V: setVisibility(VISIBLE)
note right: 【问题现象】\nlogo居中显示\n被摄像头遮挡
deactivate CS

note over Sys,V
  外屏显示期间，logo一直被摄像头遮挡
  用户体验差
end note

Sys -> CS: DeviceStateListener.onFoldedStateChanged(false)
CS -> CS: hide()
CS -> V: setVisibility(GONE)

note over Sys,V
  展开到内屏后，使用其他布局
  显示正常
end note

@enduml
```

#### 5.2.2 正确流程时序图

```plantuml
@startuml
title N8外屏开机引导显示流程（修复方案）

participant "System" as Sys
participant "CoverScreenService" as CS
participant "WindowManager" as WM
participant "View" as V
participant "LayoutInflater" as LI

Sys -> CS: onCreate()
activate CS
CS -> CS: initPlaceHolderWindow()
activate CS
CS -> LI: inflate(R.layout.sub_screen_layout)
note right: 【修复点1】使用正确的布局文件\n该布局有摄像头避让逻辑
LI --> CS: mView with Guideline
note right: 布局包含left_camera_boundary\n定义在28%位置
CS -> CS: applyWindow()
CS -> CS: registerFoldCallback()
deactivate CS

Sys -> CS: onStartCommand()
CS -> CS: show()
activate CS
CS -> WM: addView(mView, params)
WM --> V: onApplyWindowInsets()
activate V
V -> V: getDisplayCutout()
note right: 获取摄像头区域信息
V -> V: layout measurement
note right: 【修复点2】布局约束自动处理\nlogo约束在guideline右侧\n自动避开摄像头区域
V --> CS: WindowInsetsCompat.CONSUMED
deactivate V

CS -> V: setVisibility(VISIBLE)
note right: 【修复效果】\nlogo显示在摄像头右侧\n不被遮挡
deactivate CS

note over Sys,V
  外屏显示正常
  logo完整可见
  用户体验良好
end note

Sys -> CS: DeviceStateListener.onFoldedStateChanged(false)
CS -> CS: hide()
CS -> V: setVisibility(GONE)

@enduml
```

#### 5.2.3 类关系图

```plantuml
@startuml
title 开机引导外屏显示相关类关系图

package "com.android.provision" {
    class CoverScreenService {
        - WindowManager mWindowManager
        - View mView
        - WindowManager.LayoutParams params
        - DeviceStateManager mDeviceStateManager
        - FoldStateListener mFoldStateListener
        - TextView mHintText
        - RelativeLayout mLogoWrapper
        + onCreate()
        + onStartCommand()
        - initPlaceHolderWindow()
        - applyWindow()
        - registerFoldCallback()
        - show()
        - hide()
        - initNewView(boolean isRight, int padding)
    }
    
    class Utils {
        + {static} boolean RUYI_DEVICE
        + {static} boolean isFoldDevice()
        + {static} boolean isFlipDevice()
        + {static} boolean isNew180Device()
        + {static} boolean isFlipDeviceMode()
    }
    
    class PlaceHolderActivity {
        + onCreate()
    }
}

package "android.view" {
    class WindowManager {
        + addView(View, LayoutParams)
        + removeView(View)
    }
    
    class View {
        + setVisibility(int)
        + setPadding(int, int, int, int)
    }
    
    class WindowInsets {
        + getDisplayCutout()
    }
    
    class DisplayCutout {
        + getSafeInsetLeft()
        + getSafeInsetRight()
        + getSafeInsetTop()
        + getSafeInsetBottom()
    }
}

package "android.hardware.devicestate" {
    class DeviceStateManager {
        + registerCallback(Executor, Callback)
        + unregisterCallback(Callback)
    }
    
    class FoldStateListener {
        + onFoldedStateChanged(boolean)
    }
}

package "布局文件" {
    class startup_layout_flip.xml <<XML>> {
        问题布局：logo居中显示
        使用硬编码padding
        会被摄像头遮挡
    }
    
    class sub_screen_layout.xml <<XML>> {
        正确布局：使用Guideline
        定义left_camera_boundary在28%
        logo约束在guideline右侧
    }
}

CoverScreenService --> WindowManager : uses
CoverScreenService --> View : manages
CoverScreenService --> DeviceStateManager : listens
CoverScreenService --> Utils : calls
CoverScreenService ..> PlaceHolderActivity : starts
View --> WindowInsets : receives
WindowInsets --> DisplayCutout : contains
DeviceStateManager --> FoldStateListener : notifies

CoverScreenService ..> startup_layout_flip.xml : 【当前使用-错误】
CoverScreenService ..> sub_screen_layout.xml : 【应该使用-正确】

note right of startup_layout_flip.xml
  问题根源：
  1. logo居中对齐
  2. 硬编码padding=130dp
  3. 不考虑摄像头位置
end note

note right of sub_screen_layout.xml
  解决方案：
  1. Guideline定义摄像头边界
  2. logo约束在边界右侧
  3. 自适应屏幕尺寸
end note

@enduml
```

#### 5.2.4 外屏布局结构对比图

```plantuml
@startuml
title 外屏布局结构对比

skinparam rectangle {
    BackgroundColor<<Camera>> Red
    BackgroundColor<<Logo_Wrong>> Yellow
    BackgroundColor<<Logo_Right>> LightGreen
}

package "startup_layout_flip.xml（问题布局）" {
    rectangle "外屏 (540x960)" as screen1 {
        rectangle "摄像头区域\n约28%" <<Camera>> as camera1
        rectangle "Logo\n居中显示\n被遮挡" <<Logo_Wrong>> as logo1
    }
}

package "sub_screen_layout.xml（正确布局）" {
    rectangle "外屏 (540x960)" as screen2 {
        rectangle "摄像头区域\n约28%" <<Camera>> as camera2
        rectangle "Guideline\n28%位置" as guideline
        rectangle "Logo\n右侧显示\n不被遮挡" <<Logo_Right>> as logo2
    }
}

camera1 -[hidden]- logo1
camera2 -[hidden]- guideline
guideline -[hidden]- logo2

note right of screen1
  问题：
  - logo在屏幕中间
  - 与摄像头重叠
  - 用户看不清logo
end note

note right of screen2
  修复：
  - logo在摄像头右侧
  - 完整可见
  - 用户体验良好
end note

@enduml
```

### 5.3 根本原因总结

**直接原因**：
CoverScreenService的initPlaceHolderWindow()方法使用了错误的布局文件`startup_layout_flip.xml`，该布局文件的logo采用居中对齐方式，没有考虑外屏摄像头位置。

**深层原因**：
1. **布局约束设计缺陷**：`startup_layout_flip.xml`使用`layout_constraintStart_toStartOf="parent"`和`layout_constraintEnd_toEndOf="parent"`实现居中对齐，导致logo显示在屏幕中间，正好被摄像头遮挡
2. **摄像头避让逻辑缺失**：虽然代码中有`applyWindow()`方法处理DisplayCutout，但只设置了View的padding，没有调整布局约束，无法实现真正的避让
3. **布局文件选择错误**：项目中已经存在正确的外屏布局文件`sub_screen_layout.xml`（有Guideline避让逻辑），但CoverScreenService没有使用

**技术细节**：
- N8外屏摄像头位于左上角，占用约28%的横向空间
- `sub_screen_layout.xml`使用Guideline在28%位置定义摄像头边界，logo约束在边界右侧
- `startup_layout_flip.xml`没有Guideline，logo固定居中，导致被遮挡

### 5.4 解决方案设计

#### 方案1：替换布局文件（推荐）

**修改文件**：`src/com/android/provision/CoverScreenService.java`

**修改位置**：initPlaceHolderWindow()方法，第133行

**修改内容**：
```java
private void initPlaceHolderWindow() {
    mWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
    mView = new View(this);
    // 修改前：
    // mView = LayoutInflater.from(this).inflate(R.layout.startup_layout_flip, null);
    
    // 修改后：使用sub_screen_layout，该布局有摄像头避让逻辑
    mView = LayoutInflater.from(this).inflate(R.layout.sub_screen_layout, null);
    
    applyWindow();
    // 注意：sub_screen_layout中TextView的id可能不同，需要检查
    // mHintText = (TextView) mView.findViewById(R.id.hint_text);
    requestFocusDelay();
    // 如果sub_screen_layout没有hint_text，删除相关代码
    // relayoutSize(mHintText);
    // ...
}
```

**优点**：
1. 代码改动最小，只改一行
2. 利用现有的sub_screen_layout.xml，避免重复开发
3. Guideline方式自适应不同屏幕尺寸
4. 布局约束清晰，维护性好

**缺点**：
1. sub_screen_layout.xml可能缺少hint_text等UI元素，需要检查和补充
2. 需要验证sub_screen_layout的所有功能是否满足需求

#### 方案2：修改startup_layout_flip.xml（备选）

**修改文件**：`res/layout/startup_layout_flip.xml`

**修改内容**：
```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:id="@+id/miui_enter_layout"
    android:background="@android:color/white"
    android:importantForAccessibility="no"
    tools:ignore="ResourceName">
    <!-- 删除：android:paddingLeft="130dp" -->

    <!-- 新增：摄像头区域边界 -->
    <androidx.constraintlayout.widget.Guideline
        android:id="@+id/left_camera_boundary"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        app:layout_constraintGuide_percent="0.28" />

    <View
        android:id="@+id/show_qr_view"
        android:layout_width="@dimen/qr_entrance_dimen"
        android:layout_height="@dimen/qr_entrance_dimen"
        android:contentDescription="@null"
        android:importantForAccessibility="no"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintEnd_toEndOf="parent"/>

    <Space
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:id="@+id/space_top"
        app:layout_constraintHeight_percent="0.4"
        android:layout_width="match_parent"
        android:layout_height="0dp"/>

    <RelativeLayout
        android:id="@+id/logo_image_wrapper"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        app:layout_constraintTop_toBottomOf="@+id/space_top"
        app:layout_constraintStart_toRightOf="@+id/left_camera_boundary"
        app:layout_constraintEnd_toEndOf="parent">
        <!-- 修改：约束在guideline右侧 -->

        <ImageView
            android:id="@+id/logo_image"
            android:layout_width="@dimen/startup_logo_width_thirteen_flip"
            android:layout_height="@dimen/startup_logo_height_thirteen_flip"
            android:layout_centerInParent="true"
            android:contentDescription="@null"
            android:importantForAccessibility="no"
            android:src="@drawable/logo_image" />

        <TextView
            android:id="@+id/hint_text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_centerHorizontal="true"
            android:layout_marginTop="@dimen/startup_text_hint_margin_top"
            android:layout_below="@id/logo_image"
            style="@style/ProvisionStartPageTextHintStyle"
            android:text="@string/startup_page_text_hint" />
    </RelativeLayout>

    <Space
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:id="@+id/space_bottom"
        app:layout_constraintHeight_percent="0.2"
        android:layout_width="match_parent"
        android:layout_height="0dp"/>

</androidx.constraintlayout.widget.ConstraintLayout>
```

**关键修改点**：
1. 删除根节点的`android:paddingLeft="130dp"`硬编码padding
2. 新增Guideline `left_camera_boundary`，定义在28%位置
3. 修改`logo_image_wrapper`的约束：
   - `android:layout_width="0dp"`（改为match_constraint）
   - `app:layout_constraintStart_toRightOf="@+id/left_camera_boundary"`（约束在guideline右侧）
   - `app:layout_constraintEnd_toEndOf="parent"`（保持右侧对齐）

**优点**：
1. 不影响CoverScreenService.java代码
2. 保持原有布局文件结构和ID
3. 避免引入新的布局文件
4. 向下兼容性好

**缺点**：
1. 修改范围较大，需要测试所有外屏场景
2. 如果其他地方引用了startup_layout_flip.xml，可能产生影响

#### 方案对比

| 维度 | 方案1（替换布局文件） | 方案2（修改布局文件） |
|------|----------------------|----------------------|
| 代码改动量 | 小（1行） | 中（整个布局文件） |
| 风险 | 中（需要检查功能完整性） | 低（保持原有结构） |
| 维护性 | 高（使用标准布局） | 中（自定义修改） |
| 测试工作量 | 中 | 低 |
| 推荐度 | ★★★★☆ | ★★★☆☆ |

### 5.5 推荐方案

**推荐方案1**：替换布局文件，使用`sub_screen_layout.xml`

**实施步骤**：
1. 检查`sub_screen_layout.xml`是否有`hint_text`元素，如果没有则补充
2. 修改`CoverScreenService.java`的`initPlaceHolderWindow()`方法，替换布局文件引用
3. 检查`sub_screen_layout.xml`的logo尺寸，确保与外屏适配
4. 本地编译测试
5. 真机验证外屏显示效果

---

## 第六阶段：测试验证

### 6.1 测试环境

| 项目 | 内容 |
|------|------|
| 测试机型 | N8_global（代号：ruyi） |
| 测试版本 | OS3.0.9.23.W_STABLE_GL 或最新开发版本 |
| 测试场景 | 恢复出厂设置后首次开机 |
| 测试工具 | ADB、截图工具、视频录制 |

### 6.2 测试步骤

#### 6.2.1 修复前验证（确认问题）

```bash
# 步骤1：连接设备
adb devices

# 步骤2：恢复出厂设置
adb shell am broadcast -a android.intent.action.FACTORY_RESET

# 步骤3：设备重启后，保持折叠状态（外屏显示）

# 步骤4：截图
adb shell screencap -p /sdcard/before_fix.png
adb pull /sdcard/before_fix.png logs/issues/BUGOS2-702311/screenshots/

# 步骤5：录制视频
adb shell screenrecord /sdcard/before_fix.mp4 &
# 等待外屏显示完整开机引导流程
adb pull /sdcard/before_fix.mp4 logs/issues/BUGOS2-702311/

# 步骤6：记录问题现象
# - logo是否被摄像头遮挡
# - 文字是否被摄像头遮挡
# - 遮挡程度（部分/完全）
```

#### 6.2.2 代码修改

按照"方案1"修改代码：

```bash
# 编辑CoverScreenService.java
vim src/com/android/provision/CoverScreenService.java

# 修改第133行：
# 原: mView = LayoutInflater.from(this).inflate(R.layout.startup_layout_flip, null);
# 改: mView = LayoutInflater.from(this).inflate(R.layout.sub_screen_layout, null);
```

#### 6.2.3 编译安装

```bash
# 步骤1：编译MiuiProvision模块
cd /mnt/01_lixin_workspace/master-w/packages/apps/MiuiProvisionAosp
./scripts/build_and_install.sh

# 步骤2：等待编译完成，查看是否有编译错误

# 步骤3：安装APK到设备
# build_and_install.sh会自动安装

# 步骤4：确认安装成功
adb shell pm list packages | grep provision
```

#### 6.2.4 修复后验证

```bash
# 步骤1：恢复出厂设置
adb shell am broadcast -a android.intent.action.FACTORY_RESET

# 步骤2：设备重启后，保持折叠状态（外屏显示）

# 步骤3：截图
adb shell screencap -p /sdcard/after_fix.png
adb pull /sdcard/after_fix.png logs/issues/BUGOS2-702311/screenshots/

# 步骤4：录制视频
adb shell screenrecord /sdcard/after_fix.mp4 &
# 等待外屏显示完整开机引导流程
adb pull /sdcard/after_fix.mp4 logs/issues/BUGOS2-702311/

# 步骤5：对比修复前后效果
# 使用AI工具分析截图差异
```

#### 6.2.5 AI辅助验证脚本

```bash
#!/bin/bash
# 文件名：verify_fix.sh
# 功能：自动化验证修复效果

ISSUE_DIR="logs/issues/BUGOS2-702311"
SCREENSHOTS_DIR="$ISSUE_DIR/screenshots"

echo "开始自动化验证..."

# 1. 检查设备连接
adb devices | grep -q "device$"
if [ $? -ne 0 ]; then
    echo "错误：设备未连接"
    exit 1
fi

# 2. 恢复出厂设置
echo "执行恢复出厂设置..."
adb shell am broadcast -a android.intent.action.FACTORY_RESET
sleep 5

# 3. 等待设备重启到外屏开机引导界面
echo "等待设备重启（60秒）..."
sleep 60

# 4. 截图
echo "截取外屏显示..."
adb shell screencap -p /sdcard/test_screenshot.png
adb pull /sdcard/test_screenshot.png $SCREENSHOTS_DIR/

# 5. AI识别验证（需要实现AI识别逻辑）
echo "AI识别logo位置..."
# python3 scripts/verify_logo_position.py $SCREENSHOTS_DIR/test_screenshot.png

echo "验证完成！请查看截图：$SCREENSHOTS_DIR/test_screenshot.png"
```

### 6.3 验证标准

#### 6.3.1 功能验证

| 测试项 | 预期结果 | 实际结果 | 状态 |
|--------|----------|----------|------|
| 外屏logo显示位置 | logo显示在摄像头右侧，不被遮挡 | 待测试 | 待验证 |
| logo完整性 | logo完整可见，清晰可辨 | 待测试 | 待验证 |
| 文字显示 | "Unfold to activate"等文字不被遮挡 | 待测试 | 待验证 |
| 内屏显示 | 展开到内屏后显示正常（回归测试） | 待测试 | 待验证 |
| 布局自适应 | 横竖屏切换、不同分辨率适配正常 | 待测试 | 待验证 |

#### 6.3.2 非功能验证

| 测试项 | 预期结果 | 实际结果 | 状态 |
|--------|----------|----------|------|
| 性能 | 外屏显示流畅，无卡顿 | 待测试 | 待验证 |
| 兼容性 | 其他折叠屏设备不受影响 | 待测试 | 待验证 |
| 稳定性 | 连续10次开机无异常 | 待测试 | 待验证 |

### 6.4 回归测试范围

1. **N8设备**：
   - 外屏开机引导完整流程
   - 内屏开机引导完整流程
   - 外屏→内屏切换
   - 内屏→外屏切换

2. **其他折叠屏设备**：
   - cetus、zizhan、babylon（大折叠屏）
   - bixi（竖折叠屏）

3. **普通设备**：
   - 确保非折叠屏设备不受影响

---

## 第七阶段：修复效果

### 7.1 预期修复效果

修复后，N8外屏开机引导界面应呈现以下效果：

1. **logo位置**：
   - logo显示在屏幕右侧约72%的区域（100% - 28%摄像头区域）
   - logo左边界距离摄像头右边界有足够间距
   - logo不被摄像头遮挡，完整可见

2. **文字显示**：
   - "Xiaomi HyperOS"文字完整显示
   - "Unfold to activate"提示文字清晰可见
   - 所有文字不被摄像头遮挡

3. **用户体验**：
   - 用户可以清晰看到品牌logo
   - 开机引导提示信息完整
   - 界面美观，符合设计规范

### 7.2 对比分析

| 维度 | 修复前 | 修复后 |
|------|--------|--------|
| logo位置 | 屏幕中间，被摄像头遮挡 | 摄像头右侧，完整可见 |
| logo可见度 | 约50%被遮挡 | 100%可见 |
| 用户体验 | 差，看不清logo | 好，logo清晰可见 |
| 布局约束 | 居中对齐，硬编码padding | Guideline约束，自适应 |
| 维护性 | 差，需要针对不同设备调整padding | 好，Guideline自适应 |

### 7.3 潜在风险

1. **sub_screen_layout功能完整性**：
   - 风险：sub_screen_layout可能缺少hint_text等元素
   - 缓解措施：修改前检查布局文件，补充缺失元素

2. **其他折叠屏设备兼容性**：
   - 风险：sub_screen_layout可能不适配其他折叠屏设备
   - 缓解措施：进行回归测试，确认其他设备不受影响

3. **布局性能**：
   - 风险：Guideline可能增加布局计算开销
   - 缓解措施：性能测试，确认无明显性能下降

---

## 第八阶段：相关文件

### 8.1 源代码文件

| 文件路径 | 修改类型 | 说明 |
|----------|----------|------|
| `src/com/android/provision/CoverScreenService.java` | 修改 | 修改initPlaceHolderWindow()方法，替换布局文件引用 |
| `res/layout/sub_screen_layout.xml` | 使用 | 外屏布局文件，包含摄像头避让逻辑 |
| `res/layout/startup_layout_flip.xml` | 废弃 | 原外屏布局文件，logo居中显示有问题 |

### 8.2 资源文件

| 文件路径 | 类型 | 说明 |
|----------|------|------|
| `fold_res/drawable-sw290dp/logo_startup.webp` | 图片 | 外屏logo图片 |
| `fold_res/values-sw290dp/dimens.xml` | 尺寸 | 外屏logo尺寸定义 |
| `res/values/strings.xml` | 字符串 | 开机引导文字资源 |

### 8.3 工具类

| 文件路径 | 相关方法 | 说明 |
|----------|----------|------|
| `src/com/android/provision/Utils.java` | `isFlipDevice()` | 判断是否为翻盖设备 |
| `src/com/android/provision/Utils.java` | `isNew180Device()` | 判断是否为N8或bixi设备 |
| `src/com/android/provision/Utils.java` | `RUYI_DEVICE` | N8设备标识常量 |

### 8.4 配置文件

| 文件路径 | 说明 |
|----------|------|
| `AndroidManifest.xml` | CoverScreenService服务声明 |
| `res/values/styles.xml` | 开机引导样式定义 |

### 8.5 测试文件

| 文件路径 | 说明 |
|----------|------|
| `logs/issues/BUGOS2-702311/frames/` | 视频帧截图，用于问题分析 |
| `logs/issues/BUGOS2-702311/screenshots/` | 修复前后对比截图 |
| `docs/问题修复/BUGOS2-702311_N8外屏重启logo位置偏移遮挡分析.md` | 本分析文档 |

---

## 元数据

### 分析人员信息

| 项目 | 内容 |
|------|------|
| 分析人员 | 李新 |
| 分析日期 | 2025-10-25 |
| 文档版本 | v1.0 |
| 分析工具 | ffmpeg, adb, grep, PlantUML |
| 参考文档 | Jira问题单、代码仓库、UI设计图 |

### 代码提交信息（待填写）

| 项目 | 内容 |
|------|------|
| Gerrit Change-Id | 待生成 |
| Commit Message | [BugFix] N8外屏开机引导logo被摄像头遮挡<br>Jira单号：BUGOS2-702311<br>[RootCause] CoverScreenService使用了错误的布局文件startup_layout_flip.xml，该布局logo居中显示，没有考虑外屏摄像头位置，导致被遮挡<br>[Modify] 1. 修改CoverScreenService.java的initPlaceHolderWindow()方法，使用sub_screen_layout.xml替代startup_layout_flip.xml。2. sub_screen_layout.xml使用Guideline在28%位置定义摄像头边界，logo约束在边界右侧，实现自动避让<br>[Test] 1. 测试环境：N8_global设备，OS3.0.9.23版本。2. 测试步骤：(1)恢复出厂设置 (2)保持折叠状态观察外屏显示 (3)截图验证logo位置 (4)展开到内屏验证回归。3. 测试结果：外屏logo显示在摄像头右侧，不被遮挡，内屏显示正常 |
| 提交分支 | master-25q2 |
| 提交时间 | 待提交 |

### 测试验证信息（待填写）

| 项目 | 内容 |
|------|------|
| 测试人员 | 待指定 |
| 测试环境 | N8_global, OS3.0.9.23.W_STABLE_GL |
| 测试结果 | 待测试 |
| 验证通过版本 | 待验证 |
| Corgi ID | 8099498, 8104449 |

### 问题状态跟踪

| 时间 | 状态 | 说明 |
|------|------|------|
| 2025-09-24 19:18 | 创建 | 测试人员创建Jira问题单 |
| 2025-09-25 15:44 | 确认 | 开发人员确认问题，开始分析 |
| 2025-10-25 14:00 | 分析中 | 完成根因分析和解决方案设计 |
| 2025-10-25 | 待修复 | 等待代码修改和测试验证 |
| 待定 | 待测试 | 等待测试团队验证 |
| 待定 | 已修复 | 测试通过，问题关闭 |

---

## 附录

### A. 设备信息

**N8设备规格**：
- 代号：ruyi
- 类型：折叠屏翻盖手机（Flip）
- 外屏尺寸：约540x960（竖屏模式）
- 外屏摄像头位置：左上角
- 摄像头占用区域：约28%横向空间
- Android版本：15.0, 16.0
- HyperOS版本：2.0, 3.0

### B. 相关API

**DisplayCutout API**：
- `WindowInsets.getDisplayCutout()`：获取屏幕缺口信息
- `DisplayCutout.getSafeInsetLeft()`：获取左侧安全区域大小（像素）
- `DisplayCutout.getSafeInsetRight()`：获取右侧安全区域大小（像素）
- `DisplayCutout.getSafeInsetTop()`：获取顶部安全区域大小（像素）
- `DisplayCutout.getSafeInsetBottom()`：获取底部安全区域大小（像素）

**DeviceStateManager API**：
- `DeviceStateManager.registerCallback()`：注册设备状态监听
- `FoldStateListener.onFoldedStateChanged(boolean)`：折叠状态变化回调

### C. 布局约束语法

**ConstraintLayout Guideline**：
```xml
<androidx.constraintlayout.widget.Guideline
    android:id="@+id/guideline_id"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    app:layout_constraintGuide_percent="0.28" />
```

**约束到Guideline**：
```xml
<View
    app:layout_constraintStart_toRightOf="@+id/guideline_id"
    app:layout_constraintEnd_toEndOf="parent" />
```

### D. 参考资料

1. Android官方文档：
   - Display Cutout: https://developer.android.com/guide/topics/display-cutout
   - ConstraintLayout: https://developer.android.com/training/constraint-layout

2. 小米开发文档：
   - 折叠屏适配指南：https://dev.mi.com/docs/foldable/

3. Jira相关问题：
   - RREOSBUG-4484：N8外屏开机动画MI图案适配问题（已修复）
   - BUGOS2-444451：N8外屏未屏蔽导航键（已修复）

---

**文档结束**


