---
layout: default
title: 规则引擎 - State状态机设计分析
parent: 模块解析
---



# 规则引擎 - State状态机设计分析

## 📋 概述

MiuiProvision使用**状态机设计模式（State Pattern）**来管理开机引导流程中的各个页面显示规则。每个页面对应一个`State`对象，通过`isAvailable()`方法实现条件判断，系统会自动跳过不满足条件的页面。

---

## 🏗️ 核心架构

### 1. State基类设计

```java
// src/com/android/provision/global/State.java

public class State {
    protected Context context;
    protected Class<?> targetClass;  // 目标Activity类
    
    /**
     * 判断当前State是否可用
     * @param toNext true表示前进，false表示后退
     * @return true表示页面应该显示，false表示跳过此页面
     */
    public boolean isAvailable(boolean toNext) {
        return context.getPackageManager().resolveActivity(getIntent(), 0) != null;
    }
    
    public void onEnter(boolean canGoBack, boolean toNext) {
        // 进入页面时触发
    }
    
    public void onLeave() {
        // 离开页面时触发
    }
}
```

### 2. StateMachine状态机

```java
// src/com/android/provision/activities/DefaultActivity.java

public class StateMachine {
    private State mCurrentState;  // 当前状态
    private ArrayList<State> mStateStack;  // 状态栈（用于返回）
    private SparseArray<StateInfo> mStates;  // 所有状态信息
    
    /**
     * 获取下一个可用的State
     * 核心逻辑：循环查找直到找到isAvailable()返回true的State
     */
    private State getNextAvailableState(State current) {
        State next = current;
        do {
            current = next;
            next = current.getNextState();
            if (next == null) {
                next = getStateInfo(current).next;
            }
        } while (next != null && !next.isAvailable(true));  // ⭐关键：过滤不可用的State
        
        return next;
    }
    
    private void transitToNext() {
        State next = getNextAvailableState(mCurrentState);
        if (next != null) {
            mStateStack.add(mCurrentState);
            mCurrentState.onLeave();
            mCurrentState = next;
            mCurrentState.onEnter(true, true);
        }
    }
}
```

---

## 📊 规则配置示例分析

用户提供的JSON配置：

```json
{
  "font_state_rules": {
    "enabled": true,
    "conditions": [
      {"type": "feature", "key": "support_misans", "value": true},
      {"type": "device", "key": "is_fold", "value": false},
      {"type": "font_count", "value": 2}
    ],
    "logic": "AND"
  },
  "mimover_rules": {
    "enabled": true,
    "conditions": [
      {"type": "feature", "key": "support_mimover", "value": true},
      {"type": "build", "key": "is_international", "value": false}
    ],
    "logic": "AND"
  }
}
```

---

## 🔍 规则1: FontState（字体选择页面）

### 实现位置
```java
// src/com/android/provision/global/GlobalDefaultActivity.java:520-526

public static class FontState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        Log.i(TAG, " here is FontState isAvailable func ");
        return Utils.isMiSansSupportLanguages() 
            && FontStyleFragment.getFontList(context).size()==2 
            && !Utils.isFoldDevice() 
            && !Utils.isInProvisionState(context);
    }
}
```

### 规则映射

| JSON配置条件 | 代码实现 | 说明 |
|------------|---------|------|
| `support_misans: true` | `Utils.isMiSansSupportLanguages()` | 检查当前语言是否支持MiSans字体 |
| `is_fold: false` | `!Utils.isFoldDevice()` | 非折叠屏设备 |
| `font_count: 2` | `FontStyleFragment.getFontList(context).size()==2` | 字体列表数量为2（默认+MiSans） |
| `logic: "AND"` | 使用`&&`连接所有条件 | 所有条件必须同时满足 |

### 条件详细说明

#### 1️⃣ `isMiSansSupportLanguages()` - 支持MiSans字体的语言
```java
// src/com/android/provision/Utils.java:1968-1988

public static boolean isMiSansSupportLanguages(){
    LocaleList localeList = null;
    Locale systemLocale = Locale.getDefault();
    try {
        Class<?> multilangHelper = Class.forName("miui.util.font.MultiLangHelper");
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            // 反射调用MultiLangHelper.getSupportedLocaleList()
            localeList = (LocaleList)multilangHelper.getMethod("getSupportedLocaleList").invoke(null);
            if (localeList != null){
                for (int i = 0; i < localeList.size(); i++) {
                    if (localeList.get(i).equals(systemLocale)){
                        return true;  // 当前系统语言在支持列表中
                    }
                }
            }
        }
    }catch (Exception e){
        Log.e(TAG, " isMiSansSupportLanguages: ",e);
    }
    return false;
}
```

