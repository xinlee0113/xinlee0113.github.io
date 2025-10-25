---
layout: default
title: BSP模块划分与问题归属指南
parent: 操作手册
---



# BSP模块划分与问题归属指南

## 📋 文档说明

**创建时间**：2025-10-20  
**创建人**：李新  
**用途**：BSP（Board Support Package）问题转派指引  
**数据来源**：Jira系统BSP模块分类（截至2025年10月）

---

## 🏗️ BSP模块完整列表

### 1. 系统适配与稳定性

#### BSP-Adapt
- **描述**：系统适配相关
- **典型问题**：硬件平台适配、驱动移植

#### BSP-Android-Stability
- **描述**：Android系统稳定性
- **典型问题**：系统级崩溃、内核panic、watchdog

#### BSP-System-Stability
- **描述**：系统稳定性
- **典型问题**：系统异常重启、底层服务崩溃

---

### 2. 音频与蓝牙

#### BSP-Audio
- **描述**：音频驱动与处理
- **典型问题**：音频播放异常、录音问题、音频路由

#### BSP-Bluetooth
- **描述**：蓝牙驱动
- **典型问题**：蓝牙连接失败、音频传输问题

#### BSP-BT
- **描述**：蓝牙相关（可能是Bluetooth的简称）
- **典型问题**：蓝牙底层驱动问题

---

### 3. 日志与调试

#### BSP-CatchLog
- **描述**：日志抓取工具
- **典型问题**：日志收集失败、调试工具问题

---

### 4. 充电与电池

#### BSP-Charger
- **描述**：充电驱动
- **典型问题**：充电速度异常、充电识别问题

#### BSP-Wireless-Charger
- **描述**：无线充电
- **典型问题**：无线充电不工作、充电效率低

---

### 5. 测试与诊断

#### BSP-CIT
- **描述**：CIT（Circuit Integrated Test）硬件测试
- **典型问题**：工厂测试问题、硬件自检异常

#### BSP-DCK
- **描述**：DCK相关（具体含义待确认）
- **典型问题**：待补充

---

### 6. 性能与工具

#### BSP-DFX-MiSight
- **描述**：DFX（Design for X）性能诊断工具
- **典型问题**：性能监控、问题诊断工具

---

### 7. 显示相关 ⭐

#### BSP-Display
- **描述**：显示驱动、屏幕控制
- **典型问题**：
  - 屏幕闪烁、黑屏
  - 显示异常、花屏
  - 亮度调节问题
  - 刷新率问题
- **常见日志关键词**：
  - `DisplayBase::SetDisplayState`
  - `SDM` (Snapdragon Display Manager)
  - `SetHWDetailedEnhancerConfig`

---

### 8. 文件系统

#### BSP-Filesystem
- **描述**：文件系统驱动
- **典型问题**：存储读写异常、文件系统损坏

---

### 9. 指纹与游戏

#### BSP-Fingerprint
- **描述**：指纹识别驱动
- **典型问题**：指纹识别失败、录入问题

#### BSP-GAME
- **描述**：游戏性能优化
- **典型问题**：游戏卡顿、性能调度

---

### 10. 定位服务

#### BSP-GPS
- **描述**：GPS定位驱动
- **典型问题**：定位失败、精度低

#### BSP-GPS-BDSMS
- **描述**：北斗定位系统
- **典型问题**：北斗信号接收问题

---

### 11. 震动与内核

#### BSP-Haptic
- **描述**：震动马达驱动
- **典型问题**：震动失效、震动异常

#### BSP-Kernel
- **描述**：Linux内核相关
- **典型问题**：内核崩溃、驱动加载失败

---

### 12. 内存管理

#### BSP-Memory
- **描述**：内存管理、OOM处理
- **典型问题**：内存泄漏、OOM killer

---

### 13. 基带与通信 ⭐⭐⭐

#### BSP-Modem
- **描述**：基带处理器、Modem驱动
- **典型问题**：
  - 信号异常
  - 网络连接失败
  - 基带固件问题
  - **Radio/Modem初始化问题**
  - **SIM卡切换问题**
