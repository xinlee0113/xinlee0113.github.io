---
layout: default
title: Window焦点竞争问题详解
parent: Android源码学习
nav_order: 10
---

# Window焦点竞争问题详解

## 📋 问题：为什么要避免与Activity竞争焦点？

### 核心概念

**Window焦点（Focus）**：
- 在Android系统中，同一时间**只有一个Window可以获得焦点**
- 获得焦点的Window可以：
  - ✅ 接收键盘输入
  - ✅ 接收触摸事件
  - ✅ 响应用户交互
- 没有焦点的Window：
  - ❌ 无法接收键盘输入
  - ❌ 可能无法接收触摸事件（取决于flags）
  - ❌ 用户点击没有反应

---

## 🔴 后果分析：如果不动态管理焦点

### 场景1：hide时不添加FLAG_NOT_FOCUSABLE

**问题代码**：
```java
private void hide() {
    mIsShowing = false;
    
    // ❌ 错误：隐藏时不添加FLAG_NOT_FOCUSABLE
    // params.flags |= WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;  // 没有这行
    
    mView.setVisibility(View.GONE);  // 只是隐藏，但Window还在
}
```

**后果**：
```
用户操作流程：
1. 折叠状态 → CoverScreenService显示（外屏）
2. 展开设备 → CoverScreenService.hide()被调用
   ├─ mView.setVisibility(GONE) → 外屏界面隐藏
   ├─ 但Window仍然存在，且能获得焦点
   └─ DefaultActivity显示（内屏）

3. 用户尝试点击内屏按钮 → ❌ 没有反应！

原因：
┌────────────────────────────────────────────┐
│ CoverScreenService Window (GONE但有焦点)   │ ← 焦点在这里！
│ ├─ 虽然GONE（不可见）                      │
│ ├─ 但Window存在                             │
│ ├─ 能获得焦点                               │
│ └─ 拦截了触摸事件                           │
├────────────────────────────────────────────┤
│ DefaultActivity Window (可见但无焦点)      │ ← 用户看到这个
│ ├─ 界面可见                                 │
│ ├─ 但没有焦点                               │
│ └─ 点击无效 ❌                             │
└────────────────────────────────────────────┘

用户看到：内屏界面正常显示
用户感受：点击任何按钮都没反应 → 严重bug！
```

**实际表现**：
- 用户看到内屏开机引导界面
- 点击"下一步"按钮 → 没反应
- 点击"跳过"按钮 → 没反应
- 点击任何地方 → 都没反应
- **用户无法继续操作，卡死！**

---

### 场景2：show时不移除FLAG_NOT_FOCUSABLE

**问题代码**：
```java
private void show() {
    mIsShowing = true;
    
    // ❌ 错误：显示时不移除FLAG_NOT_FOCUSABLE
    // params.flags &= ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;  // 没有这行
    
    mView.setVisibility(View.VISIBLE);  // 显示，但无法获得焦点
}
```

**后果**：
```
用户操作流程：
1. 展开状态 → DefaultActivity显示（内屏）
2. 折叠设备 → CoverScreenService.show()被调用
   ├─ mView.setVisibility(VISIBLE) → 外屏界面显示
   ├─ 但FLAG_NOT_FOCUSABLE还在
   └─ 无法获得焦点

3. 用户尝试点击外屏按钮 → ❌ 没有反应！

原因：
┌────────────────────────────────────────────┐
│ CoverScreenService Window (可见但无焦点)   │ ← 用户看到这个
│ ├─ 界面可见                                 │
│ ├─ FLAG_NOT_FOCUSABLE=ON                   │
│ ├─ 无法获得焦点                             │
│ └─ 触摸事件穿透到下层                       │
├────────────────────────────────────────────┤
│ DefaultActivity Window (不可见但有焦点)    │ ← 焦点在这里！
│ ├─ 界面被遮挡                               │
│ ├─ 但有焦点                                 │
│ └─ 接收触摸事件                             │
└────────────────────────────────────────────┘

用户看到：外屏开机引导界面
用户感受：点击外屏按钮没反应 → 严重bug！
       或者：触摸穿透到内屏，意外操作了内屏 → 更严重！
```

**实际表现**：
- 用户看到外屏开机引导界面
- 点击外屏"下一步"按钮 → 没反应
- 或者：点击穿透到下面的DefaultActivity，误操作内屏 → 混乱！

---

### 场景3：两个Window都能获得焦点（焦点争夺）

**问题代码**：
```java
// 初始化时
params.flags = 0;  // ❌ 没有FLAG_NOT_FOCUSABLE

// show时
params.flags &= ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;

// hide时
// ❌ 不添加FLAG_NOT_FOCUSABLE
```

