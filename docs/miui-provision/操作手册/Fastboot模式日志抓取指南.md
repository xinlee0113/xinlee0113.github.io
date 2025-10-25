---
layout: default
title: Fastboot模式日志抓取完整指南
parent: MiuiProvision项目文档
---

# Fastboot模式日志抓取完整指南

## 📌 概述

Fastboot模式下无法使用常规的adb logcat，需要使用特殊方法采集日志。本文档详细说明各种场景下的日志采集方法。

---

## 🎯 方法一：fastboot命令获取设备信息

### 基础命令

```bash
# 1. 检测设备
fastboot devices

# 2. 获取所有设备信息（最重要）
fastboot getvar all 2>&1 | tee fastboot_getvar_all.txt

# 3. 获取关键变量
fastboot getvar version        # fastboot版本
fastboot getvar product        # 产品名称
fastboot getvar serialno       # 序列号
fastboot getvar secure         # 是否secure boot
fastboot getvar unlocked       # 是否解锁
fastboot getvar current-slot   # 当前slot（A/B分区）
fastboot getvar slot-count     # slot数量
```

### 分区信息

```bash
# 查看关键分区信息
fastboot getvar partition-size:boot
fastboot getvar partition-size:system
fastboot getvar partition-size:vendor
fastboot getvar partition-type:boot
fastboot getvar partition-type:system
```

### 小米设备专用命令

```bash
# 设备信息
fastboot oem device-info

# 获取启动信息
fastboot oem get-bootinfo

# 尝试获取日志（部分设备支持）
fastboot oem log

# 获取崩溃日志
fastboot oem get-crash-log

# 获取MIUI锁状态
fastboot oem lock-status
```

---

## 🎯 方法二：串口（UART）日志 ⭐最完整

### 硬件准备

**所需设备：**
- USB转TTL串口线（推荐：CP2102、FT232RL、CH340）
- 设备串口引出点（测试机通常已引出）
- 杜邦线（如需要）

**连接说明：**
```
串口线          设备
GND   ------>  GND
TX    ------>  RX
RX    ------>  TX
VCC   ------>  不接（设备自供电）
```

### 软件安装

```bash
# Ubuntu/Linux安装串口工具
sudo apt install -y minicom screen picocom

# 查看串口设备
ls -l /dev/ttyUSB*
# 或
ls -l /dev/ttyACM*

# 添加用户到dialout组（避免权限问题）
sudo usermod -a -G dialout $USER
# 注销后重新登录生效
```

### 使用 minicom

```bash
# 启动minicom
sudo minicom -D /dev/ttyUSB0 -b 115200

# minicom配置（首次使用）
sudo minicom -s
# Serial port setup -> 
#   A: Serial Device = /dev/ttyUSB0
#   E: Bps/Par/Bits = 115200 8N1
#   F: Hardware Flow Control = No
#   G: Software Flow Control = No
# Save setup as dfl

# 开始记录日志
Ctrl-A Z    # 显示帮助菜单
L           # 开启日志记录
# 输入日志文件名：uart_log.txt

# 退出minicom
Ctrl-A X
```

### 使用 screen

```bash
# 启动screen（更简单）
sudo screen /dev/ttyUSB0 115200

# 开始记录
Ctrl-A H    # 开启日志记录（会在当前目录生成screenlog.0）

# 退出screen
Ctrl-A K    # 确认退出
```

### 使用 picocom

```bash
# 启动picocom并记录日志
sudo picocom /dev/ttyUSB0 -b 115200 -g uart_log.txt

# 退出picocom
Ctrl-A Ctrl-X
```

### 常见波特率

| 设备类型 | 波特率 |
|---------|--------|
| 大部分Android设备 | 115200 |
| 部分高通设备 | 921600 |
| 部分MTK设备 | 921600 |
| 旧设备 | 57600 |

### 串口日志内容说明

串口日志包含：
- ✅ **Bootloader日志**（LK/ABL）
- ✅ **Kernel启动日志**（类似dmesg）
- ✅ **Init进程日志**
- ✅ **底层崩溃信息**（panic、crash）
- ✅ **完整的启动时序**

---

## 🎯 方法三：通过 Recovery 间接获取

### 进入Recovery模式

```bash
# 方法1：从fastboot进入recovery
fastboot reboot recovery

# 方法2：临时启动recovery（不刷入）
fastboot boot recovery.img

# 方法3：按键组合（关机状态）
# 音量上 + 电源键（小米设备）
```

### 在Recovery中抓日志

```bash
# 检测adb设备
adb devices

# 实时查看日志
adb logcat -v threadtime

# 保存日志到文件
adb logcat -v threadtime > recovery_logcat.txt

# 获取内核日志
adb shell dmesg > recovery_dmesg.txt

# 查看最后的启动信息
adb shell cat /proc/last_kmsg > last_kmsg.txt

# 获取完整bugreport
adb bugreport recovery_bugreport.zip
```

