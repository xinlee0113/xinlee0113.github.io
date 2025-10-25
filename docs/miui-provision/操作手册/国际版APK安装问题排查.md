---
layout: default
title: 国际版APK安装问题排查与解决方案
parent: 操作手册
---



# 国际版APK安装问题排查与解决方案

## 问题现象

在国际版开机向导测试过程中，多次遇到APK更新后代码未生效的问题，表现为：
- 修改了源码并编译
- 推送APK到设备
- 但运行时仍是旧代码逻辑
- 日志中看不到新增的调试信息

## 问题根源

### 1. OverlayFS机制导致系统分区无法覆盖

**现象：**
```bash
adb push app.apk /system_ext/priv-app/Provision/Provision.apk
# 输出：
# adb: error: Read-only file system
# 1 file pushed  <-- 虽然报错但显示推送成功
```

**原因：**
- Android使用OverlayFS实现动态系统分区挂载
- `adb remount`后需要重启才能生效
- 即使重启后，OverlayFS的upper层可能缓存了旧文件
- 直接`adb push`到系统分区会被OverlayFS拦截
- 推送"成功"但实际文件未更新

**验证方法：**
```bash
# 检查本地APK大小
ls -lh app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk
# 输出：16M

# 检查设备APK大小
adb shell ls -lh /system_ext/priv-app/Provision/Provision.apk
# 输出：20M  <-- 大小不同，说明是旧文件！
```

### 2. 恢复出厂设置不清除系统分区

**现象：**
- 执行恢复出厂设置（Factory Reset）
- `/data`分区被清空
- `/system_ext`分区的APK仍然保留
- 如果系统分区有旧APK，恢复出厂后仍然是旧版本

**原因：**
- Factory Reset只清除用户数据分区（`/data`）
- 系统分区（`/system`, `/system_ext`）不受影响
- 之前推送的旧APK一直存在于系统分区

### 3. Gradle增量编译缓存问题

**现象：**
```bash
# 修改源码时间：19:06:18
stat src/com/android/provision/fragment/FontStyleFragment.java

# 编译APK时间：19:02:25（更早！）
stat app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk
```

**原因：**
- Gradle认为没有变化，跳过了编译
- 使用`./gradlew assemblePhoneGlobalDebug`没有真正编译新代码
- 只更新了manifest或其他元数据

**解决：**
```bash
# 强制清理后重新编译
./gradlew clean
./gradlew assemblePhoneGlobalDebug
```

### 4. 双版本共存问题

**现象：**
```bash
adb shell dumpsys package com.android.provision | grep codePath
# 输出：
#   codePath=/data/app/.../com.android.provision
#   codePath=/system_ext/priv-app/Provision
```

**原因：**
- 系统分区有旧APK（versionCode=36）
- `/data/app`有新APK（versionCode=1400081101）
- 两个版本共存，系统优先使用版本号高的
- 但版本号高的不一定是最新代码

## 解决方案

### 最终采用方案：/data/app安装

**优点：**
1. ✅ 不受OverlayFS限制
2. ✅ 安装可靠，`adb install`机制成熟
3. ✅ 版本管理清晰
4. ✅ 可以覆盖任何现有版本（使用`-r`参数）

**缺点：**
1. ❌ 恢复出厂后会被删除，需要重新安装

**实现：**
```bash
# 安装到/data/app（会覆盖任何版本）
adb install -r -t -d app-phone-global-debug.apk

# 参数说明：
# -r: 替换已存在的应用
# -t: 允许安装测试APK
# -d: 允许降级安装
```

### 脚本自动化流程

```bash
# 1. 编译APK
./gradlew assemblePhoneGlobalDebug

# 2. 安装到/data/app
adb install -r -t -d $APK_PATH

# 3. 恢复出厂设置（国际版测试必需）
adb reboot recovery
# ... 手动操作Recovery ...

# 4. 等待设备启动后自动重新安装
adb wait-for-device
adb install -r -t -d $APK_PATH

# 5. 启用组件并开始测试
adb shell pm enable com.android.provision/...
adb shell pm enable com.google.android.setupwizard
```

## 排查步骤总结

### 问题1：代码未生效

```bash
# 步骤1：确认源码修改时间
stat -c "%y" src/com/android/provision/fragment/FontStyleFragment.java

# 步骤2：确认APK编译时间
stat -c "%y" app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk

# 步骤3：如果APK时间早于源码，强制重新编译
./gradlew clean
./gradlew assemblePhoneGlobalDebug

# 步骤4：验证编译后APK时间
stat -c "%y" app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk
# 确保时间晚于源码修改时间
```

