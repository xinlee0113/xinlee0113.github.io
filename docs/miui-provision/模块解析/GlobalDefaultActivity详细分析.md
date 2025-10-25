---
layout: default
title: GlobalDefaultActivity 详细分析
parent: 模块解析
---



# GlobalDefaultActivity 详细分析

## 1. 概述

### 1.1 定义与定位

```java:66:68:src/com/android/provision/global/GlobalDefaultActivity.java
public class GlobalDefaultActivity extends AppCompatActivity {
    private static final String TAG = "GlobalDefaultActivity";
    private static final String PREF_STATE_GLOBAL = "pref_state_global";
}
```

**核心职能**：
- MIUI开机引导的**第二阶段（Secondary Stage）**主控制器
- 负责**国际版新OOBE（Out of Box Experience）流程**
- 处理**GMS引导之后**的MIUI个性化配置
- 通过状态机管理账号、云服务、指纹、字体、个性化等高级功能

### 1.2 适用场景

| 场景 | 适用版本 | 触发时机 |
|------|---------|---------|
| 国际版新OOBE | Global Build (新架构) | GMS完成基础配置后 |
| GMS集成流程 | 与GMS SetupWizard协作 | 中间阶段插入MIUI流程 |

### 1.3 与DefaultActivity对比

| 维度 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|---------------------|
| **启动Action** | `com.android.provision.global.STARTUP` | `com.android.provision.global.SECOND` |
| **流程阶段** | 第一阶段（Primary） | 第二阶段（Secondary） |
| **主要内容** | 基础配置（语言、输入法、网络） | 高级功能（账号、云服务、个性化） |
| **父类** | ProvisionBaseActivity | AppCompatActivity |
| **版本适用** | 国内版 + 国际版旧OOBE | 国际版新OOBE |
| **状态持久化Key** | `Utils.PREF_STATE` | `PREF_STATE_GLOBAL` |

---

## 2. 启动方式与入口

### 2.1 Intent Filter注册

```xml:276:285:global/AndroidManifest.xml
<activity android:name=".global.GlobalDefaultActivity"
          android:excludeFromRecents="true"
          android:screenOrientation="portrait"
          android:exported="true"
          android:configChanges="mcc|mnc|keyboardHidden|locale|layoutDirection|fontScale">
    <intent-filter>
        <action android:name="com.android.provision.global.SECOND" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</activity>
```

### 2.2 GMS Wizard Script触发

```xml:293:297:res_gte_v34/raw/wizard_script.xml
<WizardAction
    id="miui_second"
    wizard:uri="intent:#Intent;action=com.android.provision.global.SECOND;end">
    <result wizard:action="oem_post_setup"/>
</WizardAction>
```

### 2.3 完整流程时序

```
GMS SetupWizard启动
  ↓
first_setup_flow (DefaultActivity)
  ├─ 语言、输入法、WiFi、条款
  └─ 返回GMS
  ↓
GMS继续流程
  ├─ Google账号
  ├─ Google服务
  ├─ 数据恢复 (unified_restore_flow)
  └─ 其他GMS流程
  ↓
miui_second (GlobalDefaultActivity)  ← 当前Activity
  ├─ 小米账号
  ├─ 云服务设置
  ├─ 查找设备
  ├─ 云备份还原
  ├─ 指纹录入
  ├─ 其他设置
  ├─ 家长控制
  ├─ 字体设置
  ├─ 轮播图
  ├─ 位置信息
  ├─ 桌面设置
  ├─ 主题选择
  ├─ 推荐应用
  ├─ 开机视频
  ├─ 手势教程
  ├─ 导航模式
  ├─ 最近任务样式
  └─ 完成页面
  ↓
oem_post_setup (OemPostActivity)
  ├─ 应用所有设置
  ├─ 发送完成广播
  └─ 清理临时状态
  ↓
进入系统桌面
```

---

## 3. 核心架构：状态机模式

### 3.1 状态机设计

