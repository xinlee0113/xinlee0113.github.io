---
layout: default
title: StartupFragment 动画流程解析
parent: 模块解析
---



# StartupFragment 动画流程解析

## 一、概述

StartupFragment 是开机引导的首页界面，包含三种关键动画：
1. **进场动画**：首次启动时的欢迎动画
2. **退场动画**：点击"下一步"进入语言选择页的过渡动画
3. **返回动画**：从语言页返回首页的动画

---

## 二、进场动画（首次启动欢迎动画）

### 2.1 触发条件

```java:536-568:src/com/android/provision/fragment/StartupFragment.java
@Override
public void onWindowFocusChanged(boolean hasFocus) {
    if (!IS_SUPPORT_WELCOME_ANIM) return;
    Log.i(TAG, " onWindowFocusChanged " + hasFocus + " isFirst " + Utils.isFirstBoot);
    if (Utils.isFirstBoot) {
        // 执行首次启动动画
    }
}
```

**触发条件**：
- `IS_SUPPORT_WELCOME_ANIM = true`（非lite或低端设备）
- `Utils.isFirstBoot = true`（首次启动标记）
- 窗口获得焦点时（`onWindowFocusChanged`）

### 2.2 动画组成（三层动画同时执行）

#### 第一层：背景光波动画（GlowController）

```java:540-545
if (mGlowController != null) {
    accelerateView(renderViewLayout);
    mGlowController.start(true);  // true = 首次启动模式
    // 设置光波中心位置与Logo对齐
    mGlowController.setCircleYOffsetWithView(mLogoImageWrapper, renderViewLayout);
}
```

**特点**：
- 使用 `RenderViewLayout` 以 0.2 倍缩放渲染，减少渲染消耗
- 光波效果从 Logo 位置向外扩散
- 启用了硬件加速（`TurboApi` 和 `BoostHelper`）

#### 第二层：Logo 动画

```java:547-551
if (mLogoImageWrapper != null) {
    mLogoImageWrapper.setVisibility(View.VISIBLE);
    accelerateView(mLogoImageWrapper);
    AnimHelper.startPageLogoAnim(mLogoImageWrapper);
}
```

**特点**：
- Logo 从不可见到可见
- 具体动画效果由 `AnimHelper.startPageLogoAnim()` 实现

#### 第三层：按钮动画

```java:553-563
if (mNextLayout != null) {
    mNextLayout.setVisibility(View.VISIBLE);
    AnimHelper.startPageBtnAnim(mNextLayout, new TransitionListener() {
        @Override
        public void onComplete(Object toTag) {
            super.onComplete(toTag);
            mNextLayout.setEnabled(true);  // 动画完成后才启用按钮
            Log.d(TAG, "onComplete: mNextLayout setEnabled");
        }
    });
}
```

**特点**：
- "下一步"按钮从不可见到可见
- **按钮初始状态是禁用的**（防止用户在动画期间点击）
- 动画完成后才启用按钮交互

### 2.3 动画时长与兜底保护

```java:578-593
private void displayOsLogoDelay(){
    Handler handler = new Handler();
    Runnable runnable = () -> {
        if (mNextLayout != null){
            mNextLayout.setVisibility(View.VISIBLE);
            mNextLayout.setEnabled(true);
        }
        if (mLogoImageWrapper != null){
            mLogoImageWrapper.setVisibility(View.VISIBLE);
        }
        Log.d(TAG, "displayOsLogoDelay");
    };
    // 动画执行1800ms，等动画执行完以后再执行该兜底逻辑，保证首页的View是可见的，所以延时2500ms
    handler.postDelayed(runnable, 2500);
}
```

**兜底逻辑**：
- 动画实际执行时间：**1800ms**
- 兜底延迟时间：**2500ms**
- 目的：确保即使动画异常，2.5秒后 UI 也会显示并可交互

### 2.4 首次启动标记重置

```java:570-576
private void resetFirstStart() {
    if (mAnimationHandler != null) {
        mAnimationHandler.removeMessages(MSG_ANIMATION_TAG);
        // 折叠屏外屏第一次启动会进入onWindowFocusChanged，所以需要延迟设置标记位
        mAnimationHandler.sendEmptyMessageDelayed(MSG_ANIMATION_TAG, Utils.isFoldDevice() ? 3000 : 0);
    }
}
```

**特殊处理**：
- 普通设备：立即重置 `Utils.isFirstBoot = false`
- 折叠屏设备：延迟 **3000ms** 后重置（避免外屏/内屏切换时重复触发动画）

---

## 三、退场动画（进入语言选择页）

### 3.1 触发流程

