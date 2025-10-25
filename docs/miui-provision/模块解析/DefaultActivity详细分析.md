---
layout: default
title: DefaultActivity 详细分析
parent: MiuiProvision项目文档
---

# DefaultActivity 详细分析

## 1. 概述

### 1.1 定义与定位

```java
/**
 * Application that sets the provisioned bit, like SetupWizard does.
 */
public class DefaultActivity extends ProvisionBaseActivity {
    private static final String TAG = "Provision_DefaultActivity";
}
```

**核心职能**：
- MIUI开机引导的**第一阶段（Primary Stage）**主控制器
- 负责**国内版（CN版本）**的完整开机引导流程
- 负责**国际版非GMS前置流程**（如语言、网络、基础设置等）
- 通过状态机管理语言、输入法、网络、账号、指纹等基础配置流程

### 1.2 适用场景

| 场景 | 适用版本 | 触发时机 |
|------|---------|---------|
| 国内版开机引导 | CN Build | 设备首次开机/恢复出厂设置 |
| 国际版前置流程 | Global Build (非新OOBE) | GMS引导之前的基础配置 |
| 企业版激活 | Enterprise Build | 企业设备激活流程 |

---

## 2. 启动方式与入口

### 2.1 Intent Filter注册

```xml:66:81:global/AndroidManifest.xml
<activity android:name=".activities.DefaultActivity"
        android:enableOnBackInvokedCallback="false"
        android:excludeFromRecents="true"
        android:screenOrientation="portrait"
        android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale"
        android:immersive="true"
        android:directBootAware="true"
        android:exported="true">
    <meta-data
        android:name="miui.supportFlipFullScreen"
        android:value="0" />
    <intent-filter>
        <action android:name="com.android.provision.global.STARTUP" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</activity>
```

### 2.2 触发路径

#### 方式1：GMS Wizard Script触发（国际版）

```xml:59:62:res_gte_v34/raw/wizard_script.xml
<WizardAction id="first_setup_flow"
    wizard:uri="intent:#Intent;package=com.android.provision;action=com.android.provision.global.STARTUP;end">
    <!-- GMS首先启动DefaultActivity完成基础配置 -->
</WizardAction>
```

**流程**：
```
开机 → GMS SetupWizard → wizard_script.xml解析
    ↓
  first_setup_flow (WizardAction)
    ↓
  Intent Action: com.android.provision.global.STARTUP
    ↓
  DefaultActivity启动
    ↓
  完成基础配置（语言、输入法、网络等）
    ↓
  返回GMS继续后续流程
```

#### 方式2：系统直接启动（国内版）

```java:177:184:src/com/android/provision/activities/DefaultActivity.java
@Override
protected void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    Log.d(TAG, "DefaultActivity onCreate");

    if (deviceIsProvisioned()) {
        finishSetup(false);
        return;
    }
```

**检查机制**：
- 检查`Settings.Global.DEVICE_PROVISIONED`标志位
- 如果已完成引导，直接finish()
- 否则启动状态机开始引导流程

---

## 3. 核心架构：状态机模式

### 3.1 状态机设计

```java:1940:1975:src/com/android/provision/activities/DefaultActivity.java
public static class StateMachine {
    
    private Context mContext;
    private SparseArray<StateInfo> mStates;    // 所有状态映射表
    private State mCurrentState;                // 当前状态
    private ArrayList<State> mStateStack;       // 状态栈（支持返回）
    
    // 特殊状态引用（用于跨状态通信）
    private State mMultiSimSettingsState;
    private State mAccountState;
    private CloudServiceState mCloudServiceState;
    private FindDeviceState mFindDeviceState;
    private BootVideoState mBootVideoState;
    
    public StateMachine(Context context) {
        mContext = context;
        init();  // 初始化所有状态和流转关系
        PreLoadManager.get().setCompleteDefaultActivityLoad();
    }
}
```

### 3.2 State基类设计

```java
public static class State {
    protected StateMachine mStateMachine;
    protected Context context;
    protected String packageName;    // 外部Activity包名
    public String className;         // 外部Activity类名
    public Class<?> targetClass;     // 内部Activity类引用
    
    // 生命周期方法
    public void onEnter(boolean canGoBack, boolean toNext);  // 进入状态
    public void onLeave();                                   // 离开状态
    
    // 可用性判断
    public boolean isAvailable(boolean toNext);
    
    // 导航控制
    public State getNextState();
    protected boolean canBackTo();
}
```

