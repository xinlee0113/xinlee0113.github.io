---
layout: default
title: Framework模块划分与问题归属指南
parent: 操作手册
---



# Framework模块划分与问题归属指南

## Framework模块完整列表

### 1. 核心系统服务
- **Framework-核心组件AMS-其他**
- **Framework-核心组件AMS-广播**
- **Framework-核心组件AMS-服务**
- **Framework-核心组件AMS-生命周期**
- **Framework-应用包管理PMS**
- **Framework-权限Permissions**

### 2. 窗口与显示
- **Framework-窗口管理-Insets**
- **Framework-窗口管理-其他**
- **Framework-窗口管理-动画**
- **Framework-窗口管理-横竖屏**
- **Framework-窗口管理-稳定性**
- **Framework-渲染与绘制-HDR**
- **Framework-渲染与绘制-其他**
- **Framework-渲染与绘制-显示异常**
- **Framework-渲染与绘制-流畅度**
- **Framework-渲染与绘制-稳定性**
- **Framework-渲染与绘制-高级材质**

### 3. 多窗口与分屏
- **Framework-分屏Multiwindow-三方兼容**
- **Framework-分屏Multiwindow-分屏单开单关**
- **Framework-分屏Multiwindow-性能**
- **Framework-分屏Multiwindow-稳定性**
- **Framework-分屏Multiwindow-黑花闪**
- **Framework-自由窗口-三方兼容**
- **Framework-自由窗口-小窗迷你窗**
- **Framework-自由窗口-智能推荐**
- **Framework-自由窗口-贴边&气泡**
- **Framework-画中画 PIP**
- **Framework-平行视界**

### 4. 折叠屏与横屏
- **Framework-折叠屏连续性-Flip**
- **Framework-折叠屏连续性-Fold**
- **Framework-内缩-Flip**
- **Framework-内缩-Fold**
- **Framework-横屏框架-Pad&Fold**
- **Framework-背屏**

### 5. 多任务与性能
- **Framework-多任务-Performance**
- **Framework-多任务-Stability**
- **Framework-多窗口切换-窗口拖拽**
- **Framework-多窗口切换-窗口控制器**

### 6. 应用管理
- **Framework-应用双开 XSpace**
- **Framework-应用悬停**
- **Framework-手机分身 SecSpace**
- **Framework-AppFunction**

### 7. 输入与交互
- **Framework-按键Input**
- **Framework-输入法InputMethod**
- **Framework-内容拖拽**
- **Framework-震动vibrator**
- **Framework-启键**

### 8. 通知与显示
- **Framework-通知Notification**
- **Framework-弹幕通知**
- **Framework-亮/灭屏异常Power**

### 9. 系统功能
- **Framework-个性化机制Theme Mechanism**
- **Framework-字体渲染**
- **Framework-文本识别Catcher**
- **Framework-分享ResolverActivity**
- **Framework-勿扰模式-DND**
- **Framework-网络 Network**
- **Framework-维修模式**

### 10. 桌面与UI
- **Framework-Desktopmode**
- **Framework-自适应UI引擎**
- **Framework-无极缩放**

---

## BUGOS2-716277问题归属分析

### 问题概述
**问题**：开机引导重启后用户协议无法打开  
**根因**：Framework层UserController与PackageManagerService模块间的时序协调问题  
**现象**：ACTION_USER_UNLOCKED广播发送时，PackageManager服务实际上还未完全准备好

### 涉及的Framework组件

#### 主要涉及（60%责任）
**UserController**
- **所属模块**：`Framework-核心组件AMS-生命周期`
- **代码路径**：`frameworks/base/services/core/java/com/android/server/am/UserController.java`
- **问题**：
  - 在keystore2触发解锁事件后立即发送ACTION_USER_UNLOCKED广播
  - 未等待PackageManagerService等关键服务完成CE应用状态更新
  - 广播语义不准确：表示"用户已解锁"，但实际PackageManager还需2-5秒

#### 次要涉及（40%责任）
**PackageManagerService**
- **所属模块**：`Framework-应用包管理PMS`
- **代码路径**：`frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java`
- **问题**：
  - 接收到用户解锁通知后，CE应用可见性状态更新过慢
  - 在更新完成前，resolveActivity()查询返回null
  - 缺少明确的"准备完成"通知机制