```java:326-343
mNextLayout.setOnClickListener(v -> {
    // 防抖：2秒内不能重复点击
    long currentClickTime = System.currentTimeMillis();
    if (Math.abs(currentClickTime - lastClickTime) < CLICK_THROTTLE_INTERVAL) {
        Log.d(TAG, "click too fast");
        return;
    }
    lastClickTime = currentClickTime;

    Log.d(TAG, "click next button");
    recordPageStayTime();
    DefaultActivity activity = (DefaultActivity) getActivity();
    Utils.isFirstBoot = false;
    activity.run(Activity.RESULT_OK);
    OTHelper.rdCountEvent(Constants.KEY_CLICK_FIRST_PAGE_START);
    BoostHelper.getInstance().boostDefault(mNext);
    enterLanguagePickPage();  // 进入语言选择页
});
```

**防抖机制**：
- 防抖间隔：**2000ms**（`CLICK_THROTTLE_INTERVAL`）
- 防止用户快速重复点击导致多次跳转

### 3.2 动画准备

```java:610-622
private void enterLanguagePickPage() {
    ViewUtils.captureRoundedBitmap(getActivity(), mNext, mainHandler, roundedBitmap -> {
        if (roundedBitmap != null) {
            startPickPage(roundedBitmap);  // 使用动画跳转
        } else {
            Log.d(TAG, "roundedBitmap is null ");
            // 降级方案：直接跳转，无动画
            Intent intent = new Intent();
            intent.setClass(getActivity(), LanguagePickerActivity.class);
            intent.putExtra("isShowDelayAnim", true);
            getActivity().startActivityForResult(intent, 0);
        }
    });
}
```

**关键步骤**：
1. 截取"下一步"按钮的圆角位图（`captureRoundedBitmap`）
2. 如果截图成功 → 使用动画跳转
3. 如果截图失败 → 降级为直接跳转（无动画）

### 3.3 创建缩放动画

```java:624-645
private void startPickPage(Bitmap bitmap){
    int foreGroundColor = getAnimForeGroundColor();
    int radius = (mNext.getWidth() - mNext.getPaddingRight() - mNext.getPaddingLeft()) / 2;

    int[] loc = new int[2];
    mNext.getLocationInWindow(loc);  // 获取按钮在窗口中的位置
    
    ActivityOptions activityOptions = ActivityOptionsHelper.makeScaleUpAnim(
            mNext,                    // 源View
            bitmap,                   // 按钮的截图
            loc[0], loc[1],          // 按钮的屏幕坐标
            radius,                   // 圆角半径
            foreGroundColor,          // 前景色
            1.0f,                     // 缩放比例
            mainHandler,
            exitStartedCallback,      // 动画开始回调 ⭐
            exitFinishCallback,       // 动画结束回调 ⭐
            null, null,
            ActivityOptionsHelper.ANIM_LAUNCH_ACTIVITY_FROM_ROUNDED_VIEW
    );
    
    // 缓存位置和位图，用于返回动画
    Utils.LOCATION_X = loc[0];
    Utils.LOCATION_Y = loc[1];
    Utils.CACHE_BITMAP = bitmap;
    Utils.IS_RTL = isRtl();
    Utils.IS_START_ANIMA = true;
    
    Intent intent = new Intent();
    intent.setClass(getActivity(), LanguagePickerActivity.class);
    intent.putExtra("isShowDelayAnim", true);
    getActivity().startActivityForResult(intent, 0, activityOptions.toBundle());
}
```

**动画原理**：
- 使用 `ActivityOptionsHelper.makeScaleUpAnim` 创建从圆形按钮放大到整个屏幕的动画
- 动画类型：`ANIM_LAUNCH_ACTIVITY_FROM_ROUNDED_VIEW`（从圆形View启动Activity）
- **缓存数据**：位置、位图、RTL方向，供返回动画使用

---

## 四、exitStartedCallback 回调时机 ⭐

### 4.1 回调定义

```java:651-659
Runnable exitStartedCallback = new Runnable() {
    @Override
    public void run() {
        if (mNextLayout != null) {
            mNextLayout.setVisibility(View.INVISIBLE);
            Log.d(TAG, "exitStartedCallback: " + (mNextLayout.getVisibility()));
        }
    }
};
```

### 4.2 触发时机

**时机**：缩放动画**开始时**立即触发

**关键发现**：⚠️ **这个回调在前进和后退动画时都会触发！**

**时间线（前进动画）**：
```
用户点击"下一步"
    ↓
captureRoundedBitmap（截图）
    ↓
startPickPage（创建动画）
    ↓
startActivityForResult（启动Activity）
    ↓
【前进动画开始】
    ↓
exitStartedCallback 触发 ✅
    ↓
    |  动画执行中（圆形放大到全屏）
    ↓
【前进动画结束】
    ↓
exitFinishCallback 触发 ✅
```

**时间线（后退动画）**：
```
用户按返回键
    ↓
StartupFragment#2 被重新创建
    ↓
【返回动画开始】
    ↓
exitStartedCallback 触发 ✅（Fragment#1 的回调）
    ↓
    |  动画执行中（全屏缩小到圆形）
    ↓
【返回动画结束】
    ↓
exitFinishCallback 触发 ✅（Fragment#1 的回调）
```