### 问题2：APK未正确安装

```bash
# 步骤1：检查本地APK大小
ls -lh app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk

# 步骤2：检查设备APK大小和路径
adb shell dumpsys package com.android.provision | grep -E "codePath|versionName"

# 步骤3：如果有多个版本或大小不符，卸载后重新安装
adb uninstall com.android.provision  # 可能失败（系统APK）
adb install -r -t -d app-phone-global-debug.apk

# 步骤4：验证安装结果
adb shell dumpsys package com.android.provision | grep -E "codePath|versionName|lastUpdateTime"
```

### 问题3：验证代码是否生效

```bash
# 方法1：检查日志
adb logcat -c
adb logcat | grep "你添加的新日志标识"

# 方法2：反编译APK验证字符串
unzip -q app.apk -d /tmp/apk
strings /tmp/apk/classes.dex | grep "新添加的日志字符串"

# 方法3：直接运行并观察行为
adb shell am start -n com.android.provision/.activities.FontStyleActivity
```

## 废弃方案：系统分区安装

**为什么废弃：**
1. OverlayFS机制导致无法可靠覆盖文件
2. 需要重启多次才能生效
3. 恢复出厂后旧APK仍存在
4. 无法通过`rm`删除系统分区文件（Read-only）
5. 需要禁用dm-verity，风险高且复杂

**之前的尝试：**
```bash
# 尝试1：adb remount + push
adb root
adb remount  # 需要重启
adb reboot
adb push app.apk /system_ext/priv-app/Provision/Provision.apk
# 结果：报错但显示成功，实际未更新

# 尝试2：删除后推送
adb shell rm /system_ext/priv-app/Provision/Provision.apk
# 结果：Read-only file system

# 尝试3：disable-verity + remount
adb disable-verity
adb reboot
adb remount
# 结果：仍然无法可靠覆盖
```

## 最佳实践

### 开发调试阶段

1. **始终使用 /data/app 安装**
   ```bash
   adb install -r -t -d app.apk
   ```

2. **确保编译是最新的**
   ```bash
   # 有代码修改时
   ./gradlew clean assemblePhoneGlobalDebug
   
   # 快速验证编译时间
   stat -c "%y" app/build/outputs/apk/*/debug/*.apk
   ```

3. **清除旧数据测试**
   ```bash
   adb shell pm clear com.android.provision
   ```

4. **查看实时日志**
   ```bash
   adb logcat -c
   adb logcat | grep FontStyleFragment
   ```

### 国际版完整测试

1. **编译并安装到 /data/app**
2. **恢复出厂设置**
3. **等待启动后自动重新安装APK**
4. **通过GMS进入开机向导**

### 中国版测试

1. **编译并安装到 /data/app**
2. **清除数据**
3. **直接启动开机向导**

## 经验教训

1. **OverlayFS不可靠** - 系统分区修改在开发阶段不推荐
2. **验证三要素** - 源码时间、APK时间、设备APK时间都要确认
3. **日志是关键** - 添加详细日志才能快速定位问题
4. **恢复出厂≠清除所有** - 系统分区文件会保留
5. **Gradle缓存** - 遇到问题先`clean`再编译
6. **APK大小是关键指标** - 大小不同100%说明APK不同

## 相关命令速查

```bash
# 查看APK信息
adb shell dumpsys package com.android.provision | grep -E "codePath|versionName|lastUpdateTime"

# 查看APK文件
adb shell ls -lh /system_ext/priv-app/Provision/Provision.apk
adb shell ls -lh /data/app/*/com.android.provision-*/base.apk

# 卸载应用（/data/app）
adb uninstall com.android.provision

# 清除应用数据
adb shell pm clear com.android.provision

# 检查编译时间
stat -c "%y" app/build/outputs/apk/phoneGlobal/debug/app-phone-global-debug.apk

# 检查源码时间
stat -c "%y" src/com/android/provision/fragment/FontStyleFragment.java

# 强制清理编译
./gradlew clean --no-build-cache

# 实时日志
adb logcat -v time FontStyleFragment:I *:S
```

## 相关文档

- `scripts/build_and_install.sh` - 自动化安装脚本
- `docs/问题修复/国际版字体同步方案.md` - 字体同步实现
- `docs/问题修复/国际版开机引导测试完整方案.md` - 完整测试流程

## 版本历史

- 2025-10-10: 初版 - 总结APK安装问题及解决方案