```java:701:733:src/com/android/provision/global/GlobalDefaultActivity.java
public static class StateMachine {
    
    private Context mContext;
    private SparseArray<StateInfo> mStates;    // 所有状态映射表
    private State mCurrentState;                // 当前状态
    private State mCompleteState;               // 完成状态
    private ArrayList<State> mStateStack;       // 状态栈（支持返回）
    
    // 特殊状态引用（用于跨状态通信）
    private State mAccountState;
    private CloudServiceState mCloudServiceState;
    private FindDeviceState mFindDeviceState;
    private BootVideoState mBootVideoState;
    
    private class StateInfo {
        private State current;
        private State next;
        
        public StateInfo(State current) {
            this.current = current;
        }
    }
    
    public StateMachine(Context context) {
        mContext = context;
        init();  // 初始化所有状态和流转关系
    }
}
```

### 3.2 State基类设计（简化版）

```java:162:257:src/com/android/provision/global/GlobalDefaultActivity.java
public static class State {
    
    public static final String PREFIX = "com.android.provision.global.GlobalDefaultActivity$";
    
    protected StateMachine mStateMachine;
    protected Context context;
    protected String packageName;    // 外部Activity包名
    public String className;         // 外部Activity类名
    public Class<?> targetClass;     // 内部Activity类引用
    protected Handler mHandler = new Handler();
    
    // 创建State实例（反射）
    public static State create(String name) {
        State state;
        try {
            state = (State) Class.forName(PREFIX + name).newInstance();
        } catch (Exception e) {
            e.printStackTrace();
            state = null;
        }
        return state;
    }
    
    // Builder模式设置属性
    public State setPackageName(String packageName) {
        this.packageName = packageName;
        return this;
    }
    
    public State setClassName(String className) {
        this.className = className;
        return this;
    }
    
    public State setTargetClass(Class<?> targetClass) {
        this.targetClass = targetClass;
        return this;
    }
    
    // 生命周期方法
    public void onEnter(boolean canGoBack, boolean toNext) {
        Activity defaultActivity = (Activity) context;
        Intent i = getIntent();
        i.putExtra(BaseActivity.EXTRA_DISABLE_BACK, !canGoBack);
        i.putExtra(BaseActivity.EXTRA_TO_NEXT, toNext);
        defaultActivity.startActivityForResult(i, 0);
    }
    
    public void onLeave() {
        // 子类可重写执行清理或应用设置
    }
    
    // 可用性判断
    public boolean isAvailable(boolean toNext) {
        return context.getPackageManager().resolveActivity(getIntent(), 0) != null;
    }
    
    // 导航控制
    public State getNextState() {
        return null;
    }
    
    protected boolean canBackTo() {
        return true;
    }
    
    // Intent构建
    protected Intent getIntent() {
        Intent intent = new Intent();
        if (TextUtils.isEmpty(packageName)) {
            intent.setClass(context, targetClass);
        } else {
            intent.setClassName(packageName, className);
        }
        return intent;
    }
}
```

**设计亮点**：
1. 使用反射动态创建State实例（支持灵活扩展）
2. Builder模式设置State属性（链式调用）
3. 支持内部Activity（targetClass）和外部Activity（packageName + className）
4. 统一的生命周期管理（onEnter/onLeave）

### 3.3 状态流转机制

#### 核心方法