### 4.3 作用

**隐藏原始按钮**：
- 将 `mNextLayout` 设置为 `INVISIBLE`
- 原因：动画使用的是按钮的截图位图，原始按钮需要隐藏，避免重影
- 注意：使用 `INVISIBLE` 而非 `GONE`，保持布局空间

**双向触发机制**：
- `ActivityOptionsHelper.makeScaleUpAnim` 创建的是**双向动画**
- `disableBackAnimation = false` 确保返回动画启用
- 因此回调在前进和后退两个方向都会触发

---

## 五、exitFinishCallback 回调时机 ⭐

### 5.1 回调定义

```java:661-683
Runnable exitFinishCallback = new Runnable() {
    @Override
    public void run() {
        if (mNextLayout != null) {
            mNextLayout.setVisibility(View.VISIBLE);
            Log.d(TAG, "exitFinishCallback: " + (mNextLayout.getVisibility()));
        }
        Activity activity = getActivity();
        if (activity == null) {
            // 进入过一次语言选择页面，再次返回首页，点击下一步图标进入语言选择页面时会走进来
            // 已经移除过了，不用再移除
            Log.w(TAG, "exitFinishCallback: getActivity() is null, fragment may be detached");
            return;
        }
        FragmentManager fragmentManager = getActivity().getSupportFragmentManager();
        Fragment fragment = fragmentManager.findFragmentByTag(StartupFragment.class.getSimpleName());
        if (fragment != null) {
            FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
            fragmentTransaction.remove(fragment);
            fragmentTransaction.commitAllowingStateLoss();
            Log.d(TAG, "remove startup fragment finished");
        }
    }
};
```

### 5.2 触发时机

**时机**：缩放动画**完全结束时**触发

**关键发现**：⚠️ **这个回调在前进和后退动画时都会触发！**

**典型场景**：
1. **首次进入语言页（前进动画）**：动画结束后，新Activity已完全可见
2. **从语言页返回（后退动画）**：返回动画结束后触发
3. **再次进入语言页（第二次前进）**：动画结束后触发，但此时 `getActivity()` 已经是 `null`

### 5.3 作用（两个关键操作）

#### 操作1：恢复按钮可见性

```java
mNextLayout.setVisibility(View.VISIBLE);
```

- 将按钮恢复为可见状态
- 为什么要恢复？因为在 `exitStartedCallback` 中将其设置为 `INVISIBLE`

**注意**：
- 在前进动画时，这个操作针对的是 Fragment#1 的 View（即将被移除）
- 在后退动画时，这个操作针对的是 Fragment#1 的 View（已经不在屏幕上）
- 屏幕上显示的是 Fragment#2 的新 View

#### 操作2：移除 Fragment ⭐

```java
FragmentManager fragmentManager = getActivity().getSupportFragmentManager();
Fragment fragment = fragmentManager.findFragmentByTag(StartupFragment.class.getSimpleName());
if (fragment != null) {
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.remove(fragment);
    fragmentTransaction.commitAllowingStateLoss();
}
```

**为什么要移除 Fragment？**
- 因为前进动画完成后，语言选择页已经完全显示
- StartupFragment 已经不需要了，移除可以释放资源
- 使用 `commitAllowingStateLoss()` 避免状态丢失异常

**空指针保护 - 为什么 `getActivity()` 会返回 `null`？** ⭐⭐⭐

```java
if (activity == null) {
    // 进入过一次语言选择页面，再次返回首页，点击下一步图标进入语言选择页面时会走进来
    // 已经移除过了，不用再移除
    return;
}
```

**详细原因**：

1. **`getActivity()` 预期返回**：`DefaultActivity`（StartupFragment 的宿主）

2. **为什么返回时是 `null`？**

```
第一次前进动画（进入语言页）：
  ↓
exitFinishCallback 触发
  ├─ getActivity() = DefaultActivity ✅
  ├─ fragmentTransaction.remove(fragment)  ← Fragment#1 被移除
  ├─ Fragment#1.onDetach() 被调用
  └─ Fragment#1 内部的 mHost = null
      ↓
      从此以后 Fragment#1.getActivity() 返回 null ❌

从语言页返回（后退动画）：
  ↓
StartupState.onEnter() 再次调用
  ├─ 创建 StartupFragment#2（新实例！）
  └─ Fragment#2.getActivity() = DefaultActivity ✅
  ↓
exitFinishCallback 再次触发（Fragment#1 的回调！）
  ├─ Fragment#1 已经 detached
  ├─ Fragment#1.getActivity() = null ❌
  └─ 空指针保护生效，直接 return
```

3. **为什么回调还能执行？**
   - 回调通过 `mainHandler` 持有，Fragment#1 实例仍在内存中
   - `mNextLayout` 等实例变量仍然可以访问
   - 但 `mHost` 已被清空，导致 `getActivity()` 返回 `null`