### 3.3 状态流转机制

#### 核心方法

```java:1993:2014:src/com/android/provision/activities/DefaultActivity.java
public void run(int code) {
    switch (code) {
        case Activity.RESULT_OK:
            transitToNext();      // 用户点击"下一步" → 前进
            break;
        
        case Activity.RESULT_CANCELED:
            transitToPrevious();  // 用户点击"返回" → 后退
            break;
        
        default:
            transitToOthers();    // 其他结果码 → 特殊跳转
            break;
    }
}
```

#### transitToNext() - 前进逻辑

```java:2016:2070:src/com/android/provision/activities/DefaultActivity.java
private void transitToNext() {
    Log.d(TAG, "transitToNext mCurrentState is " + mCurrentState);
    mCurrentState.onLeave();  // 离开当前状态
    
    // 完成所有流程，退出引导
    if (mCurrentState == mCompleteState) {
        finishProvisionFlow();
        return;
    }
    
    // 将当前状态压入栈（支持返回）
    mStateStack.add(mCurrentState);
    
    // 获取下一个可用状态（跳过不可用的State）
    State preState = mCurrentState;
    mCurrentState = getNextAvailableState(mCurrentState);
    
    // 进入下一个状态
    if (mCurrentState instanceof RecommendedState) {
        ((RecommendedState) mCurrentState).display(mContext);
    } else {
        mCurrentState.onEnter(preState.canBackTo(), true);
    }
    
    // 设置页面切换动画
    ((DefaultActivity) mContext).overridePendingTransition(
        R.anim.slide_in_right, 
        R.anim.slide_out_left
    );
    
    saveState();  // 保存状态到SharedPreferences
}
```

#### transitToPrevious() - 后退逻辑

```java:2101:2125:src/com/android/provision/activities/DefaultActivity.java
private void transitToPrevious() {
    if (mStateStack.size() <= 0) {
        return;  // 已经是第一个状态，无法返回
    }
    
    // 从栈中获取上一个可用状态
    State previousState = getPreviousAvailableState(mStateStack);
    mCurrentState.onLeave();
    
    State nextState = mCurrentState;
    mCurrentState = previousState;
    
    // 特殊处理：返回到启动页时标记已启动
    if (mCurrentState instanceof StartupState) {
        ((StartupState) mCurrentState).setBooted(true);
    }
    
    int top = mStateStack.size() - 1;
    if (mCurrentState instanceof RecommendedState) {
        ((RecommendedState) mCurrentState).display(mContext);
    } else {
        mCurrentState.onEnter(top >= 0 && mStateStack.get(top).canBackTo(), false);
        // 首页进入语言页和返回有单独的动画
        if (!(nextState instanceof LanguageState)) {
            ((DefaultActivity) mContext).overridePendingTransition(
                R.anim.slide_in_left, 
                R.anim.slide_out_right
            );
        }
    }
    
    saveState();
}
```

### 3.4 状态持久化

```java:2463:2498:src/com/android/provision/activities/DefaultActivity.java
// 恢复状态（从SharedPreferences）
private void restoreState() {
    SharedPreferences preferences = mContext.getSharedPreferences(
        Utils.PREF_STATE, 
        Context.MODE_PRIVATE
    );
    
    String state = StartupState.class.getSimpleName();
    mCurrentState = getStateInfo(state).current;
    
    // 从SharedPreferences恢复状态栈
    for (int i = 0; state != null; ++i) {
        state = preferences.getString(KEY_STATE_PREFIX + i, null);
        if (state != null) {
            if (i != 0) {
                mStateStack.add(mCurrentState);
            }
            mCurrentState = getStateInfo(state).current;
        }
    }
}

// 保存状态（到SharedPreferences）
private void saveState() {
    SharedPreferences preferences = mContext.getSharedPreferences(
        Utils.PREF_STATE, 
        Context.MODE_PRIVATE
    );
    Editor editor = preferences.edit();
    editor.clear();
    
    // 保存状态栈
    for (int i = 0; i < mStateStack.size(); ++i) {
        editor.putString(
            KEY_STATE_PREFIX + i, 
            mStateStack.get(i).getClass().getSimpleName()
        );
    }
    
    // 保存当前状态
    editor.putString(
        KEY_STATE_PREFIX + mStateStack.size(), 
        mCurrentState.getClass().getSimpleName()
    );
    
    editor.apply();
}
```

---

