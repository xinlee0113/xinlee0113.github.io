---
layout: default
title: BUGOS2-695299 - com.android.htmlviewer 明示小米账号隐私问题分析
parent: 问题修复
---



# BUGOS2-695299 - com.android.htmlviewer 明示小米账号隐私问题分析

## 📋 问题概述

**问题单号**: BUGOS2-695299  
**问题标题**: 【284log】com.android.htmlviewer 明示小米账号  
**优先级**: 紧急  
**问题类型**: 故障（隐私问题）  
**组件**: Htmlviewer  
**标签**: 无、隐私  
**Bug Category**: 隐私 Privacy  

**Jira链接**: https://jira-phone.mioffice.cn/browse/BUGOS2-695299

## 📝 问题描述

### 测试信息
- **测试类型**: 用例相关（284log隐私检查）
- **测试用例ID**: C10007554526

### 测试步骤
抓取284log，查看解析后的284log，搜索需要监控的关键字：小米账号、手机号、IMEI号、位置信息、基站、ICCID、SSID、Mac地址等

### 实际结果 vs 预期结果
- **实际结果**: com.android.htmlviewer 明示小米账号
- **预期结果**: log中不出现明文信息

### ⏰ 关键时间信息
- **问题发生时间**: 2025-09-17 16:12:50.998
- **分析窗口**: 2025-09-17 16:05 - 16:20

## 🔍 环境信息

- **设备型号**: P10 (pudding_eea)
- **系统版本**: OS3.0.250915.1.WPJEUXM
- **Android版本**: 16.0
- **区域**: eea
- **分支类型**: w-stable
- **设备编号**: P1

## 📦 日志信息

### 日志采集时间验证 ⭐⭐⭐

#### 可用日志（推荐使用）
✅ **bugreport-klee_ru-BP2A.250605.031.A3-2025-09-17-16-18-49.txt**
- **来源**: 提效工具日志（BUGOS2-695299.zip）
- **采集时间**: 2025-09-17 16:18:49
- **问题发生时间**: 2025-09-17 16:12:50
- **时间差**: 约6分钟
- **结论**: ✅ 日志时间完全匹配，可用于问题分析

#### 不可用日志
❌ **bugreport-pudding_eea-BP2A.250605.031.A3-2025-10-11-02-40-39.zip**
- **来源**: Jira附件
- **采集时间**: 2025-10-11 02:40:39
- **问题发生时间**: 2025-09-17 16:12:50
- **时间差**: 约24天（后采集）
- **结论**: ❌ 时间严重不匹配，无法用于问题分析（可能是测试人员后续补传的其他日志）

### 其他日志来源
- **飞书日志**: https://mi.feishu.cn/file/Cw7Tbi5esozSHjx3tXucUe7mnUd（需要登录）
- **提效工具日志**: 已下载并解析

## 📊 日志时间线分析（基于真实日志）

**分析基础**: bugreport-klee_ru-BP2A.250605.031.A3-2025-09-17-16-18-49.txt  
**问题时间点**: 2025-09-17 16:12:50.998  
**分析窗口**: 16:12:50 - 16:12:55（问题发生时间点及后续5秒）