---

## 🎯 方法四：系统启动后抓取历史日志

如果设备最终能进入系统，立即抓取启动相关日志。

### 完整 bugreport

```bash
# 抓取完整bugreport（包含启动日志）
adb bugreport bugreport_$(date +%Y%m%d_%H%M%S).zip
```

### bugreport 中的关键日志

解压bugreport.zip后查看：

| 文件/路径 | 说明 |
|----------|------|
| `FS/data/system/dropbox/` | 系统崩溃记录 |
| `dumpstate_board.txt` | 板级信息 |
| `kernel_log.txt` | 内核日志 |
| `logcat.txt` | 系统日志 |
| `bugreport-*.txt` | 主报告文件 |

### 单独获取关键日志

```bash
# 当前内核日志
adb shell dmesg > dmesg_current.txt

# 上次内核日志（如果存在）
adb shell cat /proc/last_kmsg > last_kmsg.txt
adb shell cat /sys/fs/pstore/console-ramoops > pstore_console.txt

# 启动时的logcat
adb logcat -d -b all > logcat_boot.txt

# dropbox崩溃记录
adb shell ls /data/system/dropbox/
adb pull /data/system/dropbox/

# 启动性能统计
adb shell dumpsys bootstat > bootstat.txt
```

---

## 🎯 方法五：分析现有日志文件

如果问题已经发生，设备上可能保留了日志。

### 检查设备上的日志

```bash
# 进入adb shell
adb shell

# 查看tombstone（native crash）
ls -lh /data/tombstones/

# 查看ANR日志
ls -lh /data/anr/

# 查看dropbox
ls -lh /data/system/dropbox/

# 查看persistent日志
ls -lh /data/misc/logd/

# 查看pstore（内核panic）
ls -lh /sys/fs/pstore/
```

### 导出所有日志

```bash
# 批量导出
adb pull /data/tombstones/ ./tombstones/
adb pull /data/anr/ ./anr/
adb pull /data/system/dropbox/ ./dropbox/
adb shell cat /sys/fs/pstore/console-ramoops > pstore_console.txt
```

---

## 📊 针对不同问题场景的日志策略

### 场景1：线刷后进入fastboot无法启动

**推荐方法：**
1. ⭐ **串口日志**（能看到bootloader和kernel启动过程）
2. `fastboot getvar all`（查看分区状态）
3. 如果能进recovery，抓取recovery日志

**关键信息：**
- Bootloader版本和状态
- 分区表是否完整
- Kernel是否加载成功
- Init进程是否启动

### 场景2：启动过程中反复重启

**推荐方法：**
1. ⭐ **串口日志**（捕获重启瞬间）
2. `adb shell cat /proc/last_kmsg`（如果能短暂进系统）
3. `adb shell cat /sys/fs/pstore/console-ramoops`

**关键信息：**
- Kernel panic信息
- 重启前最后的日志
- 可能的死循环点

### 场景3：黑屏但adb可用

**推荐方法：**
1. `adb logcat`（实时日志）
2. `adb bugreport`（完整状态）
3. `adb shell dumpsys SurfaceFlinger`（显示相关）

### 场景4：开机引导卡死

**推荐方法：**
1. ⭐ **串口日志**（看卡在哪个阶段）
2. `adb logcat`（如果能连上）
3. `adb shell ps -A`（查看进程状态）

---

## 🛠️ 实用工具脚本

### 自动抓取fastboot信息

创建脚本 `capture_fastboot_info.sh`：

```bash
#!/bin/bash

# Fastboot信息抓取脚本
OUTPUT_DIR="fastboot_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "开始抓取fastboot信息..."
echo "输出目录: $OUTPUT_DIR"

# 检测设备
echo -e "\n=== 检测设备 ===" | tee "$OUTPUT_DIR/devices.txt"
fastboot devices | tee -a "$OUTPUT_DIR/devices.txt"

# 获取所有变量
echo -e "\n=== 获取所有变量 ===" | tee "$OUTPUT_DIR/getvar_all.txt"
fastboot getvar all 2>&1 | tee -a "$OUTPUT_DIR/getvar_all.txt"

# 获取关键变量
for var in version product serialno secure unlocked current-slot slot-count; do
    echo -e "\n=== $var ===" | tee -a "$OUTPUT_DIR/key_vars.txt"
    fastboot getvar $var 2>&1 | tee -a "$OUTPUT_DIR/key_vars.txt"
done

# 小米特殊命令
echo -e "\n=== 小米设备信息 ===" | tee "$OUTPUT_DIR/miui_info.txt"
fastboot oem device-info 2>&1 | tee -a "$OUTPUT_DIR/miui_info.txt"
fastboot oem get-bootinfo 2>&1 | tee -a "$OUTPUT_DIR/miui_info.txt"

echo -e "\n完成！日志保存在: $OUTPUT_DIR"
```