```java:755:769:src/com/android/provision/global/GlobalDefaultActivity.java
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

```java:810:843:src/com/android/provision/global/GlobalDefaultActivity.java
private void transitToNext() {
    Log.d(TAG, "transitToNext mCurrentState is " + mCurrentState);
    mCurrentState.onLeave();  // 离开当前状态（可能应用设置）
    
    // 到达完成状态，结束引导
    if (mCurrentState == mCompleteState) {
        Activity activity = (Activity) mContext;
        
        // Trustonic支持
        if (MccHelper.getInstance().isSupportTrustonic(activity) || 
            MccHelper.getInstance().isSupportCustomizedTrustonic(activity)) {
            Utils.goToTrustonicApp((Activity) mContext, activity.getIntent());
        } else {
            Utils.goToNextPage((Activity) mContext, activity.getIntent(), 
                              Activity.RESULT_OK);
        }
        
        // 设置POCO launcher为默认桌面
        if (Utils.applicationInstalled(activity, DefaultHomeUtils.MIUI_HOME_PACKAGE_NAME)
                && Utils.applicationInstalled(activity, DefaultHomeUtils.POCO_LAUNCHER_PACKAGE_NAME)) {
            DefaultHomeUtils.setDefaultHome(activity, DefaultHomeUtils.MIUI_HOME_PACKAGE_NAME);
        }
        
        // Claro卸载Siprogo
        RemoveSiprogoManager.checkIsRemoveSiprogo((Activity) mContext);
        
        clearState(PREF_STATE_GLOBAL);
        clearState(Utils.PREF_STATE);
        activity.finish();
        return;
    }
    
    // 压入状态栈
    mStateStack.add(mCurrentState);
    State preState = mCurrentState;
    
    // 获取下一个可用状态
    mCurrentState = getNextAvailableState(mCurrentState);
    
    // 进入新状态
    if (mCurrentState instanceof RecommendedState) {
        ((RecommendedState) mCurrentState).display(mContext, RecommendedState.PRE_PAGE);
    } else {
        mCurrentState.onEnter(preState.canBackTo(), true);
    }
    
    // 设置页面切换动画
    ((Activity) mContext).overridePendingTransition(
        R.anim.slide_in_right, 
        R.anim.slide_out_left
    );
    
    saveState();
}
```

#### getNextAvailableState() - 智能跳过不可用状态

```java:771:782:src/com/android/provision/global/GlobalDefaultActivity.java
private State getNextAvailableState(State current) {
    State next = current;
    do {
        current = next;
        next = current.getNextState();  // 先尝试State自定义的next
        if (next == null) {
            next = getStateInfo(current).next;  // 否则使用状态机配置的next
        }
    } while (!next.isAvailable(true));  // 循环直到找到可用状态
    
    Log.d(TAG, "getNextAvailableState is " + next);
    return next;
}
```

**智能跳过机制**：
- 每个State都有`isAvailable()`方法判断当前是否可用
- 不可用的原因可能是：
  - 功能未安装（如云服务、主题管理器）
  - 条件不满足（如网络不可用、账号已登录）
  - 配置禁用（如企业版禁用某些功能）
- 自动跳过不可用状态，用户无感知

---

## 4. 完整状态流程

### 4.1 状态初始化代码

```java:889:1005:src/com/android/provision/global/GlobalDefaultActivity.java
private void init() {
    mStates = new SparseArray<StateInfo>();
    mStateStack = new ArrayList<State>();

    // 1. 账号相关状态
    State accountState = State.create("AccountState");
    State cloudServiceState = State.create("CloudServiceState")
            .setPackageName("com.miui.cloudservice")
            .setClassName("com.miui.cloudservice.ui.ProvisionSettingActivity");
    State findDeviceState = State.create("FindDeviceState")
            .setPackageName("com.miui.cloudservice")
            .setClassName("com.miui.cloudservice.ui.FindDeviceSettingsActivity");
    State cloudBackupState = State.create("CloudBackupState")
            .setPackageName("com.miui.cloudbackup")
            .setClassName("com.miui.cloudbackup.ui.ProvisionRestoreActivity");

    // 2. 安全相关状态
    State fingerprintState = State.create("FingerprintState")
        .setTargetClass(FingerprintActivity.class);
    
    // 3. 设置相关状态
    State otherState = State.create("OtherState")
        .setTargetClass(OtherSettingsActivity.class);
    State parentalControlState = ParentalControlState.create();
    
    // 4. 个性化相关状态
    State fontState = State.create("FontState")
        .setTargetClass(FontStyleActivity.class);
    State carouselState = State.create("CarouselState")
        .setTargetClass(CarouselSettingActivity.class);
    State locationInState = State.create("LocationInState")
        .setTargetClass(LocationInformationActivity.class);
    State homeState = State.create("HomeSettingsState")
        .setTargetClass(HomeSettingsActivity.class);
    State themePickerState = State.create("ThemePickerState")
            .setPackageName("com.android.thememanager")
            .setClassName("com.android.thememanager.activity.ThemeProvisionActivity");
    State recommendedState = State.create("RecommendedState")
        .setTargetClass(GlobalDefaultActivity.class);
    State bootVideoState = State.create("BootVideoState")
        .setTargetClass(BootVideoActivity.class);
    
    // 5. UI相关状态
    State navigationModePickerState = State.create("NavigationModePickerState")
        .setTargetClass(NavigationModePickerActivity.class);
    State recentTaskStyleState = State.create("RecentTaskStyleState")
        .setTargetClass(RecentTaskStyleActivity.class);
    State kindtipState = State.create("KindTipState")
        .setTargetClass(KindTipActivity.class);
    State gestureTutorialState = State.create("GestureTutorialState")
            .setPackageName("com.miui.home")
            .setClassName("com.miui.home.recents.settings.GestureTutorialProvisionActivity");
    
    // 6. 完成状态
    State congratulationState = State.create("CongratulationState")
        .setTargetClass(CongratulationActivity.class);

    // 构建状态流转链
    addState(accountState);
    setNextState(accountState, cloudServiceState);
    
    addState(cloudServiceState);
    setNextState(cloudServiceState, findDeviceState);
    
    addState(findDeviceState);
    setNextState(findDeviceState, cloudBackupState);
    
    addState(cloudBackupState);
    setNextState(cloudBackupState, fingerprintState);
    
    addState(fingerprintState);
    setNextState(fingerprintState, otherState);
    
    addState(otherState);
    setNextState(otherState, parentalControlState);
    
    addState(parentalControlState);
    setNextState(parentalControlState, fontState);
    
    addState(fontState);
    setNextState(fontState, carouselState);
    
    addState(carouselState);
    setNextState(carouselState, locationInState);
    
    addState(locationInState);
    setNextState(locationInState, homeState);
    
    addState(homeState);
    setNextState(homeState, themePickerState);
    
    addState(themePickerState);
    setNextState(themePickerState, recommendedState);
    
    addState(recommendedState);
    setNextState(recommendedState, bootVideoState);
    
    addState(bootVideoState);
    setNextState(bootVideoState, gestureTutorialState);
    
    addState(gestureTutorialState);
    setNextState(gestureTutorialState, navigationModePickerState);
    
    addState(navigationModePickerState);
    setNextState(navigationModePickerState, recentTaskStyleState);
    
    addState(recentTaskStyleState);
    if (Utils.isFlipDevice()) {
        setNextState(recentTaskStyleState, kindtipState);
        addState(kindtipState);
        setNextState(kindtipState, congratulationState);
    } else {
        setNextState(recentTaskStyleState, congratulationState);
    }
    
    addState(congratulationState);
    
    // 设置起始和结束状态
    mCompleteState = congratulationState;
    mCurrentState = accountState;
    mAccountState = accountState;
    mCloudServiceState = (CloudServiceState) cloudServiceState;
    mFindDeviceState = (FindDeviceState) findDeviceState;
    mBootVideoState = (BootVideoState) bootVideoState;
}
```

### 4.2 完整流程图

```
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
│ParentalControlState│  家长控制
└──────┬──────┘
       ↓