## 4. 完整状态流程（国内版）

### 4.1 状态初始化代码

```java:2140:2400:src/com/android/provision/activities/DefaultActivity.java
private void init() {
    mStates = new SparseArray<StateInfo>();
    mStateStack = new ArrayList<State>();

    // 创建所有状态实例
    State startupState = State.create("StartupState");
    State languageState = State.create("LanguageState")
        .setTargetClass(LanguagePickerActivity.class);
    State zonePickerState = State.create("ZonePickerState")
        .setTargetClass(ZonePickerActivity.class);
    State inputMethodState = State.create("InputMethodState")
        .setTargetClass(InputMethodActivity.class);
    State wifiSetting = State.create("WifiState")
        .setPackageName("com.android.settings")
        .setClassName("com.android.settings.wifi.WifiProvisionSettingsActivity");
    State fontSize = State.create("FontSizeState")
        .setTargetClass(FontSizeActivity.class);
    State simDetectionState = State.create("SimCardDetectionState")
        .setTargetClass(SimCardDetectionActivity.class);
    State accountState = State.create("AccountState");
    State cloudServiceState = State.create("CloudServiceState")
        .setPackageName("com.miui.cloudservice")
        .setClassName("com.miui.cloudservice.ui.ProvisionSettingActivity");
    State fingerprintState = State.create("FingerprintState")
        .setTargetClass(FingerprintActivity.class);
    State otherState = State.create("OtherState")
        .setTargetClass(OtherSettingsActivity.class);
    State termsState = State.create("TermsState")
        .setTargetClass(TermsActivity.class);
    // ... 更多状态

    // 构建状态流转链
    addState(startupState);
    setNextState(startupState, languageState);
    
    addState(languageState);
    setNextState(languageState, localePickerState);
    
    addState(localePickerState);
    setNextState(localePickerState, zonePickerState);
    
    addState(zonePickerState);
    setNextState(zonePickerState, inputMethodState);
    
    addState(inputMethodState);
    setNextState(inputMethodState, wifiSetting);
    
    addState(wifiSetting);
    setNextState(wifiSetting, fontSize);
    
    addState(fontSize);
    setNextState(fontSize, termsState);
    
    // ... 更多流转关系
}
```

### 4.2 完整流程图（国内版）

```
┌─────────────┐
│  StartupState │  启动页（品牌Logo、动画）
└──────┬──────┘
       ↓
┌─────────────┐
│ LanguageState │  语言选择
└──────┬──────┘
       ↓
┌─────────────┐
│LocalePickerState│  地区选择
└──────┬──────┘
       ↓
┌─────────────┐
│ZonePickerState│  时区选择
└──────┬──────┘
       ↓
┌─────────────┐
│InputMethodState│  输入法选择
└──────┬──────┘
       ↓
┌─────────────┐
│  WifiState   │  WiFi连接
└──────┬──────┘
       ↓
┌─────────────┐
│ FontSizeState │  字体大小
└──────┬──────┘
       ↓
┌─────────────┐
│  TermsState  │  用户协议
└──────┬──────┘
       ↓
┌─────────────┐
│TermsAndStatementState│  条款声明
└──────┬──────┘
       ↓
┌─────────────┐
│SimCardDetectionState│  SIM卡检测
└──────┬──────┘
       ↓
┌─────────────┐
│ AccountState │  小米账号登录
└──────┬──────┘
       ↓
┌─────────────┐
│CloudServiceState│  云服务设置
└──────┬──────┘
       ↓
┌─────────────┐
│FindDeviceState│  查找设备
└──────┬──────┘
       ↓
┌─────────────┐
│CloudBackupState│  云备份还原
└──────┬──────┘
       ↓
┌─────────────┐
│FingerprintState│  指纹录入
└──────┬──────┘
       ↓
┌─────────────┐
│ OtherState   │  其他设置
└──────┬──────┘
       ↓
┌─────────────┐
│PrivacyCenterState│  隐私中心
└──────┬──────┘
       ↓
┌─────────────┐
│  MiMoverState │  小米换机
└──────┬──────┘
       ↓
┌─────────────┐
│ CMTermsState │  移动条款
└──────┬──────┘
       ↓
┌─────────────┐
│ CUTermsState │  联通条款
└──────┬──────┘
       ↓
┌─────────────┐
│ThemePickerState│  主题选择
└──────┬──────┘
       ↓
┌─────────────┐
│NavigationModePickerState│  导航模式
└──────┬──────┘
       ↓
┌─────────────┐
│RecentTaskStyleState│  最近任务样式
└──────┬──────┘
       ↓
┌─────────────┐
│ KindTipState │  温馨提示(折叠屏)
└──────┬──────┘
       ↓
┌─────────────┐
│BootVideoState │  开机动画
└──────┬──────┘
       ↓
┌─────────────┐
│RecommendedState│  应用推荐
└──────┬──────┘
       ↓
┌─────────────┐
│ CompleteState │  完成引导
└─────────────┘
```