- **常见日志关键词**：
  - `qcrilNrd`
  - `Modem`
  - `Radio`
  - `RIL`
- **相关问题示例**：
  - BUGOS2-701008（SIM切换导致Display关闭）

#### BSP-Modem-Carrier
- **描述**：运营商定制、网络兼容性
- **典型问题**：特定运营商网络问题、VoLTE

#### BSP-Telephony
- **描述**：电话功能底层支持
- **典型问题**：
  - 通话质量问题
  - SIM卡识别问题
  - eSIM功能异常
  - **TelephonyManager底层实现**
- **常见日志关键词**：
  - `TelephonyManager`
  - `telephony-radio`
  - `SecureElement-Terminal-SIM`

---

### 14. 网络与NFC

#### BSP-Network
- **描述**：网络驱动（WiFi/数据）
- **典型问题**：网络连接异常、数据传输问题

#### BSP-NFC
- **描述**：NFC驱动
- **典型问题**：NFC不工作、刷卡失败

---

### 15. 其他功能

#### BSP-Other
- **描述**：未分类的其他BSP问题
- **典型问题**：不明确归属的底层问题

---

### 16. 性能优化 ⭐

#### BSP-Performance
- **描述**：整体性能优化
- **典型问题**：系统卡顿、性能调度

#### BSP-Performance-CPU调度优化
- **描述**：CPU调度策略优化
- **典型问题**：CPU频率调节、核心调度

#### BSP-Performance-IO优化
- **描述**：IO性能优化
- **典型问题**：存储读写性能、IO调度

#### BSP-Performance-内存优化
- **描述**：内存性能优化
- **典型问题**：内存回收策略、ZRAM

#### BSP-Performance-整机卡顿
- **描述**：整机级别的卡顿问题
- **典型问题**：系统响应慢、ANR

#### BSP-Performance-框架优化
- **描述**：底层框架性能优化
- **典型问题**：系统服务性能、驱动效率

#### BSP-Performance-流畅度优化
- **描述**：用户体验流畅度
- **典型问题**：滑动卡顿、动画掉帧

---

### 17. 电源管理 ⭐

#### BSP-Power
- **描述**：电源管理驱动
- **典型问题**：
  - 待机功耗高
  - 休眠唤醒异常
  - **Power状态管理**
  - **WakeLock问题**
- **常见日志关键词**：
  - `PowerManager`
  - `WakeLock`
  - `suspend`
  - `resume`

#### BSP-Power-nj
- **描述**：电源管理（南京团队？）
- **典型问题**：待补充

#### BSP-Power-sz
- **描述**：电源管理（深圳团队？）
- **典型问题**：待补充

---

### 18. 重启相关

#### BSP-Reboot
- **描述**：系统重启机制
- **典型问题**：重启失败、异常重启、重启循环

---

### 19. 安全模块

#### BSP-Security-数据安全
- **描述**：数据加密、存储安全
- **典型问题**：数据加密失败、安全存储问题

#### BSP-Security-跨端安全
- **描述**：设备间安全通信
- **典型问题**：跨设备认证、安全连接

#### BSP-Security-身份认证
- **描述**：生物识别、密码验证
- **典型问题**：认证失败、安全芯片问题

---

### 20. 传感器

#### BSP-Sensor
- **描述**：各类传感器驱动
- **典型问题**：
  - 加速度计、陀螺仪异常
  - 光线传感器失效
  - 距离传感器问题

---

### 21. 热管理

#### BSP-Thermal
- **描述**：温度监控与热管理
- **典型问题**：过热降频、温控策略

---

### 22. 触控相关

#### BSP-Touch
- **描述**：触摸屏驱动
- **典型问题**：触控失灵、误触、灵敏度问题

---

### 23. USB与UWB

#### BSP-Usb
- **描述**：USB驱动
- **典型问题**：USB连接识别、数据传输

#### BSP-UWB
- **描述**：超宽带（Ultra-Wideband）
- **典型问题**：UWB定位、设备发现

---