使用方法：
```bash
chmod +x capture_fastboot_info.sh
./capture_fastboot_info.sh
```

### 串口日志带时间戳

```bash
#!/bin/bash
# 串口日志记录脚本（带时间戳）

SERIAL_PORT="/dev/ttyUSB0"
BAUD_RATE="115200"
LOG_FILE="uart_log_$(date +%Y%m%d_%H%M%S).txt"

echo "开始记录串口日志..."
echo "串口: $SERIAL_PORT"
echo "波特率: $BAUD_RATE"
echo "日志文件: $LOG_FILE"

# 使用picocom记录
sudo picocom -b $BAUD_RATE $SERIAL_PORT -g "$LOG_FILE"
```

---

## 📝 日志分析关键点

### Fastboot getvar all 关键字段

```bash
# 设备基本信息
product: marble              # 产品代号
serialno: 1234567890        # 序列号

# 启动相关
current-slot: a             # 当前slot
slot-count: 2              # 支持A/B
unlocked: yes              # 是否解锁

# 分区状态
partition-size:boot: 0x6000000
partition-type:boot: raw
has-slot:boot: yes

# 安全状态
secure: no                 # secure boot状态
```

### 串口日志关键阶段

```
[0.0] PBL（Primary Bootloader）- 最底层
  ↓
[0.x] SBL（Secondary Bootloader）
  ↓
[1.x] ABL/LK（Android Bootloader/Little Kernel）
  ↓
[2.x] Kernel启动
  ↓
[3.x] Init进程
  ↓
[4.x] Zygote/SystemServer
  ↓
[5.x] Launcher启动
```

### 常见错误标识

| 错误信息 | 含义 | 阶段 |
|---------|------|------|
| `Unable to load image` | 镜像加载失败 | Bootloader |
| `Kernel panic` | 内核崩溃 | Kernel |
| `init: cannot find '/init'` | init进程缺失 | Init |
| `FAILED (remote: ...)` | fastboot命令失败 | Fastboot |
| `Fastboot mode started` | 正常进入fastboot | Bootloader |

---

## 🔍 常见问题排查

### Q1: fastboot devices显示为空

**解决方法：**
```bash
# 检查USB连接
lsusb | grep -i qualcomm
lsusb | grep -i mediatek

# 检查fastboot版本
fastboot --version

# 尝试sudo权限
sudo fastboot devices

# 更新udev规则
sudo vim /etc/udev/rules.d/51-android.rules
# 添加：SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
sudo udevadm control --reload-rules
```

### Q2: 串口无输出

**检查清单：**
- [ ] 波特率是否正确（尝试115200、921600）
- [ ] TX/RX是否接反
- [ ] 串口线是否正常（用万用表测试）
- [ ] 串口工具权限（sudo或加入dialout组）
- [ ] 设备是否有串口输出（部分用户版本关闭）

### Q3: Recovery模式adb连不上

**解决方法：**
```bash
# 等待设备
adb wait-for-recovery

# 重启adb服务
sudo adb kill-server
sudo adb start-server

# 检查recovery是否支持adb
# 部分recovery默认不开启adb
```

---

## 📚 参考资料

- Android官方文档：[Bootloader开发](https://source.android.com/devices/bootloader)
- Fastboot协议：[Fastboot Protocol](https://android.googlesource.com/platform/system/core/+/master/fastboot/README.md)
- 小米解锁工具：[unlock.update.miui.com](http://www.miui.com/unlock/index.html)

---

## 📌 最佳实践总结

### 日志采集优先级

1. **⭐⭐⭐ 串口日志** - 最完整，适合严重启动问题
2. **⭐⭐ fastboot getvar all** - 快速诊断，了解设备状态
3. **⭐⭐ bugreport** - 系统能启动时的完整信息
4. **⭐ Recovery日志** - 中间方案

### 记录规范

每次采集日志时记录：
- ✅ 时间戳（采集时间）
- ✅ 设备型号和ROM版本
- ✅ 操作步骤（复现步骤）
- ✅ 问题现象描述
- ✅ 环境信息（PC系统、工具版本）

### 日志保存结构

```
问题单号_日期/
├── fastboot_info/
│   ├── getvar_all.txt
│   ├── devices.txt
│   └── oem_info.txt
├── uart_logs/
│   ├── uart_boot_1.txt
│   ├── uart_boot_2.txt
│   └── uart_boot_3.txt
├── bugreport/
│   └── bugreport.zip
└── README.md (问题描述)
```

---

**文档版本**: v1.0  
**更新时间**: 2025-10-14  
**适用范围**: MiuiProvisionAosp 及相关Android系统调试