### 4.3 国际版流程（旧版OOBE）

```
StartupState → LanguageState → LocalePickerState → ZonePickerState
    ↓
InputMethodState → WifiState → FontSizeState → TermsState
    ↓
（返回GMS SetupWizard继续后续流程）
```

---

## 5. 关键State实现分析

### 5.1 StartupState - 启动页

```java:854:958:src/com/android/provision/activities/DefaultActivity.java
public static class StartupState extends State {
    private boolean mBooted = false;
    
    @Override
    public void onEnter(boolean canGoBack, boolean toNext) {
        // 不启动Activity，直接显示Fragment
        if (!mBooted) {
            ((DefaultActivity) context).removeStartupFragment();
            FragmentManager fm = ((DefaultActivity) context).getSupportFragmentManager();
            FragmentTransaction ft = fm.beginTransaction();
            ft.replace(android.R.id.content, new StartupFragment(), 
                      StartupFragment.class.getSimpleName());
            ft.commitAllowingStateLoss();
        } else {
            // 已启动过，直接进入下一步
            mStateMachine.run(Activity.RESULT_OK);
        }
    }
    
    @Override
    protected boolean canBackTo() {
        return false;  // 不允许返回到启动页
    }
    
    public void setBooted(boolean booted) {
        mBooted = booted;
    }
}
```

### 5.2 AccountState - 账号登录

```java:1015:1100:src/com/android/provision/activities/DefaultActivity.java
public static class AccountState extends State {
    
    @Override
    protected Intent getIntent() {
        Intent accountIntent = new Intent(
            "com.xiaomi.account.action.XIAOMI_ACCOUNT_WELCOME"
        );
        accountIntent.setPackage("com.xiaomi.account");
        accountIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        
        Bundle bundle = new Bundle();
        bundle.putBoolean(ExtraAccountManager.EXTRA_SHOW_FIND_DEVICE, true);
        bundle.putBoolean(ExtraAccountManager.EXTRA_SHOW_SKIP_LOGIN, true);
        bundle.putBoolean(ExtraAccountManager.EXTRA_SHOW_SYNC_SETTINGS, false);
        bundle.putBoolean(ExtraAccountManager.EXTRA_DISABLE_BACK_KEY, false);
        bundle.putBoolean(ExtraAccountManager.EXTRA_FIND_PASSWORD_ON_PC, true);
        bundle.putBoolean(ExtraAccountManager.EXTRA_ADD_ACCOUNT_FROM_PROVISION, true);
        bundle.putString(AccountManager.KEY_ANDROID_PACKAGE_NAME, 
                        context.getPackageName());
        accountIntent.putExtras(bundle);
        
        return accountIntent;
    }
    
    @Override
    public boolean isAvailable(boolean toNext) {
        if (!super.isAvailable(toNext)) {
            return false;
        }
        // 仅国内版、非Provision状态、网络可用、未登录时显示
        return !Build.IS_INTERNATIONAL_BUILD
                && !Utils.isInProvisionState(context)
                && (Build.IS_PRIVATE_BUILD || 
                    NetworkUtils.isCaptivePortalValidated(context))
                && ExtraAccountManager.getXiaomiAccount(context) == null;
    }
}
```

### 5.3 FontSizeState - 字体大小

```java:1748:1759:src/com/android/provision/activities/DefaultActivity.java
public static class FontSizeState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        return !Build.IS_INTERNATIONAL_BUILD;  // 仅国内版显示
    }
    
    @Override
    public void onLeave() {
        super.onLeave();
        // 离开时应用字体大小设置
        FontSizeUtils.sendUiModeChangeMessage(context);
    }
}
```

---

## 6. 生命周期管理

### 6.1 onCreate