**后果 - 焦点反复争夺**：
```
时间线：
0ms   CoverScreenService显示 → 尝试获得焦点
10ms  DefaultActivity也存在 → 尝试获得焦点
20ms  焦点在CoverScreenService
30ms  系统发现DefaultActivity也想要焦点
40ms  焦点切换到DefaultActivity
50ms  CoverScreenService又请求焦点
60ms  焦点切回CoverScreenService
...   焦点反复跳动

表现：
- 用户点击时，焦点刚好在另一个Window
- 触摸事件时灵时不灵
- 界面闪烁（焦点切换可能导致重绘）
- 性能问题（频繁焦点切换）
```

---

## ✅ 正确的动态焦点管理

### 完整流程

```
┌─────────────────────────────────────────────────────────────┐
│ 状态机：CoverScreenService焦点管理                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [初始状态]                                                  │
│  ├─ Window创建                                               │
│  ├─ FLAG_NOT_FOCUSABLE = ON                                 │
│  ├─ mView.setVisibility(GONE)                               │
│  └─ 结果：不可见，无焦点，不竞争 ✅                          │
│                                                              │
│  [折叠 - show()]                                             │
│  ├─ params.flags &= ~FLAG_NOT_FOCUSABLE  移除标志            │
│  ├─ mWindowManager.updateViewLayout()  更新生效              │
│  ├─ mView.setVisibility(VISIBLE)  显示                      │
│  └─ 结果：可见，有焦点，可交互 ✅                            │
│         用户可以点击外屏按钮                                 │
│                                                              │
│  [展开 - hide()]                                             │
│  ├─ params.flags |= FLAG_NOT_FOCUSABLE  添加标志             │
│  ├─ mWindowManager.updateViewLayout()  更新生效              │
│  ├─ mView.setVisibility(GONE)  隐藏                         │
│  └─ 结果：不可见，无焦点，不竞争 ✅                          │
│         焦点释放给DefaultActivity                            │
│         用户可以点击内屏按钮                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 关键时刻对比

### 时刻1：折叠设备（显示外屏）

| 做法 | CoverScreenService | DefaultActivity | 用户体验 |
|------|-------------------|-----------------|---------|
| **正确做法** | 可见+有焦点 | 被遮挡+无焦点 | ✅ 点击外屏按钮有效 |
| **错误做法1** | 可见+无焦点 | 被遮挡+有焦点 | ❌ 点击外屏无效 |
| **错误做法2** | 可见+有焦点 | 被遮挡+也想要焦点 | ❌ 焦点反复跳动 |

### 时刻2：展开设备（显示内屏）

| 做法 | CoverScreenService | DefaultActivity | 用户体验 |
|------|-------------------|-----------------|---------|
| **正确做法** | GONE+无焦点 | 可见+有焦点 | ✅ 点击内屏按钮有效 |
| **错误做法1** | GONE+有焦点 | 可见+无焦点 | ❌ 点击内屏无效 |
| **错误做法2** | GONE+有焦点 | 可见+也想要焦点 | ❌ 焦点反复跳动 |

---

## 🔬 技术深度解析

### FLAG_NOT_FOCUSABLE的作用

```java
/**
 * WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
 * 
 * 作用：告诉WindowManager，这个Window不需要接收输入焦点
 * 
 * 设置此标志的Window：
 * - 不会参与焦点竞争
 * - 不会接收键盘事件
 * - 触摸事件的处理取决于其他flags
 *   - 如果有FLAG_NOT_TOUCH_MODAL，触摸事件会穿透
 *   - 如果没有，触摸事件会被消费但不响应
 * 
 * 典型使用场景：
 * - 悬浮显示（Toast、悬浮窗）
 * - 后台Window（不需要交互）
 * - 临时隐藏的Window
 */
public static final int FLAG_NOT_FOCUSABLE = 0x00000008;
```

### 焦点分配机制

```
Android WindowManagerService焦点分配规则：

1. 优先级：
   ┌─────────────────────────────┐
   │ 最高：能获得焦点的最上层Window│
   │ ├─ 检查Window Z-Order        │
   │ ├─ 检查FLAG_NOT_FOCUSABLE    │
   │ └─ 分配焦点                   │
   └─────────────────────────────┘

2. 当Window属性变化（updateViewLayout）：
   ├─ 重新计算焦点
   ├─ 如果移除了FLAG_NOT_FOCUSABLE
   │  └─ Window变为可获得焦点，系统可能分配焦点给它
   ├─ 如果添加了FLAG_NOT_FOCUSABLE
   │  └─ Window不再参与焦点竞争，焦点转给其他Window
   └─ 触发焦点变化回调

3. 焦点变化影响：
   ├─ 键盘事件分发
   ├─ 触摸事件分发
   ├─ Window.Callback.onWindowFocusChanged()
   └─ View焦点状态