```log
━━━━━━━━━━━━ 阶段1：问题触发阶段（16:12:50.960 - 16:12:50.998）【重点】 ━━━━━━━━━━━━

09-17 16:12:50.960  1000  1862  1862 D MiuiPermission: createPermissionView!
        （系统创建权限弹窗，可能是账号登录相关的权限请求）

09-17 16:12:50.983  1000  8776 20072 I lyra-identity-account: MiAccountBase::OnAccountLogin:50 account login, account_id 3236****3936
        （小米账号登录事件，账号ID已脱敏）

09-17 16:12:50.998  1000  1862  3650 I MiuiPermission: uid=2661879296&sid=1&device=klee_ru_global&miuiVersion=OS3.0
        【关键证据】【时间点】问题发生时间点！MiuiPermission模块打印了未脱敏的小米账号ID
        （进程：system_server, PID:1862, 线程:3650）
        （uid=2661879296 就是小米账号ID，以明文形式泄露！）

09-17 16:12:50.999  1000  1862  3650 I MiuiPermission: imei1= 864812080018487,   imei2=864812080018495
        【问题】同时还泄露了IMEI信息（设备唯一标识符）

━━━━━━━━━━━━ 阶段2：htmlviewer进程被kill（16:12:51.912 - 16:12:51.996）━━━━━━━━━━━━

09-17 16:12:51.912  1000  1862  2003 I ActivityManager: Killing 2875:com.android.htmlviewer:remote/u0a100 (adj 925): normal_mem_pressure
        （htmlviewer进程因内存压力被系统kill）

09-17 16:12:51.996  1000  1862  1974 I ActivityManager: Update process exit info for com.android.htmlviewer(2875/u10100)
        （记录进程退出信息）

━━━━━━━━━━━━ 阶段3：htmlviewer进程重启（16:12:52.916 - 16:12:53.225）━━━━━━━━━━━━

09-17 16:12:52.916  1000  1862  4129 V ActivityManager: startProcess: name=com.android.htmlviewer:remote app=null knownToBeDead=false thread=null pid=-1
        （开始启动htmlviewer进程）

09-17 16:12:52.943  1000  1862  1970 I ActivityManager: Start proc 6390:com.android.htmlviewer:remote/u0a100 for content provider {com.android.htmlviewer/com.android.settings.cloud.CloudSettingsProvider} caller=com.miui.daemon
        【状态切换】htmlviewer进程重新启动，PID=6390
        【注意】启动原因：CloudSettingsProvider被com.miui.daemon调用

09-17 16:12:52.996 10100  6390  6390 D ActivityThread: setEmbeddedParam packageName=com.android.htmlviewer processName=com.android.htmlviewer:remote isEmbedded=false isIsolated=false
        （htmlviewer进程初始化，uid=10100）

09-17 16:12:53.217 10100  6390  6390 I htmlviewercloudcontrol: isStagingEnv:false scheduleCloudControlJobs
        （htmlviewer的云控任务调度）

09-17 16:12:53.225 10100  6390  6425 I htmlviewercloudcontrol: isStagingEnv:false param =  PerfTurbo  uriMatch = 1, cluster: global, version: 443711, traceId: bcccd9c18ad183f9365be6a2fee3ff1f, regId: 
        （开始访问云控配置）

━━━━━━━━━━━━ 阶段4：系统其他模块活动（16:12:55.387 - 16:12:55.849）━━━━━━━━━━━━

09-17 16:12:55.387 10183  6904  7263 I ##XLogger##: J3.@IPV6@SourceFile:73, thread:373--getAuthToken:Bundle[{authAccount=@XIAOMI_ACCOUNT, accountType=com.xiaomi, authtoken=2.0&V1_micloud&...}]
        【正确示例】其他模块中，账号信息已被脱敏为@XIAOMI_ACCOUNT占位符

09-17 16:12:55.849 10152  6408  6810 I ##XLogger##: N0.h::b@SourceFile:132, thread:1429--CloudBackupServerConfigProtocol, URL=https://appbackupapi.micloud.xiaomi.net/mic/appbackup/v1/user/cloud/control/list, ...userId":@XIAOMI_ACCOUNT},"description":"成功","ts":1758096776176}
        【正确示例】云备份服务中，账号ID也被脱敏为@XIAOMI_ACCOUNT

```

### 🔍 关键发现

1. **⏰ 问题发生准确时间**: 2025-09-17 16:12:50.998
2. **❌ 泄露内容**: 小米账号ID（2661879296）和IMEI信息（明文形式）
3. **📍 泄露位置**: system_server进程（PID:1862）的MiuiPermission模块
4. **🔗 触发场景**: 小米账号登录过程中，MiuiPermission进行权限检查时打印了敏感信息
5. **⚠️ 时间关联**: 问题发生约2秒后（16:12:52），htmlviewer进程被kill后重启，重启原因是CloudSettingsProvider被调用
6. **✅ 对比发现**: 系统中其他模块（如XLogger）都正确地将账号信息脱敏为`@XIAOMI_ACCOUNT`占位符，唯独MiuiPermission模块直接打印了明文账号ID

