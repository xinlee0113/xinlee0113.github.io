---
layout: default
title: DefaultActivity与GlobalDefaultActivity对比总结
parent: 模块解析
---



# DefaultActivity与GlobalDefaultActivity对比总结

## 1. 整体定位对比

### 1.1 核心职责

| 维度 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|----------------------|
| **核心定位** | 第一阶段主控制器 | 第二阶段主控制器 |
| **主要职责** | 基础系统配置 | MIUI个性化配置 |
| **目标用户** | 所有新用户 | 国际版GMS用户 |
| **适用场景** | 国内版完整流程 / 国际版前置流程 | 国际版GMS中间插入流程 |

### 1.2 架构图示

```
国内版流程：
┌────────────────────────────────────────────────┐
│           DefaultActivity                       │
│  (完整流程：从启动页到完成)                      │
│                                                 │
│  StartupState → LanguageState → ... → CompleteState │
└────────────────────────────────────────────────┘
                    ↓
              进入系统桌面


国际版新OOBE流程：
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   GMS SUW   │  →  │DefaultActivity│  →  │   GMS SUW   │  →  │GlobalDefaultActivity│
│   (前置)     │     │  (基础配置)   │     │  (GMS流程)   │     │ (个性化配置)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                     ↓
                                                            ┌─────────────┐
                                                            │OemPostActivity│
                                                            │  (完成清理)   │
                                                            └─────────────┘
                                                                     ↓
                                                              进入系统桌面
```

---

## 2. 技术实现对比

### 2.1 类继承关系

```java
// DefaultActivity
public class DefaultActivity extends ProvisionBaseActivity {
    // ProvisionBaseActivity提供了丰富的引导页面框架功能
}

// GlobalDefaultActivity
public class GlobalDefaultActivity extends AppCompatActivity {
    // AppCompatActivity是标准的Activity基类
}
```

**差异原因**：
- DefaultActivity需要更多UI框架支持（启动动画、页面模板等）
- GlobalDefaultActivity主要做流程控制，UI由各个子Activity实现

### 2.2 Intent Action

| Activity | Intent Action | 触发者 |
|----------|--------------|--------|
| DefaultActivity | `com.android.provision.global.STARTUP` | GMS SetupWizard / 系统启动 |
| GlobalDefaultActivity | `com.android.provision.global.SECOND` | GMS SetupWizard (wizard_script) |

### 2.3 状态持久化Key

```java
// DefaultActivity
private static final String PREF_STATE = "pref_state";  // Utils.PREF_STATE

// GlobalDefaultActivity  
private static final String PREF_STATE_GLOBAL = "pref_state_global";
```

**隔离原因**：两个Activity可能同时存在状态（异常场景），避免相互覆盖

---

## 3. 状态机对比

### 3.1 State数量

| Activity | State总数 | 内部State | 外部State | 完整流程长度 |
|----------|----------|----------|----------|-------------|
| DefaultActivity | 30+ | 约15个 | 约15个 | 长（完整引导） |
| GlobalDefaultActivity | 17 | 约10个 | 约7个 | 中（个性化为主） |

### 3.2 核心State对比

#### DefaultActivity独有State

```
StartupState          - 启动页（品牌动画）
LanguageState         - 语言选择
LocalePickerState     - 地区选择
ZonePickerState       - 时区选择
InputMethodState      - 输入法选择
WifiState             - WiFi连接
FontSizeState         - 字体大小（国内版）
EsimDateState         - eSIM数据卡
SimCardDetectionState - SIM卡检测
MultiSimSettingsState - 多SIM卡设置
GoogleAccountState    - Google账号（国际版旧OOBE）
TermsState            - 用户协议
TermsAndStatementState - 条款声明
CMTermsState          - 移动条款
CUTermsState          - 联通条款
PrivacyState          - 隐私设置
PrivacyCenterState    - 隐私中心
VoiceAssistState      - 语音助手
AIButtonState         - AI按钮设置
MiMoverState          - 小米换机
```

#### GlobalDefaultActivity独有State