```

---

## 📊 实际案例对比

### 案例1：不管理焦点的后果

**用户反馈**：
> "折叠手机后，外屏开机引导显示了，但点击任何按钮都没反应，设备像死机了一样。必须重启才能继续。"

**根因**：
```java
// hide()时没有添加FLAG_NOT_FOCUSABLE
private void hide() {
    mView.setVisibility(View.GONE);
    // ❌ 缺少：params.flags |= FLAG_NOT_FOCUSABLE;
}

// 展开后：
// - CoverScreenService Window虽然GONE，但仍有焦点
// - DefaultActivity虽然可见，但无焦点
// - 用户点击DefaultActivity按钮 → 焦点在CoverScreenService → 无效
```

### 案例2：正确管理焦点

**用户反馈**：
> "折叠展开切换很流畅，外屏和内屏都能正常操作，没有任何问题。"

**实现**：
```java
// show()时移除FLAG_NOT_FOCUSABLE
params.flags &= ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
mWindowManager.updateViewLayout(mView, params);
mView.setVisibility(View.VISIBLE);

// hide()时添加FLAG_NOT_FOCUSABLE
params.flags |= WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
mWindowManager.updateViewLayout(mView, params);
mView.setVisibility(View.GONE);
```

---

## 🎓 延伸：其他相关Flags

### FLAG_NOT_TOUCH_MODAL

```java
/**
 * WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
 * 
 * 作用：触摸Window外部区域时，事件不会被阻塞
 * 
 * 没有此标志：
 * - 触摸Window外部 → 事件被消费，下层Window收不到
 * - 行为：模态对话框效果
 * 
 * 有此标志：
 * - 触摸Window外部 → 事件穿透到下层Window
 * - 行为：非模态悬浮窗效果
 * 
 * 在我们的场景：
 * - CoverScreenService设置了此标志
 * - 如果外屏界面没有覆盖整个屏幕
 * - 用户点击外部区域，事件可以传递到DefaultActivity
 */
public static final int FLAG_NOT_TOUCH_MODAL = 0x00000020;
```

### 组合使用

```java
// 组合1：悬浮窗（不获取焦点，事件穿透）
params.flags = FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL;
// 用途：Toast、悬浮球、系统状态显示

// 组合2：模态覆盖层（获取焦点，阻塞事件）
params.flags = 0;  // 不设置FLAG_NOT_FOCUSABLE和FLAG_NOT_TOUCH_MODAL
// 用途：全屏对话框、引导遮罩

// 组合3：我们的场景（动态切换）
// 隐藏时
params.flags = FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL;
// 显示时
params.flags = FLAG_NOT_TOUCH_MODAL;  // 移除FLAG_NOT_FOCUSABLE
```

---

## 🔧 调试技巧

### 检查当前焦点

```bash
# 查看当前哪个Window有焦点
adb shell dumpsys window windows | grep mCurrentFocus

# 输出示例（正确情况）：
# 展开状态：
mCurrentFocus=Window{... com.android.provision/...DefaultActivity}

# 折叠状态：
mCurrentFocus=Window{... com.android.provision/...CoverScreenWindow}
```

### 监控焦点变化

```java
// 在Activity中添加
@Override
public void onWindowFocusChanged(boolean hasFocus) {
    super.onWindowFocusChanged(hasFocus);
    Log.d(TAG, "DefaultActivity focus changed: " + hasFocus);
    if (!hasFocus) {
        Log.w(TAG, "Lost focus! User input will be ignored!");
    }
}
```

### 检查Window Flags

```bash
# 查看Window的flags
adb shell dumpsys window windows | grep -A 10 "CoverScreenWindow"

# 查看是否有FLAG_NOT_FOCUSABLE（0x8）
# fl=0x118  → 包含FLAG_NOT_FOCUSABLE
# fl=0x110  → 不包含FLAG_NOT_FOCUSABLE
```

---

## 📝 总结

### 为什么要避免与Activity竞争焦点？

**核心原因**：
1. **同一时间只有一个Window可以有焦点**
2. **没有焦点的Window无法响应用户输入**
3. **焦点竞争会导致用户界面失效**

### 不避免的严重后果

| 后果 | 用户表现 | 严重程度 |
|------|---------|---------|
| **内屏无法点击** | 展开后点击按钮无效 | 🔴 P0致命 |
| **外屏无法点击** | 折叠后点击按钮无效 | 🔴 P0致命 |
| **焦点反复跳动** | 操作不稳定，闪烁 | 🟠 P1严重 |
| **误操作** | 点击穿透到错误界面 | 🟠 P1严重 |

### 正确做法

```java
// ✅ 动态管理焦点
show()  → 移除FLAG_NOT_FOCUSABLE → 获得焦点
hide()  → 添加FLAG_NOT_FOCUSABLE → 释放焦点
```

**记住这句话**：
> **焦点不是越多越好，而是谁需要谁拿，不需要就放！**

---

**文档日期**：2025-10-30  
**撰写人员**：AI Assistant  
**相关文件**：`src/com/android/provision/CoverScreenService.java`