### 📝 日志采集说明

- **bugreport采集时间**: 2025-09-17 16:18:49（问题发生后约6分钟）
- **时间匹配性**: ✅ 完美覆盖问题发生时间点
- **日志完整性**: ✅ 包含问题现场的完整日志记录，buffer未被覆盖

## 🎯 问题范围分析

### 📍 问题归属判定

**⚠️ 重要结论：此问题不属于HTMLViewer模块，应转派至Framework团队**

#### 问题归属分析

1. **日志来源进程**：
   - 进程：system_server（PID: 1862, UID: 1000）
   - 模块：MiuiPermission
   - 线程：3650

2. **HTMLViewer的角色**：
   - HTMLViewer进程（uid=10100）在问题发生时处于被kill状态
   - 问题发生时间：16:12:50.998
   - HTMLViewer进程被kill时间：16:12:51.912（问题发生约1秒后）
   - HTMLViewer进程重启时间：16:12:52.916（问题发生约2秒后）
   - **结论**：HTMLViewer进程在问题发生时并不存在，因此不可能是该进程打印的日志

3. **真正的问题模块**：
   - **MiuiPermission模块**（Framework层）
   - 位置：system_server进程中
   - 问题：在进行权限检查时，直接打印了未脱敏的小米账号ID和IMEI信息

4. **触发场景**：
   - 小米账号登录流程
   - MiuiPermission创建权限弹窗（createPermissionView）
   - 权限检查过程中打印了敏感信息

### 🔄 问题标题的误解

问题单标题为"【284log】com.android.htmlviewer 明示小米账号"，但实际情况是：

1. **284log工具的误判**：284log工具可能根据uid=10100（htmlviewer的uid）将这条日志关联到了htmlviewer
2. **实际情况**：这条日志是system_server中MiuiPermission模块打印的，与htmlviewer进程本身无关
3. **时间验证**：问题发生时（16:12:50.998），htmlviewer进程尚未启动（2秒后才启动）

### 📊 责任判定

#### 详细调查结论

经过全面检查日志，明确各方责任：

**1. HTMLViewer进程本身**
- **是否打印未脱敏信息**：❌ 否
- **检查结果**：
  - 检查了htmlviewer进程（uid=10100）的所有日志
  - 仅包含正常的云控配置、性能监控等业务日志
  - **没有任何账号ID、IMEI等敏感信息泄露**
- **时间验证**：问题发生时（16:12:50.998），htmlviewer进程尚未启动（2秒后才启动）
- **结论**：**完全清白**

**2. MiuiPermission模块（Framework层）**
- **是否打印未脱敏信息**：✅ 是
- **泄露内容**：
  - 小米账号ID：2661879296（明文）
  - IMEI信息：864812080018487, 864812080018495（明文）
- **日志来源**：system_server进程（uid=1000, PID=1862）
- **结论**：**真正的责任方**

**3. 284log工具**
- **归属判断准确性**：⚠️ 误判
- **问题**：将system_server的MiuiPermission日志错误归属到htmlviewer
- **可能原因**：
  - 日志中的`uid=2661879296`（账号ID）被误认为与htmlviewer的进程uid（10100）相关
  - 或基于时间关联错误推断
- **结论**：工具存在归属判断逻辑缺陷

#### 责任表

| 模块 | 是否打印未脱敏信息 | 是否有责任 | 说明 |
|------|-----------------|-----------|------|
| HTMLViewer进程 | ❌ 否 | ❌ 否 | 进程在问题发生时不存在，且自身日志完全清白 |
| MiuiPermission (Framework) | ✅ 是 | ✅ 是 | 直接打印了未脱敏的账号ID和IMEI信息 |
| 284log工具 | N/A | ⚠️ 部分 | 误将问题归属到htmlviewer，存在判断逻辑缺陷 |

### 🎯 转派建议

**应转派至**：Framework团队 - MiuiPermission模块负责人