4. **Fragment 实例关系**：
   ```
   StartupFragment#1（旧实例）：
     ├─ 在第一次前进动画结束时被移除
     ├─ getActivity() = null（已 detached）
     ├─ 但回调仍然绑定到这个实例
     └─ 回调操作的 View 已经不在 Activity 中

   StartupFragment#2（新实例）：
     ├─ 在返回时由 StartupState.onEnter() 创建
     ├─ getActivity() = DefaultActivity ✅
     └─ 这个实例的 View 才是屏幕上显示的
   ```

---

## 六、Fragment 重建机制 ⭐⭐⭐

### 6.1 核心问题：为什么 Fragment 被移除了，但 UI 还在？

这是一个看起来很矛盾的现象：

| 事实 | 说明 |
|------|------|
| ✅ Fragment#1 在前进动画结束时被 `remove` | `exitFinishCallback` 中调用 `fragmentTransaction.remove(fragment)` |
| ✅ Fragment#1 已经 detached | `getActivity()` 返回 `null` |
| ❌ 但返回首页时，UI 仍然完整显示 | Logo、按钮、背景都在 |

**答案**：因为从语言页返回时，**状态机重新创建了 StartupFragment 实例**！

### 6.2 状态机的返回流程

```java:2077-2101:src/com/android/provision/activities/DefaultActivity.java
private void transitToPrevious() {
    if (mStateStack.size() <= 0) {
        return;
    }

    State previousState = getPreviousAvailableState(mStateStack);
    mCurrentState.onLeave();  // ← LanguageState 离开

    State nextState = mCurrentState;
    mCurrentState = previousState;  // ← 切换回 StartupState
    if (mCurrentState instanceof StartupState) {
        ((StartupState) mCurrentState).setBooted(true);
    }
    int top = mStateStack.size() - 1;
    if (mCurrentState instanceof RecommendedState) {
        ((RecommendedState) mCurrentState).display(mContext);
    } else {
        mCurrentState.onEnter(top >= 0 && mStateStack.get(top).canBackTo(), false);
        // ← 🔥 关键：StartupState.onEnter() 被再次调用！
        
        // 首页进入语言页和返回有单独的动画
        if (!(nextState instanceof LanguageState)) {
            ((DefaultActivity) mContext).overridePendingTransition(R.anim.slide_in_left, R.anim.slide_out_right);
        }
    }
    saveState();
}
```

**从语言页按返回键时的流程**：

```
用户按返回键
  ↓
DefaultActivity.onBackPressed()
  ↓
StateMachine.transitToPrevious()
  ↓
LanguageState.onLeave()  ← 语言页状态离开
  ↓
mCurrentState = StartupState  ← 切换回首页状态
  ↓
StartupState.onEnter()  ← 🔥 重新进入首页状态
```

### 6.3 StartupState.onEnter() 重新创建 Fragment

```java:629-648:src/com/android/provision/activities/DefaultActivity.java
@Override
public void onEnter(boolean canGoBack, boolean toNext) {
    DefaultActivity activity = (DefaultActivity) context;
    FragmentManager fragmentManager = activity.getSupportFragmentManager();
    startupFragment = new StartupFragment();  // ← 🔥 创建新的 Fragment 实例
    if (fragmentManager.findFragmentByTag(StartupFragment.class.getSimpleName()) == null) {
        buildStartupFragment(startupFragment, fragmentManager);  // ← 添加到 Activity
    } else {
        startupFragment.setInitialSavedState(savedState);  // ← 恢复保存的状态
        buildStartupFragment(startupFragment, fragmentManager);  // ← 添加到 Activity
    }
    addShutdownTask();
    Utils.isShowLanguageListAnim = true;
}

private void buildStartupFragment(Fragment fragment, FragmentManager fragmentManager) {
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.replace(android.R.id.content, fragment, StartupFragment.class.getSimpleName());
    // ← 🔥 replace 会将 Fragment 的 View 添加到 android.R.id.content
    fragmentTransaction.commitAllowingStateLoss();
}
```

**关键点**：
- 每次进入 `StartupState` 都会创建**全新的 Fragment 实例**
- 通过 `replace` 将新 Fragment 添加到 `android.R.id.content`
- 新 Fragment 会执行完整的生命周期：`onAttach → onCreate → onCreateView → onViewCreated → onStart → onResume`

### 6.4 状态恢复机制

```java:651-657:src/com/android/provision/activities/DefaultActivity.java
@Override
public void onLeave() {
    DefaultActivity defaultActivity = (DefaultActivity) context;
    FragmentManager fragmentManager = defaultActivity.getSupportFragmentManager();
    Fragment fragment = fragmentManager.findFragmentByTag(StartupFragment.class.getSimpleName());
    if (fragment != null) {
        savedState = fragmentManager.saveFragmentInstanceState(fragment);
        // ← 保存 Fragment#1 的状态
    }
    cancelShutdownTask();
}
```

```java:637-638
startupFragment.setInitialSavedState(savedState);
// ← 恢复到 Fragment#2，保证 UI 状态一致
```