**判断逻辑**：
- 通过反射调用`miui.util.font.MultiLangHelper.getSupportedLocaleList()`
- 检查当前系统语言（`Locale.getDefault()`）是否在支持的语言列表中
- 支持的语言通常包括：中文、英文、西班牙语等（具体列表由系统定义）

#### 2️⃣ `isFoldDevice()` - 是否为折叠屏设备
```java
// src/com/android/provision/Utils.java:431-436

public static boolean isFoldDevice(){
    return "cetus".equalsIgnoreCase(Build.DEVICE)||
            "zizhan".equalsIgnoreCase(Build.DEVICE)||
            "babylon".equalsIgnoreCase(Build.DEVICE)||
            MiuiMultiDisplayTypeInfo.isFoldDevice();
}
```

**判断逻辑**：
- 硬编码检查特定设备代号：`cetus`、`zizhan`、`babylon`
- 调用MIUI系统API `MiuiMultiDisplayTypeInfo.isFoldDevice()`
- 折叠屏设备不显示字体选择页面（可能因为UI适配问题）

#### 3️⃣ `getFontList().size()==2` - 字体数量检查
```java
// src/com/android/provision/fragment/FontStyleFragment.java:376-386

public static List<LocalFontModel> getFontList(Context context) {
    List<LocalFontModel> ret = new ArrayList<>();
    try {
        Bundle bundle = context.getContentResolver().call(
            Uri.parse("content://com.android.thememanager.theme_provider"), 
            "getLocalFonts",  // 调用主题管理器的Content Provider
            null, 
            null
        );
        if (bundle == null) return ret;
        String resultJson = bundle.getString("result");
        ret = getFontsResult(resultJson);  // 解析JSON返回的字体列表
    }catch (Exception e){
        // ...
    }
    return ret;
}
```

**判断逻辑**：
- 调用主题管理器（ThemeManager）的Content Provider
- 获取本地字体列表
- 只有当字体数量为2时才显示（通常是默认字体+MiSans）
- 如果字体数量≠2，说明系统状态异常或已安装其他字体，跳过此页面

### 应用场景

**✅ 显示字体选择页面的条件：**
- 系统语言支持MiSans字体（如中文、英文等）
- 非折叠屏设备
- 字体列表数量恰好为2个（默认字体 + MiSans）
- 不在Provision状态中（`!Utils.isInProvisionState(context)`）

**❌ 跳过字体选择页面的情况：**
- 系统语言不支持MiSans（如某些小语种）
- 折叠屏设备（UI适配考虑）
- 字体列表数量异常（≠2）
- 国际版设备可能限制字体功能

**典型用户场景：**
1. 用户首次开机，选择中文语言
2. 系统检测到支持MiSans，且设备为非折叠屏
3. 显示字体选择页面，提供"默认字体（Roboto）"和"推荐字体（MiSans）"两个选项
4. 用户选择MiSans后，系统应用全局字体设置

---

## 🔍 规则2: MiMoverState（换机功能页面）

### 实现位置
```java
// src/com/android/provision/activities/DefaultActivity.java:1353-1375

public static class MiMoverState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        if (!super.isAvailable(toNext) || !Utils.supportMiMover(context)) {
            return false;
        }
        Log.d(TAG, "MiConnectServer destroyed");
        MiConnectServer.getInstance().destroy();
        return !checkHuanjiFinish(context);
    }
}
```

```java
// src/com/android/provision/Utils.java:1675-1690

public static boolean supportMiMover(Context context) {
    // 1. 企业模式限制检查
    if (miui.enterprise.RestrictionsHelperStub.getInstance().isRestriction(
            miui.enterprise.RestrictionsHelperStub.DISALLOW_MIMOVER)) {
        Log.d(TAG,"Device is in enterprise mode, MiMover is restricted by enterprise!");
        return false;
    }
    
    // 2. Context空判断
    if (context == null) {
        return false;
    }
    
    // 3. 检查换机应用是否存在
    Intent i = new Intent();
    i.setComponent(new ComponentName(
        "com.miui.huanji", 
        "com.miui.huanji.provision.ui.ProvisionCTAActivity"
    ));
    List<ResolveInfo> infos = context.getPackageManager().queryIntentActivities(i, PackageManager.MATCH_ALL);
    
    // 4. 国际版检查 + 应用存在性检查
    return !Build.IS_INTERNATIONAL_BUILD && !infos.isEmpty();
}
```