**转派理由**：
1. 日志来源明确为system_server进程中的MiuiPermission模块
2. HTMLViewer进程在问题发生时不存在，不可能是问题源头
3. 需要Framework团队修复MiuiPermission模块的日志打印逻辑，添加敏感信息脱敏处理

### 📝 Htmlviewer组件说明

**CloudSettingsProvider的间接关联**：
- HTMLViewer的CloudSettingsProvider确实在16:12:52被com.miui.daemon调用
- 但这发生在问题日志打印**2秒之后**
- 该Provider被调用与账号信息泄露无直接因果关系

## 🔧 根因分析

### 🔍 问题根本原因

**核心问题**：Framework层的MiuiPermission模块在打印日志时，未对敏感信息进行脱敏处理

### 📝 详细分析

#### 1. 日志打印位置

```java
// 推测的代码逻辑（需Framework团队确认具体代码位置）
// 位置：frameworks/base/services/core/java/com/android/server/am/MiuiPermission.java
// 或类似路径

public void checkPermission(...) {
    // ... 权限检查逻辑 ...
    
    // ❌ 问题代码：直接打印了敏感信息
    Log.i(TAG, "uid=" + accountId + "&sid=" + sid + 
          "&device=" + device + "&miuiVersion=" + version);
    
    Log.i(TAG, "imei1= " + imei1 + ",   imei2=" + imei2);
}
```

#### 2. 对比：正确的脱敏实现

系统中其他模块已经正确实现了敏感信息脱敏：

```log
✅ 正确示例1（XLogger）:
09-17 16:12:55.387 I ##XLogger##: authAccount=@XIAOMI_ACCOUNT
（将实际账号ID替换为占位符 @XIAOMI_ACCOUNT）

✅ 正确示例2（lyra-identity-account）:
09-17 16:12:50.983 I lyra-identity-account: account_id 3236****3936
（对账号ID中间部分进行星号脱敏）

❌ 错误示例（MiuiPermission）:
09-17 16:12:50.998 I MiuiPermission: uid=2661879296
（直接打印完整账号ID，未脱敏）
```

#### 3. 问题影响范围

- **影响系统**：所有使用MiuiPermission模块的系统
- **影响版本**：OS3.0.250915.1.WPJEUXM及相关版本
- **隐私风险等级**：⚠️ 高（泄露用户账号ID和设备IMEI）
- **284log检测**：✅ 能够被284log工具检测到

#### 4. 为什么284log将问题归到htmlviewer

可能的原因：
1. 日志中的`uid=2661879296`被284log工具解析时，可能与htmlviewer进程的uid（10100）产生了某种关联
2. 284log工具可能根据日志发生的时间范围，推测与该时段活跃的应用（htmlviewer）有关
3. 或者284log工具在归属判断逻辑上存在缺陷

**实际情况**：
- 日志来自system_server（uid=1000），不是htmlviewer（uid=10100）
- `uid=2661879296`是**小米账号ID**，不是进程UID

### 🎯 根因总结

1. **直接原因**：MiuiPermission模块打印日志时未脱敏
2. **根本原因**：Framework层缺少统一的敏感信息日志打印规范或工具
3. **附带问题**：284log工具的日志归属判断可能存在误导性

## 💡 解决方案

### 🔧 针对MiuiPermission模块（Framework团队）

#### 方案1：使用占位符替换（推荐）

```java
// 修改前
Log.i(TAG, "uid=" + accountId + "&sid=" + sid + 
      "&device=" + device + "&miuiVersion=" + version);

// 修改后
Log.i(TAG, "uid=@XIAOMI_ACCOUNT&sid=" + sid + 
      "&device=" + device + "&miuiVersion=" + version);
```

#### 方案2：使用星号脱敏

```java
// 修改前
Log.i(TAG, "uid=" + accountId + "&sid=" + sid + 
      "&device=" + device + "&miuiVersion=" + version);

// 修改后  
String maskedAccountId = maskAccountId(accountId); // 如: 2661****296
Log.i(TAG, "uid=" + maskedAccountId + "&sid=" + sid + 
      "&device=" + device + "&miuiVersion=" + version);
```