### 24. 视频与WiFi

#### BSP-Video
- **描述**：视频编解码驱动
- **典型问题**：视频播放异常、编码问题

#### BSP-WIFI
- **描述**：WiFi驱动
- **典型问题**：WiFi连接失败、信号弱

---

### 25. 专项技术

#### BSP-专项技术 SpecialTech
- **描述**：特殊技术项目
- **典型问题**：创新功能、特殊硬件支持

---

### 26. 媒体库

#### BSP-媒体库
- **描述**：媒体编解码库
- **典型问题**：音视频编解码问题

---

## 🎯 常见问题归属快速查询

### Display相关问题

| 问题现象 | 推荐模块 | 次要模块 |
|---------|---------|---------|
| 屏幕黑屏/闪黑 | BSP-Display | BSP-Power |
| 花屏/显示异常 | BSP-Display | - |
| 亮度调节异常 | BSP-Display | BSP-Sensor |
| 刷新率问题 | BSP-Display | BSP-Performance |

### 通信相关问题

| 问题现象 | 推荐模块 | 次要模块 |
|---------|---------|---------|
| 信号异常 | BSP-Modem | BSP-Telephony |
| SIM卡识别问题 | BSP-Telephony | BSP-Modem |
| eSIM功能异常 | BSP-Telephony | BSP-Modem |
| VoLTE问题 | BSP-Modem-Carrier | BSP-Telephony |
| **SIM切换导致其他异常** | **BSP-Modem** | **BSP-Telephony, BSP-Display** |

### 电源相关问题

| 问题现象 | 推荐模块 | 次要模块 |
|---------|---------|---------|
| 待机功耗高 | BSP-Power | BSP-Modem, BSP-WIFI |
| 休眠唤醒异常 | BSP-Power | BSP-Kernel |
| 充电异常 | BSP-Charger | BSP-Power |
| 错误suspend/resume | BSP-Power | BSP-Kernel |

### 性能相关问题

| 问题现象 | 推荐模块 | 次要模块 |
|---------|---------|---------|
| 系统卡顿 | BSP-Performance-整机卡顿 | BSP-Performance-CPU调度优化 |
| 存储读写慢 | BSP-Performance-IO优化 | BSP-Filesystem |
| 内存不足/OOM | BSP-Performance-内存优化 | BSP-Memory |
| 动画掉帧 | BSP-Performance-流畅度优化 | BSP-Display |

### 稳定性相关问题

| 问题现象 | 推荐模块 | 次要模块 |
|---------|---------|---------|
| 系统崩溃/重启 | BSP-System-Stability | BSP-Kernel |
| 内核panic | BSP-Kernel | BSP-System-Stability |
| watchdog | BSP-Android-Stability | BSP-Kernel |
| 驱动崩溃 | 具体驱动模块 | BSP-System-Stability |

---

## 📝 BUGOS2-701008 转派示例

### 问题简述
**标题**：开机引导激活eSIM卡返回后闪黑  
**现象**：从eSIM管理界面返回到SIM卡检测界面时，界面突然闪黑约1秒

### 根本原因
Radio/Modem在处理SIM类型切换（eSIM→物理SIM）时，错误触发了Display关闭信号

### 转派建议

**主转派模块**：**BSP-Modem** ⭐⭐⭐

**理由**：
1. 问题根源：Modem重新初始化时错误触发Display关闭
2. 日志证据：
   ```
   15:49:33.873  QtiRadioConfigProxyHandler: SET_SIM_TYPE_RESPONSE
   15:49:33.876  qcrilNrd: xiaomi_qcril_uim 更新
   15:49:33.879  telephony-radio wakelock频繁ACQ/REL
   15:49:33.984  Display OFF ← Bug触发
   ```
3. 调用链：setEsimState() → qcrilNrd → Modem初始化 → Display异常关闭
4. 责任占比：50%

**抄送模块**：
- **BSP-Telephony**（协助排查TelephonyManagerEx接口）
- **BSP-Display**（协助排查Display控制逻辑）
- **BSP-Power**（协助排查电源信号来源）