### 规则映射

| JSON配置条件 | 代码实现 | 说明 |
|------------|---------|------|
| `support_mimover: true` | `!infos.isEmpty()` | 换机应用已安装且可用 |
| `is_international: false` | `!Build.IS_INTERNATIONAL_BUILD` | 国内版ROM |
| `logic: "AND"` | 使用`&&`连接 | 所有条件必须同时满足 |

### 条件详细说明

#### 1️⃣ 企业模式限制检查
```java
if (miui.enterprise.RestrictionsHelperStub.getInstance().isRestriction(
        miui.enterprise.RestrictionsHelperStub.DISALLOW_MIMOVER)) {
    return false;
}
```
- 企业版设备可能禁用换机功能（安全策略）
- 通过`RestrictionsHelperStub`检查企业限制策略

#### 2️⃣ 换机应用存在性检查
```java
Intent i = new Intent();
i.setComponent(new ComponentName(
    "com.miui.huanji", 
    "com.miui.huanji.provision.ui.ProvisionCTAActivity"
));
List<ResolveInfo> infos = context.getPackageManager().queryIntentActivities(i, PackageManager.MATCH_ALL);
return !infos.isEmpty();
```
- 检查`com.miui.huanji`包是否已安装
- 检查是否存在`ProvisionCTAActivity`组件
- 如果应用未安装或组件不可用，返回false

#### 3️⃣ 国际版限制
```java
return !Build.IS_INTERNATIONAL_BUILD;
```
- 国际版ROM不支持换机功能
- `Build.IS_INTERNATIONAL_BUILD`是MIUI定义的系统属性

#### 4️⃣ 换机状态检查
```java
return !checkHuanjiFinish(context);
```
- 如果用户已经完成换机流程，跳过此页面
- 通过SharedPreferences记录换机完成状态

### 应用场景

**✅ 显示换机页面的条件：**
- 国内版ROM（`!Build.IS_INTERNATIONAL_BUILD`）
- 换机应用已安装（`com.miui.huanji`）
- 非企业模式限制
- 用户尚未完成换机流程

**❌ 跳过换机页面的情况：**
- 国际版ROM（不包含换机功能）
- 换机应用未安装或不可用
- 企业模式下被限制
- 用户已完成换机流程

**典型用户场景：**
1. 用户首次开机国内版新手机
2. 系统检测到换机应用可用
3. 显示换机引导页面，提供：
   - 从旧手机迁移数据
   - 跳过换机流程
4. 用户选择后，系统记录状态，下次启动不再显示

**技术细节：**
- 使用`MiConnectServer`建立设备间的蓝牙/Wi-Fi连接
- 支持IDM（Intelligent Device Manager）极速迁移模式
- 页面退出时会销毁`MiConnectServer`实例以释放资源

---

## 🔄 状态机流转逻辑

### 流程图

```
[StartupState]
     ↓
   isAvailable() → false → 跳过
     ↓ true
[LanguageState]
     ↓
   isAvailable() → false → 跳过
     ↓ true
[FontState] ← 字体规则判断
     ↓
   isAvailable() → false → 跳过
     ↓ true
[MiMoverState] ← 换机规则判断
     ↓
   ...更多State...
     ↓
[FinishState]
```

### 关键代码流程

```java
// 1. 用户点击"下一步"
onActivityResult(RESULT_OK) 
    → StateMachine.run(RESULT_OK)
    → transitToNext()

// 2. 获取下一个可用State
State next = getNextAvailableState(mCurrentState);
    → do-while循环查找
    → 调用每个State的isAvailable(true)
    → 跳过返回false的State
    → 返回第一个返回true的State

// 3. 状态切换
mCurrentState.onLeave();  // 离开当前页面
mCurrentState = next;     // 切换状态
mCurrentState.onEnter(true, true);  // 进入新页面
```

---

## 🎯 设计模式分析

### 1. 状态模式（State Pattern）

**优点：**
- ✅ **解耦页面逻辑**：每个页面的显示规则独立在自己的State类中
- ✅ **易于扩展**：添加新页面只需创建新的State子类
- ✅ **自动化流转**：StateMachine自动处理页面跳过逻辑
- ✅ **可维护性高**：规则集中在`isAvailable()`方法中

**缺点：**
- ⚠️ **类数量增多**：每个页面需要一个State类
- ⚠️ **规则硬编码**：规则直接写在代码中，无法动态配置