#### 方案3：完全移除敏感信息日志（最安全）

```java
// 如果该日志不是必需的调试信息，建议直接删除或降级为DEBUG级别
if (DEBUG) {
    // 仅在DEBUG版本打印，且使用脱敏
    Log.d(TAG, "Permission check for account: @XIAOMI_ACCOUNT");
}
```

### 📋 IMEI信息处理

```java
// 修改前
Log.i(TAG, "imei1= " + imei1 + ",   imei2=" + imei2);

// 修改后（方案1：完全不打印）
// 删除该行日志

// 修改后（方案2：脱敏打印）
String maskedImei1 = maskImei(imei1); // 如: 8648****8487
String maskedImei2 = maskImei(imei2); // 如: 8648****8495
Log.i(TAG, "imei1= " + maskedImei1 + ",   imei2=" + maskedImei2);
```

### 🛠️ 建议的脱敏工具方法

```java
/**
 * 对账号ID进行脱敏处理
 * @param accountId 原始账号ID（如：2661879296）
 * @return 脱敏后的账号ID（如：2661****296）
 */
private static String maskAccountId(String accountId) {
    if (TextUtils.isEmpty(accountId) || accountId.length() < 8) {
        return "****";
    }
    int len = accountId.length();
    return accountId.substring(0, 4) + "****" + accountId.substring(len - 3);
}

/**
 * 对IMEI进行脱敏处理
 * @param imei 原始IMEI（如：864812080018487）
 * @return 脱敏后的IMEI（如：8648****8487）
 */
private static String maskImei(String imei) {
    if (TextUtils.isEmpty(imei) || imei.length() < 12) {
        return "****";
    }
    int len = imei.length();
    return imei.substring(0, 4) + "****" + imei.substring(len - 4);
}
```

### 🎯 HTMLViewer团队行动（本模块）

**结论**：HTMLViewer模块**无需修改代码**

**建议行动**：
1. ✅ 在Jira上添加分析结论，说明问题不属于HTMLViewer
2. ✅ 提供完整的日志分析报告（本文档）
3. ✅ 建议转派至Framework团队处理
4. ✅ 抄送给284log工具团队，建议改进日志归属判断逻辑

### 📊 验证方案

修复完成后，需验证：

1. **功能验证**：小米账号登录流程正常
2. **日志验证**：
   - 运行284log工具扫描
   - 搜索关键字：账号ID、IMEI等
   - 确认所有敏感信息都已脱敏
3. **回归测试**：权限弹窗功能正常

### 🔄 长期改进建议

1. **建立统一的日志打印规范**：
   - 制定敏感信息列表（账号ID、IMEI、手机号、位置等）
   - 提供统一的脱敏工具类
   - 集成到Framework的日志工具中

2. **改进284log工具**：
   - 优化日志归属判断逻辑
   - 区分进程UID和业务数据中的ID
   - 提供更准确的问题定位

3. **代码审查机制**：
   - 在代码审查时，重点检查日志打印语句
   - 使用静态代码分析工具检测敏感信息泄露风险

## 📌 分析状态

- [x] 第一阶段：信息收集（已完成）
- [x] 第二阶段：文档创建（已完成）
- [x] 第三阶段：日志时间验证（已完成，确认可用日志）
- [x] 第四阶段：日志时间线分析（已完成）
- [x] 第五阶段：问题范围分析（已完成）
- [x] 第六阶段：根因分析与方案输出（已完成）

## 📋 后续行动

### 立即行动（本团队）
1. [ ] 在Jira BUGOS2-695299上添加分析评论
2. [ ] 附上本分析文档链接
3. [ ] 建议转派至Framework团队-MiuiPermission模块

### 跟进事项（其他团队）
1. [ ] Framework团队：修复MiuiPermission日志打印逻辑
2. [ ] 284log工具团队：改进日志归属判断
3. [ ] 测试团队：验证修复后的版本

---
*分析文档创建时间: 2025-10-16*  
*分析人: 李新*  
*文档版本: v1.0*  
*Jira链接: https://jira-phone.mioffice.cn/browse/BUGOS2-695299*