┌─────────────┐
│  FontState   │  字体设置（MiSans/Roboto）
└──────┬──────┘
       ↓
┌─────────────┐
│CarouselState │  轮播推荐
└──────┬──────┘
       ↓
┌─────────────┐
│LocationInState│  位置信息权限
└──────┬──────┘
       ↓
┌─────────────┐
│ HomeSettingsState│  桌面布局设置
└──────┬──────┘
       ↓
┌─────────────┐
│ThemePickerState│  主题选择（已废弃）
└──────┬──────┘
       ↓
┌─────────────┐
│RecommendedState│  应用推荐（Aura/GetApps）
└──────┬──────┘
       ↓
┌─────────────┐
│BootVideoState │  开机视频
└──────┬──────┘
       ↓
┌─────────────┐
│GestureTutorialState│  手势教程
└──────┬──────┘
       ↓
┌─────────────┐
│NavigationModePickerState│  导航模式选择
└──────┬──────┘
       ↓
┌─────────────┐
│RecentTaskStyleState│  最近任务样式
└──────┬──────┘
       ↓
┌─────────────┐
│ KindTipState │  温馨提示（折叠屏）
└──────┬──────┘
       ↓
┌─────────────┐
│CongratulationState│  完成页面
└─────────────┘
```

---

## 5. 关键State实现分析

### 5.1 AccountState - 账号登录

```java:259:294:src/com/android/provision/global/GlobalDefaultActivity.java
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
        // 仅在以下条件全部满足时显示：
        // 1. 非国际版
        // 2. 非Provision工作状态
        // 3. 网络可用或开发版
        // 4. 未登录小米账号
        return !Build.IS_INTERNATIONAL_BUILD
                && !Utils.isInProvisionState(context)
                && (Build.IS_PRIVATE_BUILD || 
                    NetworkUtils.isCaptivePortalValidated(context))
                && ExtraAccountManager.getXiaomiAccount(context) == null;
    }
}
```

### 5.2 CloudServiceState - 云服务

```java:296:327:src/com/android/provision/global/GlobalDefaultActivity.java
public static class CloudServiceState extends State {
    