```
FontState             - 字体设置（国际版，MiSans）
CarouselState         - 轮播推荐
LocationInState       - 位置信息权限
HomeSettingsState     - 桌面布局设置
ParentalControlState  - 家长控制
KindTipState          - 温馨提示（折叠屏）
GestureTutorialState  - 手势教程
```

#### 两者共有State（功能相似但实现独立）

```
AccountState          - 小米账号登录
CloudServiceState     - 云服务设置
FindDeviceState       - 查找设备
CloudBackupState      - 云备份还原
FingerprintState      - 指纹录入
OtherState            - 其他设置
ThemePickerState      - 主题选择
NavigationModePickerState - 导航模式选择
RecentTaskStyleState  - 最近任务样式
BootVideoState        - 开机视频
RecommendedState      - 应用推荐
CongratulationState   - 完成页面
```

### 3.3 State创建方式对比

```java
// DefaultActivity - 直接通过类名创建
State startupState = State.create("StartupState");

// GlobalDefaultActivity - 通过反射创建（包含包路径前缀）
public static final String PREFIX = "com.android.provision.global.GlobalDefaultActivity$";
State state = (State) Class.forName(PREFIX + name).newInstance();
```

**差异原因**：
- DefaultActivity的State类更多，避免包路径前缀冗余
- GlobalDefaultActivity使用完整类名避免与DefaultActivity冲突

---

## 4. 流程控制对比

### 4.1 启动入口

```java
// DefaultActivity
@Override
protected void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    
    // 检查是否已完成引导
    if (deviceIsProvisioned()) {
        finishSetup(false);
        return;
    }
    
    // 各种初始化（网络监听、异常服务、PreLoadManager等）
    // ...
    
    // 创建并启动状态机
    mStateMachine = new StateMachine(this);
    boolean enterCurrent = (icicle == null || 
        icicle.getBoolean(STATE_ENTER_CURRENTSTATE, true));
    mStateMachine.start(enterCurrent);
}

// GlobalDefaultActivity
@Override
protected void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    
    // 直接创建并启动状态机（无需检查provision状态）
    mStateMachine = new StateMachine(this);
    boolean enterCurrent = (icicle == null || 
        icicle.getBoolean(STATE_ENTER_CURRENTSTATE, true));
    mStateMachine.start(enterCurrent);
    
    // 注册网络监听
    registerNetworkChangedReceiver();
}
```

### 4.2 完成流程

```java
// DefaultActivity - 复杂的完成逻辑
if (mCurrentState == mCompleteState) {
    // 1. Trustonic处理
    // 2. 设置默认桌面
    // 3. 卸载特定应用（Claro/Siprogo）
    // 4. 发送完成广播
    // 5. 清理状态
    // 6. 标记provision完成
    // 7. 跳转到下一页或结束
}

// GlobalDefaultActivity - 简化的完成逻辑
if (mCurrentState == mCompleteState) {
    // 1. Trustonic处理
    // 2. 设置默认桌面
    // 3. 卸载特定应用
    // 4. 清理状态
    // 5. 跳转到OemPostActivity（由GMS控制）
}
```

### 4.3 返回按钮处理

两者都支持返回操作，但细节有差异：

```java
// DefaultActivity
private void transitToPrevious() {
    if (mStateStack.size() <= 0) {
        return;  // 已经是第一个状态，不处理（停留在首页）
    }
    // 弹出状态栈，返回上一页
    // 特殊处理：返回到StartupState时设置已启动标记
}

// GlobalDefaultActivity
private void transitToPrevious() {
    if (mStateStack.size() <= 0) {
        clearState(PREF_STATE_GLOBAL);
        ((Activity) mContext).finish();  // 直接结束Activity，返回GMS
        return;
    }
    // 弹出状态栈，返回上一页
}
```

---

## 5. 功能模块对比

### 5.1 PreLoadManager（预加载优化）

```java
// DefaultActivity - 使用PreLoadManager
PreLoadManager.get().setCompleteDefaultActivityLoad();
PreLoadManager.get().addGlobalActivityClass(state);

// GlobalDefaultActivity - 使用PreLoadManager
PreLoadManager.get().addGlobalActivityClass(state);
```