**作用**：虽然创建了新的 Fragment 实例，但通过恢复 `savedState`，确保 UI 状态（如滚动位置、输入内容等）看起来和离开时一样。

### 6.5 完整的 Fragment 生命周期对比

#### 第一次进入语言页（前进）

```
[点击"下一步"]
  ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  StartupFragment 实例 #1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ↓
startActivityForResult(LanguagePickerActivity)
  ↓
【前进动画执行】
  ↓
exitFinishCallback 触发
  ├─ fragmentTransaction.remove(startupFragment)
  ├─ StartupFragment#1.onDestroyView()  ← View 被销毁
  ├─ StartupFragment#1.onDetach()  ← Fragment 从 Activity 分离
  └─ StartupFragment#1 被移除，但实例还在内存（被回调引用）
  
此时：
  - android.R.id.content 显示语言页 ✅
  - StartupFragment#1 已经 detached
```

#### 从语言页返回首页（后退）

```
[按返回键]
  ↓
transitToPrevious()
  ├─ LanguageState.onLeave()
  └─ StartupState.onEnter()  ← 🔥 关键
      ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  创建 StartupFragment 实例 #2（新实例！）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ↓
  fragmentTransaction.replace(android.R.id.content, startupFragment)
      ↓
  StartupFragment#2.onAttach(DefaultActivity)
  StartupFragment#2.onCreate()
  StartupFragment#2.onCreateView()  ← 🔥 创建新的 View 树
  StartupFragment#2.onViewCreated()
  StartupFragment#2.onStart()
  StartupFragment#2.onResume()
      ↓
  【返回动画执行】
  StartupFragment#1 的 exitStartedCallback 触发（旧实例的回调）
      ↓ 操作 Fragment#1 的 mNextLayout（已经不在 Activity 中）
  StartupFragment#1 的 exitFinishCallback 触发（旧实例的回调）
      ↓ getActivity() = null，空指针保护生效
      ↓
此时：
  - android.R.id.content 显示 StartupFragment#2 的 View ✅
  - StartupFragment#2 已经 attached
  - StartupFragment#1 的回调操作无效（View 不在屏幕上）
```

### 6.6 两个 Fragment 实例的对比

| 特性 | Fragment#1（旧实例） | Fragment#2（新实例） |
|------|---------------------|---------------------|
| **创建时机** | 首次启动 | 从语言页返回时 |
| **状态** | 已 detached | 已 attached |
| **getActivity()** | 返回 `null` ❌ | 返回 `DefaultActivity` ✅ |
| **View 位置** | 已从 Activity 移除 | 在 `android.R.id.content` 中显示 ✅ |
| **回调绑定** | 回调仍绑定到这个实例 | 无回调（继承自 Fragment#1） |
| **可见性** | 不可见（不在屏幕上） | 可见（用户看到的就是这个） ✅ |

### 6.7 为什么要这样设计？

| 优点 | 说明 |
|------|------|
| ✅ **状态机驱动** | 每次进入 StartupState 都重新创建，确保状态一致 |
| ✅ **生命周期清晰** | Fragment 的生命周期完全由状态机控制 |
| ✅ **状态恢复** | 通过 `savedState` 确保 UI 状态正确恢复 |
| ✅ **内存管理** | 旧实例最终会被 GC 回收 |
| ✅ **动画隔离** | 旧实例的回调不会影响新实例的 UI |

---

## 七、返回动画（从语言页返回首页）

### 7.1 返回动画准备

```java:410-428
mNext.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
    @Override
    public boolean onPreDraw() {
        mNext.getViewTreeObserver().removeOnPreDrawListener(this);
        if (Utils.CACHE_BITMAP != null) {
            updateLocation(Utils.CACHE_BITMAP);  // 使用缓存的位图更新位置
        } else {
            // 如果缓存丢失，重新截图
            ViewUtils.captureRoundedBitmap(getActivity(), mNext, mainHandler, 
                new ViewUtils.RoundedBitmapCallback() {
                    @Override
                    public void onBitmapReady(Bitmap roundedBitmap) {
                        updateLocation(roundedBitmap);
                    }
                });
        }
        return true;
    }
});
```

**关键点**：
- 在 `onResume` 时监听 `onPreDraw`（即将绘制时）
- 优先使用缓存的位图（`Utils.CACHE_BITMAP`）
- 如果缓存失效，重新截图

### 6.2 更新返回动画数据