**问题描述模板**：
```
【问题】：SIM卡GPIO切换时错误触发Display关闭
【现象】：调用setEsimState(1)后，Display OFF 243ms
【影响】：用户看到闪黑，体验极差
【复现】：开机引导-激活eSIM超时-返回检测SIM卡界面
【日志】：bugreport-pudding_eea-BP2A.250605.031.A3-2025-09-18-15-49-54.txt
【分析文档】：docs/问题修复/BUGOS2-701008_开机引导激活esim卡返回后闪黑问题分析.md

【需要排查】：
1. Modem初始化的电源管理逻辑
2. 是否错误发送suspend/screen_off信号
3. SIM卡GPIO操作与Display的耦合
4. 基带固件版本是否有已知Bug

【关键时间点】：
15:49:33.873  Modem处理SIM类型切换
15:49:33.984  Display异常关闭
15:49:34.227  Display恢复
```

---

## 🔍 日志关键词匹配表

| 日志关键词 | 相关BSP模块 |
|-----------|------------|
| `qcrilNrd`, `RIL` | BSP-Modem, BSP-Telephony |
| `DisplayBase::SetDisplayState` | BSP-Display |
| `SDM` (Snapdragon Display Manager) | BSP-Display |
| `PowerManager`, `WakeLock` | BSP-Power |
| `kernel panic`, `oops` | BSP-Kernel |
| `thermal`, `temperature` | BSP-Thermal |
| `touchscreen`, `input` | BSP-Touch |
| `battery`, `charger` | BSP-Charger |
| `WiFi`, `wlan` | BSP-WIFI |
| `bluetooth`, `bt` | BSP-Bluetooth |
| `camera`, `sensor` | BSP-Sensor |
| `audio`, `codec` | BSP-Audio |
| `USB` | BSP-Usb |
| `NFC` | BSP-NFC |
| `GPS`, `location` | BSP-GPS |
| `memory`, `OOM` | BSP-Memory, BSP-Performance-内存优化 |
| `CPU`, `scheduler` | BSP-Performance-CPU调度优化 |
| `IO`, `block`, `storage` | BSP-Performance-IO优化 |

---

## 📊 BSP模块统计

**总数**：约50+个子模块

**主要分类**：
- 系统稳定性：3个
- 音频蓝牙：3个
- 充电电池：2个
- 显示相关：1个 ⭐
- 基带通信：3个 ⭐⭐⭐
- 性能优化：7个
- 电源管理：3个 ⭐
- 安全模块：3个
- 传感器：1个
- 其他硬件：10+个

**高频问题模块TOP5**：
1. BSP-Modem（通信问题）
2. BSP-Display（显示问题）
3. BSP-Power（电源问题）
4. BSP-Performance-整机卡顿（性能问题）
5. BSP-System-Stability（稳定性问题）

---

## 📌 使用建议

### 1. 转派前准备
- ✅ 收集完整的bugreport日志
- ✅ 记录问题复现步骤
- ✅ 分析日志找到关键证据
- ✅ 明确问题现象和影响
- ✅ 准备完整的分析文档

### 2. 选择正确模块
- 🔍 先看日志关键词（参考日志关键词匹配表）
- 🔍 分析问题根源（硬件/驱动/固件）
- 🔍 确定责任模块（可能多个）
- 🔍 主转派+抄送其他相关模块

### 3. 描述问题要点
- 📝 问题现象（用户体验）
- 📝 技术根因（底层机制）
- 📝 日志证据（关键时间点）
- 📝 影响范围（其他功能）
- 📝 复现条件（触发场景）

### 4. 跟进协作
- 🤝 提供技术支持
- 🤝 补充日志信息
- 🤝 协助复现问题
- 🤝 验证修复方案

---

## 🔄 文档维护

**更新频率**：每季度更新一次或有重大变更时更新  
**维护人**：李新  
**反馈渠道**：发现模块变更或新增时及时更新文档

**变更记录**：
- 2025-10-20：初始版本创建，基于Jira系统BSP模块分类

---

**文档结束**