### 5.2 网络监听

```java
// DefaultActivity
private void registerNetworkChangedReceiver() {
    if (Build.IS_INTERNATIONAL_BUILD && !mIsNetworkRegistered) {
        // 国际版注册网络监听
    }
}

// GlobalDefaultActivity
private void registerNetworkChangedReceiver() {
    if (Build.IS_INTERNATIONAL_BUILD && !mIsNetworkRegistered) {
        // 国际版注册网络监听（与DefaultActivity相同）
    }
}
```

**注意**：两者都只在国际版注册网络监听

### 5.3 异常恢复

```java
// DefaultActivity
// 启动异常监控服务
Intent abnormalBackService = new Intent(this, AbnormalBackService.class);
startService(abnormalBackService);

// GlobalDefaultActivity
// 无异常监控服务
```

**差异原因**：
- DefaultActivity是首次进入，需要监控异常返回
- GlobalDefaultActivity由GMS控制，异常由GMS处理

---

## 6. 跨状态通信对比

### 6.1 实现方式

两者都使用**中介者模式**，但细节略有不同：

```java
// DefaultActivity
public void onResult(int resultCode, Intent data) {
    if (mCurrentState == mAccountState) {
        mCloudServiceState.onLoginResult(resultCode, data);
        mFindDeviceState.onLoginResult(resultCode, data);
    }
}

// GlobalDefaultActivity
public void onResult(int resultCode, Intent data) {
    if (mCurrentState == mAccountState) {
        mCloudServiceState.onLoginResult(resultCode, data);
        mFindDeviceState.onLoginResult(resultCode, data);
    }
}
```

**共同点**：都通过StateMachine.onResult()中介传递

### 6.2 特殊State保存

```java
// DefaultActivity
private State mMultiSimSettingsState;
private State mAccountState;
private CloudServiceState mCloudServiceState;
private FindDeviceState mFindDeviceState;
private BootVideoState mBootVideoState;

// GlobalDefaultActivity
private State mAccountState;
private CloudServiceState mCloudServiceState;
private FindDeviceState mFindDeviceState;
private BootVideoState mBootVideoState;
```

---

## 7. 性能优化对比

### 7.1 启动速度

| Activity | 启动时间 | 优化措施 |
|----------|---------|---------|
| DefaultActivity | 较长 | PreLoadManager预加载、Lottie动画延迟加载 |
| GlobalDefaultActivity | 较短 | 无启动动画、直接进入首个State |

### 7.2 内存占用

| Activity | 内存占用 | 原因 |
|----------|---------|------|
| DefaultActivity | 高 | 包含StartupFragment、预加载多个Activity |
| GlobalDefaultActivity | 中 | 仅加载状态机和当前State |

---

## 8. 版本兼容策略

### 8.1 国内版 vs 国际版

```
国内版：
  ├─ DefaultActivity（完整流程）
  └─ 不使用GlobalDefaultActivity

国际版（旧OOBE）：
  ├─ DefaultActivity（简化流程，仅基础配置）
  └─ 不使用GlobalDefaultActivity

国际版（新OOBE）：
  ├─ DefaultActivity（极简流程，语言+输入法+WiFi）
  ├─ GMS SetupWizard（Google流程）
  └─ GlobalDefaultActivity（MIUI个性化配置）
```

### 8.2 判断逻辑

```java
// DefaultActivity中判断是否使用新OOBE
if (Utils.isNewGlobalOOBE()) {
    // 新OOBE：简化流程，快速返回GMS
    setNextState(inputMethodState, termsState);
} else {
    // 旧OOBE：包含WiFi、字体大小等
    setNextState(inputMethodState, wifiSetting);
    // ...
}
```

---

## 9. 设计模式对比

### 9.1 共同使用的设计模式