### 2. 责任链模式（Chain of Responsibility）

StateMachine的`getNextAvailableState()`实现了责任链：
```java
do {
    current = next;
    next = getNextState();
} while (next != null && !next.isAvailable(true));
```

每个State检查自己是否可用，不可用则传递给下一个State。

### 3. 模板方法模式（Template Method）

State基类定义了生命周期模板：
```java
onEnter() → isAvailable() → onLeave()
```

子类重写`isAvailable()`实现具体规则。

---

## 📈 规则引擎对比

### 当前实现（硬编码规则）

```java
// 优点：
// - 性能好，直接方法调用
// - 类型安全，编译期检查
// - IDE支持好，可跳转、重构

// 缺点：
// - 规则硬编码，无法动态修改
// - 修改规则需要重新编译
// - 规则分散在各个State子类中
```

### JSON配置规则引擎（用户提供的方案）

```json
// 优点：
// - 规则集中管理
// - 可动态配置（通过云控）
// - 易于理解和维护
// - 支持A/B测试

// 缺点：
// - 需要解析引擎
// - 运行时开销
// - 类型不安全
// - 调试困难
```

---

## 🚀 改进建议

### 方案1：引入规则解析引擎

```java
public class RuleEngine {
    private Map<String, Rule> rules;
    
    public boolean evaluate(String ruleId, Context context) {
        Rule rule = rules.get(ruleId);
        if (!rule.enabled) return false;
        
        boolean result = true;
        for (Condition condition : rule.conditions) {
            boolean conditionResult = evaluateCondition(condition, context);
            result = rule.logic.equals("AND") ? result && conditionResult : result || conditionResult;
        }
        return result;
    }
    
    private boolean evaluateCondition(Condition condition, Context context) {
        switch (condition.type) {
            case "feature":
                return checkFeature(condition.key, condition.value, context);
            case "device":
                return checkDevice(condition.key, condition.value);
            case "build":
                return checkBuild(condition.key, condition.value);
            default:
                return false;
        }
    }
}

// State实现改造
public static class FontState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        return RuleEngine.getInstance().evaluate("font_state_rules", context);
    }
}
```

### 方案2：注解驱动配置

```java
@StateRule(
    conditions = {
        @Condition(type = "feature", key = "support_misans", value = true),
        @Condition(type = "device", key = "is_fold", value = false),
        @Condition(type = "font_count", value = 2)
    },
    logic = Logic.AND
)
public static class FontState extends State {
    // 规则自动生成，无需手动实现isAvailable()
}
```

### 方案3：混合模式（推荐）

```java
public static class FontState extends State {
    @Override
    public boolean isAvailable(boolean toNext) {
        // 优先使用云控配置
        if (CloudConfigManager.hasRule("font_state_rules")) {
            return RuleEngine.evaluate("font_state_rules", context);
        }
        
        // 降级到硬编码规则
        return Utils.isMiSansSupportLanguages() 
            && FontStyleFragment.getFontList(context).size()==2 
            && !Utils.isFoldDevice() 
            && !Utils.isInProvisionState(context);
    }
}
```

**优点：**
- ✅ 云控配置优先，支持动态调整
- ✅ 硬编码降级，保证稳定性
- ✅ 渐进式迁移，风险可控

---

## 📝 总结

### 核心要点

1. **状态机设计**：MiuiProvision使用State Pattern管理页面流转
2. **规则判断**：每个State的`isAvailable()`方法实现显示规则
3. **自动跳过**：StateMachine自动过滤不可用的State
4. **条件组合**：使用`&&`（AND）或`||`（OR）组合多个条件

### 规则实现映射

| 功能 | State类 | 规则文件位置 | 关键方法 |
|-----|--------|------------|---------|
| 字体选择 | `FontState` | `GlobalDefaultActivity.java:520` | `isMiSansSupportLanguages()`, `isFoldDevice()` |
| 换机功能 | `MiMoverState` | `DefaultActivity.java:1353` | `supportMiMover()` |

### 应用场景

- **字体选择**：国内版、非折叠屏、支持MiSans的语言环境
- **换机功能**：国内版、换机应用已安装、非企业限制

### 扩展性

如果要实现JSON配置驱动的规则引擎，建议采用**混合模式**：
- 优先使用云控配置（灵活）
- 降级到硬编码规则（稳定）
- 逐步迁移现有规则

---

**文档版本**: v1.0  
**创建日期**: 2025-10-20  
**适用版本**: MiuiProvision 25Q2