```java:176:240:src/com/android/provision/activities/DefaultActivity.java
@Override
protected void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    Log.d(TAG, "DefaultActivity onCreate");

    // 1. 检查是否已完成引导
    if (deviceIsProvisioned()) {
        finishSetup(false);
        return;
    }
    
    // 2. 折叠屏特殊处理
    if (Utils.isFlipDevice()) {
        Utils.disableScreenshots(this);  // 禁止截屏
        Intent coverFlipIntent = new Intent(this, CoverScreenService.class);
        startService(coverFlipIntent);
    }
    
    // 3. 注册页面拦截器
    PageIntercepHelper.getInstance().register();
    PageIntercepHelper.getInstance().setCallback(this::onActivityResult);
    
    // 4. Trustonic支持
    if (MccHelper.getInstance().isSupportTrustonic(
            ProvisionApplication.getContext())) {
        UserManagerHelper.getInstance().disableUserSpace(true);
    }
    
    // 5. Dock状态禁用
    MiuiDockUtils.disableInitDockStatus(this.getApplication());
    
    // 6. 发送开始广播
    START_TIME = System.currentTimeMillis();
    Utils.sendBroadcastAsUser(this, 
        new Intent(PROVISION_START_BROADCAST));
    
    // 7. 创建并启动状态机
    mStateMachine = new StateMachine(this);
    boolean enterCurrent = (icicle == null || 
        icicle.getBoolean(STATE_ENTER_CURRENTSTATE, true));
    mStateMachine.start(enterCurrent);
    
    // 8. 启动异常监控服务
    Intent abnormalBackService = new Intent(this, AbnormalBackService.class);
    startService(abnormalBackService);
    
    // 9. 注册网络监听
    registerNetworkChangedReceiver();
}
```

### 6.2 onActivityResult

```java:460:510:src/com/android/provision/activities/DefaultActivity.java
@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    Log.d(TAG, "onActivityResult requestCode=" + requestCode + 
               ", resultCode=" + resultCode);
    
    // 处理企业激活NFC
    if (requestCode == ENTERPRISE_PROVISIONING_REQUEST_CODE) {
        handleEnterpriseProvisioningResult(resultCode);
        return;
    }
    
    // 处理推荐应用结果
    if (requestCode == RecommendedState.AURA_PRIMARY_FLOW_REQUEST_CODE) {
        onAuraActivityResult(requestCode, resultCode);
        return;
    }
    
    // 处理MI换机结果
    if (requestCode == NEXT_REQUEST_CODE) {
        handleMiMoverResult(resultCode, data);
        return;
    }
    
    // 正常状态流转处理
    mStateMachine.onResult(resultCode, data);
    if (data != null) {
        mStateMachine.setBootVideoSkiped(
            data.getBooleanExtra(
                BootVideoFragment.EXTRA_BOOTVIDEO_FORCE_SKIPED, false
            )
        );
    }
    
    // 驱动状态机继续运行
    mStateMachine.run(resultCode);
}
```

### 6.3 onDestroy

```java:570:600:src/com/android/provision/activities/DefaultActivity.java
@Override
protected void onDestroy() {
    super.onDestroy();
    unRegisterNetworkChangedReceiver();
    unRegisterBluetoothReceiver();
    Utils.FINGER_PRINT_POINT = null;
    OTHelper.releaseOTA();
    stopTimeAnimation();
    mHandler.removeCallbacksAndMessages(null);
    PageIntercepHelper.getInstance().unregister();
}
```

---

## 7. 特殊功能模块

### 7.1 网络监听

```java:602:638:src/com/android/provision/activities/DefaultActivity.java
private void registerNetworkChangedReceiver() {
    if (Build.IS_INTERNATIONAL_BUILD && !mIsNetworkRegistered) {
        mIsNetworkRegistered = true;
        mNetorkReceiver = new NetWorkChangedReceiver();
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        registerReceiver(mNetorkReceiver, intentFilter);
    }
}
```

**用途**：国际版在引导过程中监听网络状态变化，用于条件判断（如账号登录需要网络）

### 7.2 快速启动检测

```java:265:300:src/com/android/provision/activities/DefaultActivity.java
private void checkQuickStartBoot() {
    // 检测是否从快速启动模式启动
    Intent miConnectServiceIntent = new Intent(
        "com.android.provision.MIUI_MICONNECT_DATA_SERVICE"
    );
    miConnectServiceIntent.setClass(this, MiConnectServer.class);
    
    MiConnectServer miConnectServer = new MiConnectServer();
    int quickStartCode = miConnectServer.getQuickStartCode();
    
    // 快速启动码处理逻辑
    if (quickStartCode == Utils.SKIP_ALL_PROVISION_PAGES_AND_SET_PROVISION_FLAG) {
        // 跳过所有引导页
        finishProvisionFlow();
    } else if (quickStartCode == Utils.SKIP_STARTUP_PAGE) {
        // 仅跳过启动页
        mStateMachine.run(Activity.RESULT_OK);
    }
}
```