    private long mMasterKeyVersion = -1;
    private boolean mCanInstall = false;
    
    @Override
    protected Intent getIntent() {
        Intent cloudServiceIntent = super.getIntent();
        cloudServiceIntent.putExtra(INTENT_KEY_VERSION, mMasterKeyVersion);
        cloudServiceIntent.putExtra(INTENT_KEY_CAN_INSTALL, mCanInstall);
        return cloudServiceIntent;
    }
    
    @Override
    public boolean isAvailable(boolean toNext) {
        return !Build.IS_INTERNATIONAL_BUILD &&
                super.isAvailable(toNext) &&
                !Utils.isInProvisionState(context) &&
                ExtraAccountManager.getXiaomiAccount(context) != null &&  // 已登录
                Settings.Global.getInt(context.getContentResolver(), 
                    "provision_cloudService_enabled", 0) == 0 &&
                !Utils.isRedmiDigitOrNoteSeries();  // 排除红米数字系列/Note系列
    }
    
    // 接收AccountState的登录结果
    public void onLoginResult(int resultCode, Intent data) {
        if (data != null) {
            mMasterKeyVersion = data.getLongExtra(INTENT_KEY_VERSION, -1);
            mCanInstall = data.getBooleanExtra(INTENT_KEY_CAN_INSTALL, false);
        }
    }
}
```

### 5.3 FontState - 字体设置

```java:520:526:src/com/android/provision/global/GlobalDefaultActivity.java
public static class FontState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        Log.i(TAG, " here is FontState isAvailable func ");
        return Utils.isMiSansSupportLanguages() &&      // 支持MiSans的语言
               FontStyleFragment.getFontList(context).size() == 2 &&  // 有2种字体可选
               !Utils.isFoldDevice() &&                  // 非折叠屏
               !Utils.isInProvisionState(context);       // 非Provision工作状态
    }
}
```

### 5.4 CongratulationState - 完成状态（应用所有设置）

```java:547:567:src/com/android/provision/global/GlobalDefaultActivity.java
public static class CongratulationState extends State {
    @Override
    public void onLeave() {
        super.onLeave();
        
        // 1. 应用字体设置
        if (Build.IS_INTERNATIONAL_BUILD && 
            FontStyleUtils.DEFAULT_FONT_ID.equalsIgnoreCase(
                FontStyleUtils.getLocalFontId(context))) {
            FontStyleUtils.applyFont(context, FontStyleUtils.DEFAULT_FONT_ID);
        } else {
            FontStyleUtils.applyFont(context, FontStyleUtils.MISANS_FONT_ID);
        }
        
        // 2. 应用导航栏全屏设置
        if (Utils.isTabletDevice()) {
            Utils.setNavigationBarFullScreen(context, true);
        } else {
            Utils.setNavigationBarFullScreen(context, 
                DefaultPreferenceHelper.isPrefFullscreen());
        }
        
        // 3. 显示手势线
        if (context != null && !Utils.isGestureLineShow(context)) {
            Utils.hideGestureLine(context, false);
        }
    }
}
```

**关键机制**：
- 完成页面的`onLeave()`是应用所有设置的最佳时机
- 此时用户已完成所有选择，即将进入系统
- 统一应用避免中间过程频繁重启应用

### 5.5 RecommendedState - 应用推荐

```java:610:699:src/com/android/provision/global/GlobalDefaultActivity.java
public static class RecommendedState extends State {
    public static final String AURA_PACKAGE_NAME = "com.aura.oobe.xiaomi";
    public static final String MI_APPS_ACTION = "com.xiaomi.market.FirstRecommend";
    