```java:430-454
private void updateLocation(Bitmap bitmap){
    try {
        int[] loc = new int[2];
        int foreGroundColor = getAnimForeGroundColor();
        mNext.getLocationInWindow(loc);
        
        // 判断是否需要更新
        if (!Utils.IS_START_ANIMA || 
            (Utils.LOCATION_X == loc[0] && Utils.LOCATION_Y == loc[1] && !isNeedRotation())){
            return;  // 位置未变化且无需旋转，不更新
        }
        
        // 如果RTL方向变化，旋转位图180度
        if (isNeedRotation()){
            bitmap = ViewUtils.rotateBitmap180(bitmap);
        }
        
        // 将数据传递给Activity，用于返回动画
        Bundle bundle = new Bundle();
        bundle.putInt("xInScreen", loc[0]);
        bundle.putInt("yInScreen", loc[1]);
        bundle.putParcelable("scaleDownBitmap", bitmap);
        bundle.putInt("scaleDownColor", foreGroundColor);
        bundle.putBoolean("disableBackAnimation", false);
        
        Class<?> clazz = Activity.class;
        Method declaredMethod = clazz.getDeclaredMethod("updateScaleUpDownData", Bundle.class);
        declaredMethod.setAccessible(true);
        declaredMethod.invoke(getActivity(), bundle);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

**返回动画原理**：
1. 通过反射调用 `Activity.updateScaleUpDownData()`
2. 传递按钮的位置、截图、颜色等数据
3. 系统根据这些数据执行从全屏缩小到圆形按钮的动画

### 7.3 返回时的View跳动问题修复

```java:266-276
// 语言页返回首页过程中，窗口动画结束时，因为截图的bitmap和实际View的位置可能不同，会导致View跳动
// 因此在返回时先隐藏View再显示
if (Utils.IS_START_ANIMA) {
    mNextLayout.setVisibility(View.INVISIBLE);
    mainHandler.postDelayed(() -> {
        if (mNextLayout.getVisibility() == View.INVISIBLE) {
            mNextLayout.setVisibility(View.VISIBLE);
        }
        Utils.IS_START_ANIMA = false;
    }, 505);
}
```

**问题**：返回动画结束时，截图位置和真实View位置可能不一致，导致View跳动

**解决方案**：
1. 先将按钮设置为 `INVISIBLE`（Fragment#2 的 View）
2. 延迟 **505ms** 后再设置为 `VISIBLE`
3. 延迟时间略大于动画时长，确保动画完全结束

**注意**：这个操作针对的是 Fragment#2（新实例）的 View，与 exitStartedCallback 中操作的 Fragment#1 的 View 无关。

---

## 八、动画时序总图

### 8.1 首次启动完整流程

```
[StartupFragment onCreate]
    ↓
[onViewCreated]
    ↓ (IS_SUPPORT_WELCOME_ANIM && isFirstBoot)
[mLogoImageWrapper = INVISIBLE]  ← 隐藏Logo
[mNextLayout = INVISIBLE]        ← 隐藏按钮
[mNextLayout.setEnabled(false)]  ← 禁用按钮
    ↓
[onStart]
    ↓
[onResume]
    ↓
[onWindowFocusChanged(true)]
    ↓ (isFirstBoot = true)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【进场动画开始】t=0ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[mGlowController.start(true)]        ← 光波动画
[AnimHelper.startPageLogoAnim()]     ← Logo动画
[AnimHelper.startPageBtnAnim()]      ← 按钮动画
    ↓
    | 动画执行中...（1800ms）
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【进场动画结束】t=1800ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[onComplete回调]
[mNextLayout.setEnabled(true)]       ← 启用按钮
    ↓
    | 用户可以点击...
    ↓
[兜底逻辑] t=2500ms
[mNextLayout = VISIBLE]
[mNextLayout.setEnabled(true)]
```

### 8.2 点击"下一步"退场流程（Fragment#1）

```
[用户点击mNextLayout]
    ↓
[防抖检查：2秒内不能重复点击]
    ↓
[enterLanguagePickPage]
    ↓
[captureRoundedBitmap] ← 截取按钮位图
    ↓
[startPickPage]
    ↓
[创建ActivityOptions动画（包含双向回调）]
[缓存位置/位图: Utils.LOCATION_X/Y, CACHE_BITMAP]
    ↓