#### 关联组件
**LockSettingsService**
- **所属模块**：`Framework-核心组件AMS-其他`
- **代码路径**：`frameworks/base/services/core/java/com/android/server/locksettings/LockSettingsService.java`
- **说明**：该模块按照安全策略正确执行，不是问题根源

**ActivityStarterImpl**
- **所属模块**：`Framework-核心组件AMS-生命周期`
- **代码路径**：`frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java`
- **说明**：该模块是问题的受害者，接收到PackageManager返回的null后抛出异常

---

## 建议转派路径

### 方案1：转派到核心组件AMS团队（推荐）⭐

**理由**：
1. **主要责任在UserController**（60%），属于AMS核心组件
2. UserController负责用户状态管理和广播发送机制
3. 需要协调AMS内部多个组件的时序问题
4. 涉及系统启动流程和用户解锁流程的架构设计

**具体模块**：`Framework-核心组件AMS-生命周期`

**关键人员**：负责UserController、UserState、用户生命周期管理的开发人员

**需要评估的问题**：
1. ACTION_USER_UNLOCKED广播的发送时机是否合理？
2. 是否应该等待关键服务（如PackageManager）准备完成后再发送？
3. 是否需要引入新的广播机制（如分阶段通知）？
4. 如何建立Framework层服务间的协调机制？

---

### 方案2：同时抄送应用包管理PMS团队

**理由**：
1. PackageManagerService承担40%责任
2. CE应用状态更新速度影响用户体验
3. 需要优化服务就绪通知机制

**具体模块**：`Framework-应用包管理PMS`

**关键人员**：负责PackageManagerService、应用可见性管理的开发人员

**需要评估的问题**：
1. 为什么CE应用状态更新需要2-5秒？
2. 能否优化更新速度？
3. 是否可以提供明确的"准备完成"回调接口？
4. 能否在resolveActivity()前增加状态检查？

---

### 方案3：跨团队联合评估（最佳）⭐⭐⭐

**建议流程**：
1. **主责**：`Framework-核心组件AMS-生命周期`团队
2. **协同**：`Framework-应用包管理PMS`团队
3. **评审**：系统架构组评审广播机制设计

**评估重点**：
- UserController与PackageManagerService的协调机制
- ACTION_USER_UNLOCKED广播的语义定义
- Framework层服务间的依赖关系和就绪通知机制
- 系统启动流程的优化方向

---

## 问题升级建议

### 问题级别
**建议定级**：P1（高优先级）

**理由**：
1. 影响用户首次开机体验
2. 高频偶现（复现率2/3）
3. 涉及Framework核心服务的架构设计缺陷
4. 可能影响其他依赖ACTION_USER_UNLOCKED广播的功能

### 临时规避方案
在Framework团队修复前，应用层可以做防御性修复：
- 在Utils.startActivityAsUser()中增加UserManager.isUserUnlocked()检查
- 提示用户"系统正在启动，请稍候"而不是"ActivityNotFound"

### 根本修复方案
需要Framework团队从架构层面解决：
1. 优化UserController的广播发送时机
2. 优化PackageManagerService的状态更新速度
3. 建立服务间协调机制
4. 明确广播语义，避免误导应用层

---

## 附录：问题关键证据

### 日志证据
```
18:07:29.439  keystore2: on_device_unlocked(user_id=0)
              → UserController发送ACTION_USER_UNLOCKED广播

18:07:29.458  FaceUnlockTrack: CE存储不可用
              → Framework自身服务报错（相差19ms）

18:07:31.505  ActivityStarterImpl: aInfo is null for resolve intent
              → PackageManager仍无法查询（相差2066ms）
```

### 时序问题窗口期
- **广播发送到PackageManager实际可用**：2-5秒
- **用户操作时机**：系统启动后9秒
- **问题发生概率**：取决于用户操作速度和系统负载

### 相关文档
- 详细分析：`docs/问题修复/BUGOS2-716277_开机引导重启后用户协议无法打开问题分析.md`
- Jira链接：https://jira-phone.mioffice.cn/browse/BUGOS2-716277

---

**文档创建**：2025-10-20  
**创建人**：李新  
**用途**：Framework问题转派指引