    public static final int OPERATION_START_IRONSOURCE = 1;
    private static final int OPERATION_START_MI_APPS = 2;
    
    private int mOperation = REQUEST_EXCEPTION;
    
    @Override
    public boolean isAvailable(boolean toNext) {
        if (!super.isAvailable(toNext) || 
            !Utils.isGlobalBuild() || 
            Utils.isGoogleCoopeModels()) {
            return false;
        }
        
        if (Utils.isInProvisionState(context)) {
            return false;
        }
        
        // 印度地区支持Indus AppStore
        if (miAppsAvailable(context) && 
            Utils.isSupportIndusApps(context, GET_APPS_PKG_NAME) && 
            !Utils.isOobeDisabledExplicitly) {
            mOperation = OPERATION_START_MI_APPS;
            return true;
        }
        
        mOperation = DefaultPreferenceHelper.getRecommendedOperation();
        if (REQUEST_EXCEPTION != mOperation && 
            OPERATION_NONE != mOperation && 
            NetworkUtils.isCaptivePortalValidated(context)) {
            switch (mOperation) {
                case OPERATION_START_IRONSOURCE:
                    return ironsourceAvailable(context);
                case OPERATION_START_MI_APPS:
                    return miAppsAvailable(context);
            }
        }
        return false;
    }
    