### 7.3 预加载优化

```java:1974:1975:src/com/android/provision/activities/DefaultActivity.java
PreLoadManager.get().setCompleteDefaultActivityLoad();
```

**PreLoadManager职能**：
- 预加载下一个页面的Activity类和资源
- 提前初始化重量级组件（如账号服务、云服务）
- 减少页面切换时的等待时间

---

## 8. 与GlobalDefaultActivity的关系

### 8.1 职能划分

| 特性 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|----------------------|
| 适用版本 | 国内版 + 国际版旧OOBE | 国际版新OOBE |
| 启动时机 | 开机第一阶段 | GMS引导中间阶段 |
| Intent Action | `com.android.provision.global.STARTUP` | `com.android.provision.global.SECOND` |
| 流程范围 | 语言、输入法、网络、基础设置 | 账号、云服务、个性化设置 |
| 完成后 | 国内版完成/国际版返回GMS | 跳转到OemPostActivity |

### 8.2 协作流程（国际版新OOBE）

```
开机
  ↓
GMS SetupWizard
  ↓ (action: com.android.provision.global.STARTUP)
  ↓
DefaultActivity (第一阶段)
  ├─ 语言选择
  ├─ 输入法选择
  ├─ WiFi连接
  └─ 条款同意
  ↓ (返回GMS)
  ↓
GMS继续流程
  ├─ Google账号登录
  ├─ Google服务设置
  └─ 数据恢复
  ↓ (action: com.android.provision.global.SECOND)
  ↓
GlobalDefaultActivity (第二阶段)
  ├─ 小米账号
  ├─ 云服务
  ├─ 查找设备
  ├─ 指纹录入
  ├─ 字体设置
  └─ 个性化配置
  ↓ (action: com.android.setupwizard.OEM_POST_SETUP)
  ↓
OemPostActivity (完成清理)
  ↓
进入系统
```

---

## 9. 性能优化要点

### 9.1 状态持久化

- 使用SharedPreferences保存状态机当前位置
- 支持异常重启恢复（如系统崩溃、内存不足被杀）
- 恢复时检查状态可用性，自动跳过不可用状态

### 9.2 资源预加载

- PreLoadManager提前加载下一个Activity类
- WiFi连接页面预加载账号服务
- 账号登录后预加载云服务组件

### 9.3 动画优化

- 自定义页面切换动画（slide_in/slide_out）
- 首页特殊动画处理（LanguageAnimTool）
- 启动页Lottie动画延迟加载

---

## 10. 安全与隐私

### 10.1 敏感信息保护

```java:185:190:src/com/android/provision/activities/DefaultActivity.java
if (Utils.isFlipDevice()) {
    // 禁止页面截屏（防止敏感信息泄露）
    Utils.disableScreenshots(this);
}
```

### 10.2 权限控制

- Activity声明`android:exported="true"`但通过Intent Action限制调用方
- 使用`signatureOrSystem`权限保护关键广播
- SharedPreferences使用`MODE_PRIVATE`模式

---

## 11. 总结

### 核心特性

1. **状态机驱动**：灵活管理复杂多步骤流程，支持条件跳过和返回
2. **版本兼容**：同时支持国内版和国际版旧OOBE流程
3. **可扩展性**：通过State子类化轻松添加新引导页
4. **容错恢复**：状态持久化保证异常情况下可恢复
5. **性能优化**：预加载和动画优化提升用户体验

### 设计模式

- **状态模式（State Pattern）**：封装页面状态和流转逻辑
- **责任链模式（Chain of Responsibility）**：状态按链式顺序处理
- **模板方法模式（Template Method）**：State基类定义生命周期框架
- **策略模式（Strategy Pattern）**：不同State实现不同的isAvailable策略

### 改进建议

1. 状态流转逻辑过于复杂，可考虑使用DSL或配置文件定义流程
2. 状态类过多（30+），可按功能模块分包组织
3. 部分硬编码判断（如设备型号、运营商）可提取为配置
4. 增加更详细的埋点和日志，便于流程分析和问题定位