[startActivityForResult(LanguagePickerActivity)]
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【前进动画开始】t=0ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[exitStartedCallback 触发]（Fragment#1）
[Fragment#1.mNextLayout = INVISIBLE]  ← 隐藏原始按钮
    ↓
    | 缩放动画执行中...（圆形放大到全屏）
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【前进动画结束】t=?ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[exitFinishCallback 触发]（Fragment#1）
  ├─ Fragment#1.mNextLayout = VISIBLE  ← 恢复按钮可见性
  ├─ fragmentTransaction.remove(Fragment#1)  ← 移除Fragment#1
  └─ Fragment#1.onDetach()  ← Fragment#1 与Activity分离
      ↓
[语言选择页完全显示]
[Fragment#1 已 detached，getActivity() = null]
```

### 8.3 从语言页返回流程（Fragment#2 + Fragment#1回调）

```
[语言选择页按返回键]
    ↓
[StateMachine.transitToPrevious()]
    ↓
[StartupState.onEnter() 再次调用]
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  【创建 Fragment#2（新实例）】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[new StartupFragment()]  ← Fragment#2
[fragmentTransaction.replace(Fragment#2)]
    ↓
[Fragment#2.onAttach(DefaultActivity)]
[Fragment#2.onCreate()]
[Fragment#2.onCreateView()]  ← 创建新的View树
[Fragment#2.onViewCreated()]
[Fragment#2.onStart()]
[Fragment#2.onResume()]
    ↓
[onPreDraw监听器触发]（Fragment#2）
    ↓
[updateLocation] ← 更新返回动画数据
[Activity.updateScaleUpDownData()] ← 通过反射更新
[disableBackAnimation = false] ← 返回动画启用
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【返回动画开始】t=0ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[exitStartedCallback 触发]（Fragment#1 的回调！）
  ├─ Fragment#1.mNextLayout = INVISIBLE  ← 操作旧View（已不在屏幕）
  └─ 不影响 Fragment#2 的显示
    ↓
[Fragment#2.mNextLayout = INVISIBLE]  ← onViewCreated中的逻辑
    ↓
    | 缩放动画执行中...（全屏缩小到圆形）
    | 屏幕显示：Fragment#2 的 View ✅
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    【返回动画结束】t=?ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[exitFinishCallback 触发]（Fragment#1 的回调！）
  ├─ Fragment#1.mNextLayout = VISIBLE  ← 操作旧View（已不在屏幕）
  ├─ Fragment#1.getActivity() = null  ← 空指针保护生效
  └─ 直接 return，不执行移除操作
    ↓
[延迟505ms]（Fragment#2 的延迟逻辑）
[Fragment#2.mNextLayout = VISIBLE]  ← 显示新按钮 ✅
[Utils.IS_START_ANIMA = false]
    ↓
[最终屏幕显示：Fragment#2 的完整UI]
```

---

## 九、关键设计要点总结

### 9.1 性能优化

| 优化项 | 实现方式 | 效果 |
|--------|----------|------|
| **渲染优化** | `renderViewLayout.attachView(mGlowEffectView, 0.2f)` | 将渲染分辨率降至 20%，大幅减少GPU消耗 |
| **硬件加速** | `TurboApi.setDefaultTurbo(view)` + `BoostHelper.boostDefault(view)` | 使用硬件加速，提升动画流畅度 |
| **防抖机制** | 2000ms 点击间隔限制 | 防止用户快速重复点击导致多次跳转 |
| **按钮禁用** | 动画期间 `mNextLayout.setEnabled(false)` | 防止动画未完成时用户点击 |

### 9.2 兼容性处理

| 场景 | 处理方式 |
|------|----------|
| **低端设备** | `IS_SUPPORT_WELCOME_ANIM = false`，使用静态图片，跳过所有动画 |
| **折叠屏** | `isFirstBoot` 延迟 3000ms 重置，避免内外屏切换时重复动画 |
| **RTL语言** | 检测方向变化，自动旋转位图 180° |
| **截图失败** | 降级为直接跳转（无动画） |
| **缓存丢失** | 返回时重新截图 |

### 9.3 稳定性保障

| 保障措施 | 实现 |
|----------|------|
| **兜底显示** | 2500ms 后强制显示 UI，即使动画失败 |
| **空指针保护** | `exitFinishCallback` 中检查 `getActivity() == null` |
| **单次监听** | `onPreDraw` 监听器执行后立即移除 |
| **状态容错** | 使用 `commitAllowingStateLoss()` 避免状态异常 |
| **View跳动修复** | 返回时延迟 505ms 显示，避免位置不一致 |
| **Fragment重建** | 状态机驱动，每次返回重新创建Fragment实例 |

### 9.4 模糊效果支持

```java:241-263
if (Utils.isBlurEffectEnabled(getContext())) {
    // 背景模糊
    MiuiBlurUtils.setBackgroundBlur(miuiEnterLayout, (int) (50 * density + 0.5f));
    
    // Logo 模糊混色
    int[] textBlendColor = new int[]{0xCC4A4A4A, 0xFF4F4F4F, 0xFF1AF200};
    int[] textBlendMode = new int[]{19, 100, 106};
    BlurUtils.setupViewBlur(mLogoImage, true, textBlendColor, textBlendMode);
    
    // 按钮模糊混色
    int[] buttonBlendColor = new int[]{0xFF2E2E2E, 0xFF1AF200};
    int[] buttonBlendMode = new int[]{100, 106};
    BlurUtils.setupViewBlur(mNext, true, buttonBlendColor, buttonBlendMode);
}
```

**降级方案**：
- 如果模糊效果不支持 → 使用 lite 版本的静态图片资源

---

## 十、常见问题排查

### 问题1：首页动画不执行

**可能原因**：
1. `Utils.isFirstBoot = false`（不是首次启动）
2. `IS_SUPPORT_WELCOME_ANIM = false`（低端设备）
3. `onWindowFocusChanged` 未触发

**排查方法**：
```java
Log.i(TAG, "IS_SUPPORT_WELCOME_ANIM: " + IS_SUPPORT_WELCOME_ANIM);
Log.i(TAG, "Utils.isFirstBoot: " + Utils.isFirstBoot);
Log.i(TAG, "onWindowFocusChanged hasFocus: " + hasFocus);
```

### 问题2：点击"下一步"无动画

**可能原因**：
1. `captureRoundedBitmap` 截图失败 → 走了降级逻辑
2. 按钮截图为空 → `roundedBitmap == null`

**排查方法**：
```java
Log.d(TAG, "roundedBitmap is null: " + (roundedBitmap == null));
```

### 问题3：返回首页时View跳动

**原因**：动画结束时截图位置与真实View位置不一致

**解决方案**：已通过延迟 505ms 显示修复（第 266-276 行）

### 问题4：exitFinishCallback 中 getActivity() 为 null

**场景**：多次往返首页和语言页后触发

**原因**：Fragment 已被移除，但动画回调仍然执行

**解决方案**：已加空指针保护（第 669-673 行）

---

## 十一、与 AnimHelper 的关系

StartupFragment 依赖 `AnimHelper` 类实现具体的动画效果：

```java
AnimHelper.startPageLogoAnim(mLogoImageWrapper);         // Logo 动画
AnimHelper.startPageBtnAnim(mNextLayout, listener);      // 按钮动画
```

**建议**：如需了解动画的具体实现细节（如透明度、位移、缩放等），需要进一步分析 `AnimHelper.java`。

---

## 十二、核心代码位置索引

### 12.1 StartupFragment 代码位置

| 功能 | 方法 | 行号 |
|------|------|------|
| **进场动画触发** | `onWindowFocusChanged()` | 536-568 |
| **Logo动画** | `AnimHelper.startPageLogoAnim()` | 550 |
| **按钮动画** | `AnimHelper.startPageBtnAnim()` | 555 |
| **光波动画** | `mGlowController.start(true)` | 542 |
| **退场动画准备** | `enterLanguagePickPage()` | 610-622 |
| **创建缩放动画** | `startPickPage()` | 624-645 |
| **exitStartedCallback** | 定义 | 651-659 |
| **exitFinishCallback** | 定义 | 661-683 |
| **返回动画数据更新** | `updateLocation()` | 430-454 |
| **防抖处理** | `mNextLayout.setOnClickListener()` | 326-343 |
| **兜底显示逻辑** | `displayOsLogoDelay()` | 578-593 |

### 12.2 DefaultActivity 状态机代码位置

| 功能 | 方法 | 行号 |
|------|------|------|
| **StartupState 进入** | `StartupState.onEnter()` | 629-642 |
| **StartupState 离开** | `StartupState.onLeave()` | 651-659 |
| **Fragment 构建** | `buildStartupFragment()` | 644-648 |
| **状态机后退** | `StateMachine.transitToPrevious()` | 2077-2101 |
| **移除 Fragment 消息** | `Handler.handleMessage()` | 155-170 |

---

## 十三、总结

### exitStartedCallback 核心作用：
- ⏱️ **触发时机**：前进和后退动画**开始时**都会触发
- 🎯 **核心作用**：隐藏按钮（`mNextLayout = INVISIBLE`），避免与动画位图重影
- ⚠️ **注意事项**：
  - 使用 `INVISIBLE` 保持布局空间
  - 前进动画时操作 Fragment#1 的 View
  - 后退动画时也操作 Fragment#1 的 View（但已不在屏幕上）

### exitFinishCallback 核心作用：
- ⏱️ **触发时机**：前进和后退动画**完全结束时**都会触发
- 🎯 **核心作用**：
  1. 恢复按钮可见性（`mNextLayout = VISIBLE`）
  2. 前进动画时：移除 StartupFragment#1 释放资源
  3. 后退动画时：由于 Fragment#1 已 detached，空指针保护生效
- ⚠️ **注意事项**：
  - 需要空指针保护（`getActivity() == null`）
  - 回调操作的是 Fragment#1，但屏幕显示的是 Fragment#2

### Fragment 重建机制核心：
- ⭐ **状态机驱动**：每次返回首页都会重新创建 Fragment 实例
- ⭐ **双实例并存**：Fragment#1（旧实例，持有回调）+ Fragment#2（新实例，屏幕显示）
- ⭐ **回调隔离**：旧实例的回调无法影响新实例的 UI
- ⭐ **状态恢复**：通过 `savedState` 确保 UI 状态一致

### 动画设计亮点：
1. ✅ **性能优化**：渲染降分辨率、硬件加速、防抖机制
2. ✅ **兼容性好**：低端设备降级、折叠屏适配、RTL支持
3. ✅ **稳定性高**：兜底逻辑、空指针保护、状态容错、Fragment重建
4. ✅ **体验流畅**：三层动画同步、双向动画无缝衔接
5. ✅ **架构清晰**：状态机管理生命周期，Fragment 重建确保状态一致