    private void display(Context context, String jumpWay) {
        switch (mOperation) {
            case OPERATION_START_IRONSOURCE:
                // 启动Aura应用推荐
                AuraMediator.getInstance().startPrimaryFlowActivityForResult(
                    (GlobalDefaultActivity) context
                );
                break;
            case OPERATION_START_MI_APPS:
                // 启动GetApps应用推荐
                mMiAppsIntent.putExtra("startFrom", jumpWay);
                ((GlobalDefaultActivity) context).startActivityForResult(
                    mMiAppsIntent, MI_APPS_REQUEST_CODE
                );
                break;
        }
    }
}
```

**商业逻辑**：
- 根据地区和合作伙伴显示不同的应用推荐
- Aura（IronSource）：全球大部分地区
- GetApps（小米应用商店）：印度等特定地区
- 通过`DefaultPreferenceHelper.getRecommendedOperation()`获取配置

---

## 6. 生命周期管理

### 6.1 onCreate

```java:82:90:src/com/android/provision/global/GlobalDefaultActivity.java
@Override
protected void onCreate(Bundle icicle) {
    super.onCreate(icicle);
    
    // 创建状态机
    mStateMachine = new StateMachine(this);
    
    // 是否进入当前状态（用于恢复场景）
    boolean enterCurrent = (icicle == null || 
        icicle.getBoolean(STATE_ENTER_CURRENTSTATE, true));
    
    // 启动状态机
    mStateMachine.start(enterCurrent);
    
    // 注册网络监听
    registerNetworkChangedReceiver();
}
```

### 6.2 onStart

```java:92:98:src/com/android/provision/global/GlobalDefaultActivity.java
@Override
protected void onStart() {
    super.onStart();
    
    // 获取企业版Provision状态
    DevicePolicyManager dpm = getSystemService(DevicePolicyManager.class);
    sUserProvisioningState = dpm.getUserProvisioningState();
    Log.i(TAG, "GlobalDefaultActivity getUserProvisioningState=" + 
              sUserProvisioningState);
}
```

### 6.3 onSaveInstanceState

```java:100:104:src/com/android/provision/global/GlobalDefaultActivity.java
@Override
protected void onSaveInstanceState(Bundle outState) {
    super.onSaveInstanceState(outState);
    
    // 保存是否需要进入当前状态（用于Activity重建）
    outState.putBoolean(STATE_ENTER_CURRENTSTATE, 
        mStateMachine.mCurrentState instanceof AccountState);
}
```

### 6.4 onActivityResult

```java:133:145:src/com/android/provision/global/GlobalDefaultActivity.java
@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    Log.d(TAG, "onActivityResult requestCode=" + requestCode + 
               ", resultCode=" + resultCode);
    
    // 处理Aura推荐结果
    if (requestCode == RecommendedState.AURA_PRIMARY_FLOW_REQUEST_CODE) {
        onAuraActivityResult(requestCode, resultCode);
    } else {
        // 正常状态流转
        mStateMachine.onResult(resultCode, data);
        if (data != null) {
            mStateMachine.setBootVideoSkiped(
                data.getBooleanExtra(BootVideoFragment.EXTRA_BOOTVIDEO_FORCE_SKIPED, false)
            );
        }
        mStateMachine.run(resultCode);
    }
}
```

### 6.5 onDestroy

```java:123:128:src/com/android/provision/global/GlobalDefaultActivity.java
@Override
protected void onDestroy() {
    super.onDestroy();
    unRegisterNetworkChangedReceiver();
}
```

---

## 7. 跨状态通信机制

### 7.1 问题背景

某些State需要获取前面State的结果，例如：
- `CloudServiceState`需要`AccountState`的登录信息
- `FindDeviceState`需要知道用户是否使用密码登录

### 7.2 实现方案

```java:748:753:src/com/android/provision/global/GlobalDefaultActivity.java
public void onResult(int resultCode, Intent data) {
    // 如果当前是AccountState，将结果传递给后续状态
    if (mCurrentState == mAccountState) {
        mCloudServiceState.onLoginResult(resultCode, data);
        mFindDeviceState.onLoginResult(resultCode, data);
    }
}
```

```java:366:373:src/com/android/provision/global/GlobalDefaultActivity.java
// FindDeviceState接收登录结果
public void onLoginResult(int resultCode, Intent data) {
    if (data != null) {
        mPasswordLogin = data.getBooleanExtra("password_login", true);
    }
}
```

**设计模式：观察者模式变种**
- StateMachine作为中介者
- 特定State作为观察者接收其他State的结果
- 避免State之间直接耦合

---

## 8. 特殊功能模块

### 8.1 网络监听

```java:106:121:src/com/android/provision/global/GlobalDefaultActivity.java
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

**用途**：
- 部分功能需要网络（如云服务、应用推荐）
- 网络状态变化时重新评估State可用性
- 仅国际版注册（国内版在DefaultActivity中处理）

### 8.2 状态持久化

```java:1070:1115:src/com/android/provision/global/GlobalDefaultActivity.java
private void restoreState() {
    SharedPreferences preferences = mContext.getSharedPreferences(
        PREF_STATE_GLOBAL, 
        Context.MODE_PRIVATE
    );
    
    String state = AccountState.class.getSimpleName();
    if (getStateInfo(state) == null) {
        return;
    }
    
    mCurrentState = getStateInfo(state).current;
    
    // 恢复状态栈
    for (int i = 0; state != null; ++i) {
        state = preferences.getString(KEY_STATE_PREFIX + i, null);
        if (state != null) {
            if (i != 0) {
                mStateStack.add(mCurrentState);
            }
            if (getStateInfo(state) != null) {
                mCurrentState = getStateInfo(state).current;
            }
        }
    }
    
    // 检查当前状态是否仍然可用
    if (!mCurrentState.isAvailable(true)) {
        State tempState = getPreviousAvailableState(mStateStack);
        if (mCurrentState == tempState || tempState == null) {
            mCurrentState = getNextAvailableState(mCurrentState);
        }
    }
}

private void saveState() {
    SharedPreferences preferences = mContext.getSharedPreferences(
        PREF_STATE_GLOBAL, 
        Context.MODE_PRIVATE
    );
    Editor editor = preferences.edit();
    editor.clear();
    
    // 保存状态栈和当前状态
    for (int i = 0; i < mStateStack.size(); ++i) {
        editor.putString(KEY_STATE_PREFIX + i, 
            mStateStack.get(i).getClass().getSimpleName());
    }
    editor.putString(KEY_STATE_PREFIX + mStateStack.size(), 
        mCurrentState.getClass().getSimpleName());
    
    editor.apply();
}
```