| 设计模式 | 应用场景 | 优势 |
|---------|---------|------|
| **状态模式** | 管理页面流转 | 封装状态转换逻辑 |
| **责任链模式** | 状态顺序执行 | 灵活调整顺序 |
| **Builder模式** | State属性设置 | 链式调用美观 |
| **策略模式** | isAvailable判断 | 不同State不同策略 |
| **中介者模式** | 跨状态通信 | 降低耦合度 |

### 9.2 特有设计模式

| Activity | 独特设计模式 | 应用场景 |
|----------|-----------|---------|
| DefaultActivity | **模板方法** | ProvisionBaseActivity定义UI框架 |
| GlobalDefaultActivity | **反射创建** | 动态加载State类 |

---

## 10. 代码质量对比

### 10.1 代码行数

| Activity | 总行数 | StateMachine行数 | State类数量 |
|----------|-------|----------------|------------|
| DefaultActivity | ~2600行 | ~600行 | 30+ |
| GlobalDefaultActivity | ~1130行 | ~400行 | 17 |

### 10.2 复杂度评估

| 维度 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|----------------------|
| **流程复杂度** | 高（分支多） | 中（相对线性） |
| **代码耦合度** | 中（依赖ProvisionBaseActivity） | 低（仅依赖AppCompatActivity） |
| **测试难度** | 高（State多、依赖多） | 中（State少、逻辑清晰） |
| **维护成本** | 高（历史包袱重） | 中（相对新代码） |

---

## 11. 使用场景决策树

```
开机引导启动
  ↓
是否国内版？
  ├─ 是 → DefaultActivity（完整流程） → 完成
  └─ 否 → 是国际版
            ↓
         是否新OOBE？
           ├─ 是 → DefaultActivity（基础配置）
           │        ↓
           │      返回GMS
           │        ↓
           │      GMS流程
           │        ↓
           │      GlobalDefaultActivity（个性化配置）
           │        ↓
           │      OemPostActivity
           │        ↓
           │      完成
           └─ 否 → DefaultActivity（简化完整流程） → 完成
```

---

## 12. 未来优化建议

### 12.1 统一建议

1. **配置化流程定义**
   - 使用JSON/XML定义状态流转关系
   - 减少硬编码，提高可维护性

2. **增强监控埋点**
   - 统计每个State的通过率、耗时、跳过率
   - 分析用户行为，优化流程

3. **模块化重构**
   - 按功能领域拆分State（账号、个性化、UI等）
   - 提高代码可读性

4. **单元测试覆盖**
   - 抽取状态机核心逻辑
   - 增加单元测试，保证重构安全

### 12.2 DefaultActivity特有建议

1. **简化流程分支**
   - 国内版/国际版/企业版分支过多
   - 考虑策略模式重构

2. **减少历史包袱**
   - 清理废弃代码（如已注释的逻辑）
   - 移除不再使用的State

### 12.3 GlobalDefaultActivity特有建议

1. **增强与GMS协作**
   - 更清晰的Intent参数传递
   - 更完善的错误处理

2. **优化外部依赖**
   - 云服务、主题管理器等外部App可用性检查
   - 增加降级方案

---

## 13. 总结

### 13.1 核心差异

| 维度 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|----------------------|
| **定位** | 基础配置入口 | 个性化配置入口 |
| **复杂度** | 高（功能全） | 中（聚焦个性化） |
| **适用范围** | 广（国内+国际） | 窄（国际版新OOBE） |
| **演进方向** | 精简分支 | 丰富个性化 |

### 13.2 设计哲学

- **DefaultActivity**：大而全，兼容所有场景
- **GlobalDefaultActivity**：小而美，专注MIUI特色

### 13.3 开发建议

1. 新增基础配置功能 → 修改DefaultActivity
2. 新增个性化功能（国际版） → 修改GlobalDefaultActivity
3. 新增通用功能 → 评估后选择合适的Activity
4. 修改现有功能 → 先确认版本兼容性，再修改

### 13.4 关键要点

- 两者是**互补关系**，不是替代关系
- GlobalDefaultActivity依赖GMS环境，不能独立运行
- DefaultActivity是向后兼容的，GlobalDefaultActivity是面向未来的
- 理解两者差异有助于准确定位问题和开发新功能