**容错机制**：
- 恢复后检查当前状态是否仍然可用
- 不可用则尝试返回上一个可用状态
- 仍不可用则跳到下一个可用状态

---

## 9. 与OemPostActivity的衔接

### 9.1 完成流程

```java:813:831:src/com/android/provision/global/GlobalDefaultActivity.java
if (mCurrentState == mCompleteState) {
    Activity activity = (Activity) mContext;
    
    // Trustonic处理
    if (MccHelper.getInstance().isSupportTrustonic(activity) || 
        MccHelper.getInstance().isSupportCustomizedTrustonic(activity)) {
        Utils.goToNextPage((Activity) mContext, activity.getIntent(), 
                          Activity.RESULT_OK);
    } else {
        Utils.goToNextPage((Activity) mContext, activity.getIntent(), 
                          Activity.RESULT_OK);
    }
    
    // 清理状态
    clearState(PREF_STATE_GLOBAL);
    clearState(Utils.PREF_STATE);
    
    activity.finish();
    return;
}
```

### 9.2 Utils.goToNextPage()

该方法会根据Intent中的信息跳转到下一个Activity：
- 如果是GMS调用，返回`RESULT_OK`给GMS
- GMS根据wizard_script.xml配置跳转到`oem_post_setup`
- 最终启动`OemPostActivity`完成清理工作

---

## 10. 设计优势与不足

### 10.1 设计优势

1. **职责明确**
   - 只处理MIUI个性化配置，不涉及基础设置
   - 与GMS流程清晰分离

2. **灵活性高**
   - 通过`isAvailable()`动态调整流程
   - 支持不同地区、设备、配置的差异化流程

3. **可扩展性强**
   - 新增State只需创建子类并在init()中注册
   - 状态间松耦合，易于维护

4. **容错恢复**
   - 状态持久化支持异常恢复
   - 智能跳过不可用状态

5. **跨进程协作**
   - 支持启动外部App（云服务、主题管理器等）
   - Intent传参清晰规范

### 10.2 设计不足

1. **状态类过多**
   - 17个State类，代码量大
   - 建议按功能模块分包组织

2. **硬编码较多**
   - 包名、类名硬编码在代码中
   - 建议提取到配置文件或常量类

3. **状态机逻辑复杂**
   - getNextAvailableState循环查找逻辑不直观
   - 建议增加流程可视化工具

4. **缺少埋点和监控**
   - 状态流转缺少详细日志
   - 无法统计各State的通过率和耗时

5. **测试困难**
   - 状态机逻辑难以单元测试
   - 依赖大量外部Activity和服务

---

## 11. 总结

### 11.1 核心特性

1. **第二阶段引导**：处理GMS之后的MIUI个性化配置
2. **状态机驱动**：灵活管理复杂多步骤流程
3. **智能跳过**：根据条件自动跳过不可用页面
4. **跨进程协作**：支持启动外部应用完成配置
5. **容错恢复**：状态持久化保证异常情况下可恢复

### 11.2 与DefaultActivity对比总结

| 维度 | DefaultActivity | GlobalDefaultActivity |
|------|----------------|---------------------|
| **定位** | 第一阶段基础配置 | 第二阶段高级功能 |
| **复杂度** | 高（30+State） | 中（17State） |
| **外部依赖** | 少（主要是Settings） | 多（云服务、主题等） |
| **流程长度** | 长（基础到完整） | 中（个性化为主） |
| **容错要求** | 高（必须完成） | 中（可跳过部分） |

### 11.3 改进建议

1. **配置化流程定义**：使用JSON/XML定义状态流转，减少硬编码
2. **模块化拆分**：按功能模块（账号、个性化、UI）拆分State类
3. **增强监控**：添加埋点统计各State的通过率、耗时、跳过原因
4. **可视化工具**：开发流程编辑器，可视化配置状态流转
5. **单元测试**：抽取状态机核心逻辑，增加单元测试覆盖

