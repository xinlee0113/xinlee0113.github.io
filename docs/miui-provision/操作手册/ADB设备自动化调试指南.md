---
layout: default
title: ADB设备自动化调试指南
parent: MiuiProvision项目文档
---

# ADB设备自动化调试指南

## 📋 文档信息
- **版本**: v1.0
- **创建日期**: 2025-10-24
- **适用范围**: MiuiProvisionAosp开机引导模块
- **目标**: 通过ADB + AI视觉识别实现设备自动化调试

---

## 🎯 应用场景

1. **Jira问题复现**: 根据问题描述自动复现用户操作流程
2. **代码修改验证**: 修改代码后自动验证修复效果
3. **回归测试**: 自动化执行完整的开机引导流程测试
4. **问题分析**: 逐步截图记录，结合日志定位问题根因

---

## 🔧 环境准备

### 1. 检查ADB连接

```bash
# 检查设备连接状态
adb devices

# 预期输出
List of devices attached
e229623c	device
```

**状态说明**:
- `device`: 设备正常连接
- `unauthorized`: 需要在设备上授权
- `offline`: 设备离线，需要重新连接
- `no device`: 未检测到设备

### 2. 获取设备信息

```bash
# 获取屏幕分辨率
adb shell wm size
# 输出: Physical size: 1280x2772

# 获取屏幕密度
adb shell wm density
# 输出: Physical density: 440

# 获取设备型号
adb shell getprop ro.product.model

# 获取Android版本
adb shell getprop ro.build.version.release

# 获取系统版本号
adb shell getprop ro.build.display.id
```

### 3. 创建工作目录

```bash
# 在项目根目录下创建日志和截图目录
cd /mnt/01_lixin_workspace/master-w/packages/apps/MiuiProvisionAosp
mkdir -p logs/screenshots
mkdir -p logs/ui_dumps
mkdir -p logs/bugreports
```

---

## 📱 核心操作流程

### 流程图

```
┌─────────────┐
│ 1.截取屏幕  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2.AI识别页面│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3.Dump UI树 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4.定位元素  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 5.执行操作  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 6.验证结果  │
└──────┬──────┘
       │
       ▼ 循环
```

---

## 📸 第一步：截取屏幕

### 基础截图命令

```bash
# 方法1：截图并拉取（分步执行）
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png logs/screenshots/screen_$(date +%Y%m%d_%H%M%S).png

# 方法2：带时间戳的截图（推荐）
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
adb shell screencap -p /sdcard/screen.png && \
adb pull /sdcard/screen.png logs/screenshots/step_${TIMESTAMP}.png 2>&1 | grep pulled

# 方法3：快速截图（覆盖当前）
adb shell screencap -p /sdcard/screen.png && \
adb pull /sdcard/screen.png logs/current_screen.png 2>&1 | tail -1
```

### 截图最佳实践

```bash
# 1. 操作前截图
adb shell screencap -p /sdcard/before.png
adb pull /sdcard/before.png logs/before_click.png

# 2. 执行操作
adb shell input tap 640 2553

# 3. 等待动画完成后截图
sleep 2
adb shell screencap -p /sdcard/after.png
adb pull /sdcard/after.png logs/after_click.png
```

### 处理截图错误

```bash
# 如果出现 FORTIFY 错误提示，可以忽略，文件通常已成功生成
# FORTIFY: pthread_mutex_destroy called on a destroyed mutex (0x...)
# 这是Android系统的调试信息，不影响截图功能

# 验证截图是否成功
adb shell ls -lh /sdcard/screen.png
```

---

## 🔍 第二步：页面识别（UI Dump优先）

### ⚡ 推荐方式：UI Dump（高效）

**原理**：直接解析UI层次结构XML，速度快、精度高、零token消耗

```bash
# 1. 导出UI结构
adb shell uiautomator dump

# 2. 拉取XML文件
adb pull /sdcard/window_dump.xml /tmp/ui.xml

# 3. 快速解析页面信息
grep 'provision_title' /tmp/ui.xml | grep -oP 'text="\K[^"]*'  # 页面标题
grep 'checked="true"' /tmp/ui.xml | grep -oP 'text="\K[^"]*'   # 当前选中项
grep 'text="Next"' /tmp/ui.xml | grep -oP 'bounds="\K[^\]]*'  # Next按钮坐标
```

**优势对比**：

| 指标 | UI Dump | 截图+AI识别 |
|------|---------|------------|
| 速度 | ~0.2秒 | ~3秒 |
| 文件大小 | ~15KB | ~200KB |
| 坐标精度 | 100%精确 | 估算 |
| Token消耗 | 0 | ~1500/张 |
| 效率提升 | 基准 | **15x slower** |

### 🖼️ 备用方式：截图识别（可视化）

**使用场景**：
- 需要保留问题证据
- 分析UI渲染问题
- 视觉效果验证

**操作步骤**：

```bash
# 截图
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png logs/screenshot.png

# 使用Cursor的read_file工具读取截图
# AI会自动识别页面内容
```

**AI识别结果示例**:
```
页面: 语言选择页
标题: "Choose language"
当前选中: "English (United States)"
可操作元素:
  - 底部"Next"按钮
  - 返回按钮（左上角）
  - 语言列表（可滚动）
```

### 🎯 混合策略（推荐）

```bash
# 日常自动化：只用UI Dump（效率优先）
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml /tmp/ui.xml
# ... 解析并操作 ...

# 关键节点：UI Dump + 截图（证据保留）
adb shell uiautomator dump
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/window_dump.xml logs/stepXX.xml &
adb pull /sdcard/screen.png logs/stepXX.png &
wait
```

---

## 🌲 第三步：导出UI树结构

### UI Dump命令

```bash
# 导出UI层次结构到XML
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml logs/ui_dumps/ui_$(date +%Y%m%d_%H%M%S).xml

# 快速查看当前页面标题
adb shell uiautomator dump && \
adb pull /sdcard/window_dump.xml logs/ui_current.xml 2>&1 | grep pulled
```

### 解析UI XML获取元素信息

```bash
# 查找按钮元素
grep -oP 'class="android.widget.Button"[^>]+' logs/ui_current.xml

# 查找文本内容
grep -oP 'text="[^"]*"' logs/ui_current.xml | head -10

# 查找特定resource-id
grep -oP 'resource-id="com.android.provision:id/[^"]*"' logs/ui_current.xml | sort -u

# 提取元素bounds坐标
grep -oP 'resource-id="com.android.provision:id/group_primary_button".*?bounds="\[([0-9,\[\]]+)\]"' logs/ui_current.xml
```

### UI元素结构示例

```xml
<node 
  text="Next" 
  resource-id="com.android.provision:id/group_primary_button" 
  class="android.widget.Button" 
  clickable="true" 
  enabled="true" 
  bounds="[104,2473][1175,2632]"
/>
```

**关键属性说明**:
- `text`: 显示文本
- `resource-id`: 资源ID（最可靠的定位方式）
- `class`: 控件类型
- `clickable`: 是否可点击
- `enabled`: 是否启用
- `bounds`: 边界坐标 [left,top][right,bottom]

---

## 🎯 第四步：定位元素坐标

### 计算中心点坐标

从bounds `[left,top][right,bottom]` 计算中心点：

```bash
# 示例: bounds="[104,2473][1175,2632]"
# 中心点 X = (104 + 1175) / 2 = 640
# 中心点 Y = (2473 + 2632) / 2 = 2553
```

### 自动提取坐标脚本

```bash
# 提取指定resource-id的中心坐标
function get_element_center() {
    local resource_id=$1
    local xml_file=${2:-logs/ui_current.xml}
    
    # 提取bounds
    bounds=$(grep -oP "resource-id=\"${resource_id}\".*?bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\"" "$xml_file")
    
    if [ -n "$bounds" ]; then
        # 解析并计算中心点
        left=$(echo "$bounds" | grep -oP '\[(\d+),' | grep -oP '\d+' | head -1)
        top=$(echo "$bounds" | grep -oP ',(\d+)\]' | grep -oP '\d+' | head -1)
        right=$(echo "$bounds" | grep -oP '\]\[(\d+),' | grep -oP '\d+')
        bottom=$(echo "$bounds" | grep -oP ',(\d+)\]' | grep -oP '\d+' | tail -1)
        
        center_x=$(( (left + right) / 2 ))
        center_y=$(( (top + bottom) / 2 ))
        
        echo "${center_x} ${center_y}"
    fi
}

# 使用示例
get_element_center "com.android.provision:id/group_primary_button"
# 输出: 640 2553
```

---

## 🖱️ 第五步：执行操作

### 1. 点击操作

```bash
# 基础点击
adb shell input tap <x> <y>

# 示例：点击Next按钮
adb shell input tap 640 2553

# 长按（3秒）
adb shell input swipe <x> <y> <x> <y> 3000
```

### 2. 滑动操作

```bash
# 基础滑动: swipe <x1> <y1> <x2> <y2> [duration_ms]
adb shell input swipe 640 2000 640 1000 300

# 向上滚动列表
adb shell input swipe 640 2000 640 1000 300

# 向下滚动列表
adb shell input swipe 640 1000 640 2000 300

# 向左滑动（返回手势）
adb shell input swipe 100 1386 900 1386 300

# 向右滑动
adb shell input swipe 900 1386 100 1386 300
```

### 3. 文本输入

```bash
# 输入英文文本
adb shell input text "Hello"

# 输入带空格的文本（需要转义）
adb shell input text "Hello%sWorld"

# 清除输入框（先聚焦，再全选，再删除）
adb shell input tap <x> <y>
adb shell input keyevent KEYCODE_MOVE_END
adb shell input keyevent --longpress KEYCODE_DEL

# 输入中文（需要先设置输入法，建议使用UI Automator）
# 或者通过剪贴板
adb shell am broadcast -a clipper.set -e text "中文内容"
adb shell input keyevent KEYCODE_PASTE
```

### 4. 按键操作

```bash
# 常用按键
adb shell input keyevent KEYCODE_BACK          # 返回键
adb shell input keyevent KEYCODE_HOME          # Home键
adb shell input keyevent KEYCODE_MENU          # 菜单键
adb shell input keyevent KEYCODE_ENTER         # 回车键
adb shell input keyevent KEYCODE_DEL           # 删除键
adb shell input keyevent KEYCODE_DPAD_UP       # 方向上
adb shell input keyevent KEYCODE_DPAD_DOWN     # 方向下
adb shell input keyevent KEYCODE_VOLUME_UP     # 音量+
adb shell input keyevent KEYCODE_VOLUME_DOWN   # 音量-
adb shell input keyevent KEYCODE_POWER         # 电源键

# 组合键（同时按下音量下+电源键截图）
adb shell input keyevent --longpress KEYCODE_VOLUME_DOWN & \
adb shell input keyevent KEYCODE_POWER
```

### 5. 应用控制

```bash
# 启动开机引导
adb shell am start -n com.android.provision/.DefaultActivity

# 强制停止应用
adb shell am force-stop com.android.provision

# 清除应用数据
adb shell pm clear com.android.provision

# 重启开机引导（清除数据后启动）
adb shell pm clear com.android.provision && \
adb shell am start -n com.android.provision/.DefaultActivity
```

---

## ✅ 第六步：验证操作结果

### 1. 验证页面跳转

```bash
# 操作前dump
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/before.xml

# 执行操作
adb shell input tap 640 2553

# 等待跳转
sleep 2

# 操作后dump
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/after.xml

# 对比页面变化
diff logs/before.xml logs/after.xml
```

### 2. 验证元素状态

```bash
# 检查元素是否存在
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/ui_current.xml
grep "resource-id=\"com.android.provision:id/next_button\"" logs/ui_current.xml

# 检查元素是否可点击
grep "resource-id=\"com.android.provision:id/next_button\".*clickable=\"true\"" logs/ui_current.xml
```

### 3. 获取当前Activity

```bash
# 获取当前运行的Activity
adb shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'

# 输出示例:
# mCurrentFocus=Window{12345 u0 com.android.provision/com.android.provision.DefaultActivity}
```

---

## 📊 完整操作示例

### 示例1：自动完成语言和地区选择

```bash
#!/bin/bash
# 脚本: auto_select_language_region.sh

echo "=== 开始自动化测试 ==="

# 1. 截取初始页面
echo "[1/6] 截取初始页面..."
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png logs/screenshots/01_initial.png

# 2. Dump UI获取Next按钮坐标
echo "[2/6] 获取UI结构..."
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/ui_dumps/01_language.xml

# 3. 点击Next按钮（语言选择页）
echo "[3/6] 点击Next按钮（语言选择）..."
adb shell input tap 640 2553
sleep 2

# 4. 截取地区选择页
echo "[4/6] 截取地区选择页..."
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png logs/screenshots/02_region.png

# 5. Dump地区选择页UI
echo "[5/6] 获取地区选择页UI..."
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/ui_dumps/02_region.xml

# 6. 点击Next按钮（地区选择页）
echo "[6/6] 点击Next按钮（地区选择）..."
adb shell input tap 640 2553
sleep 2

echo "=== 测试完成 ==="
```

### 示例2：根据Jira问题复现流程

```bash
#!/bin/bash
# 脚本: reproduce_jira_issue.sh
# 用途: 复现BUGOS2-XXXXXX问题

ISSUE_ID="BUGOS2-716698"
LOG_DIR="logs/issues/${ISSUE_ID}"

mkdir -p "${LOG_DIR}/screenshots"
mkdir -p "${LOG_DIR}/ui_dumps"

echo "=== 复现问题: ${ISSUE_ID} ==="

# 1. 重置应用状态
echo "[1] 重置应用..."
adb shell pm clear com.android.provision
adb shell am start -n com.android.provision/.DefaultActivity
sleep 3

# 2. 进入Quick Start流程
echo "[2] 选择语言..."
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png "${LOG_DIR}/screenshots/step1_language.png"
adb shell input tap 640 2553  # Next
sleep 2

echo "[3] 选择地区..."
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png "${LOG_DIR}/screenshots/step2_region.png"
adb shell input tap 640 2553  # Next
sleep 2

echo "[4] Quick Start页面..."
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png "${LOG_DIR}/screenshots/step3_quickstart.png"
# 点击"从以前的设备恢复数据"
adb shell input tap 640 1500
sleep 2

# ... 继续复现问题的具体步骤 ...

# 最后采集bugreport
echo "[最后] 采集日志..."
adb bugreport "${LOG_DIR}/bugreport.zip"

echo "=== 复现完成，日志保存在: ${LOG_DIR} ==="
```

---

## 🔍 日志采集

### 1. 采集Bugreport

```bash
# 完整bugreport（推荐）
adb bugreport logs/bugreports/bugreport_$(date +%Y%m%d_%H%M%S).zip

# 实时查看日志（调试用）
adb logcat | tee logs/logcat_$(date +%Y%m%d_%H%M%S).log
```

### 2. 过滤特定日志

```bash
# 只看MiuiProvision的日志
adb logcat | grep -E "Provision|provision"

# 过滤错误和警告
adb logcat *:E *:W

# 过滤特定TAG
adb logcat -s MiuiProvision:V

# 清除日志缓冲区
adb logcat -c
```

### 3. 采集Tombstone（崩溃日志）

```bash
# 查看tombstone列表
adb shell ls -lt /data/tombstones/

# 拉取最新的tombstone
adb pull /data/tombstones/ logs/tombstones/
```

---

## 🐛 故障排查

### 问题1: 设备未授权

```bash
# 现象
$ adb devices
List of devices attached
e229623c	unauthorized

# 解决方法
1. 在设备上允许USB调试授权
2. 如果设备屏幕锁定，解锁后重试
3. 撤销授权后重新连接：
   adb kill-server
   adb start-server
   adb devices
```

### 问题2: 截图失败或图片损坏

```bash
# 如果出现FORTIFY错误，但文件存在
# 可以忽略错误信息，直接拉取文件

# 验证文件完整性
adb shell ls -lh /sdcard/screen.png
# 如果文件大小 > 0，说明截图成功

# 清理设备上的临时文件
adb shell rm /sdcard/screen.png
adb shell rm /sdcard/ui.xml
adb shell rm /sdcard/window_dump.xml
```

### 问题3: 找不到元素

```bash
# 检查当前页面所有可点击元素
adb shell uiautomator dump
adb pull /sdcard/window_dump.xml logs/debug.xml
grep 'clickable="true"' logs/debug.xml

# 检查元素resource-id
grep 'resource-id="com.android.provision' logs/debug.xml | \
  grep -oP 'resource-id="[^"]*"' | sort -u
```

### 问题4: 操作无响应

```bash
# 检查应用是否ANR
adb shell dumpsys activity | grep -A 5 "ANR"

# 检查应用是否在前台
adb shell dumpsys window | grep mCurrentFocus

# 强制停止并重启
adb shell am force-stop com.android.provision
adb shell am start -n com.android.provision/.DefaultActivity
```

---

## 📝 最佳实践

### 1. 操作间隔

```bash
# 点击后等待页面加载（推荐2-3秒）
adb shell input tap 640 2553
sleep 2

# 输入后等待输入法响应
adb shell input text "test"
sleep 1

# 滑动后等待列表加载
adb shell input swipe 640 2000 640 1000 300
sleep 1
```

### 2. 错误处理

```bash
# 添加操作验证
adb shell input tap 640 2553
if [ $? -eq 0 ]; then
    echo "点击成功"
    sleep 2
else
    echo "点击失败"
    exit 1
fi
```

### 3. 日志记录

```bash
# 记录每个操作步骤
log_step() {
    local step_num=$1
    local description=$2
    echo "[$(date +%H:%M:%S)] Step ${step_num}: ${description}"
}

log_step 1 "点击Next按钮"
adb shell input tap 640 2553
```

### 4. 截图命名规范

```bash
# 建议命名格式: {序号}_{页面名称}_{操作}.png
# 示例:
01_language_initial.png      # 语言选择页初始状态
02_language_after_click.png  # 点击后状态
03_region_initial.png        # 地区选择页初始状态
```

---

## 🚀 高级技巧（快捷脚本）

### 🎯 快速部署：一键安装ADB工具函数

将以下代码添加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
# ============= ADB自动化工具集 =============
# 作者: Cursor AI Assistant
# 版本: v1.0
# 用途: 提升Android自动化调试效率15倍

# 1. 快速UI Dump
adb_dump() {
    adb shell uiautomator dump > /dev/null 2>&1
    adb pull /sdcard/window_dump.xml /tmp/ui_current.xml > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ UI dumped to /tmp/ui_current.xml"
    else
        echo "❌ UI dump failed"
        return 1
    fi
}

# 2. 获取页面标题
adb_title() {
    adb_dump
    local title=$(grep -oP 'provision_title.*?text="\K[^"]*' /tmp/ui_current.xml 2>/dev/null)
    if [ -n "$title" ]; then
        echo "📄 页面标题: $title"
    else
        echo "❌ 未找到页面标题"
    fi
}

# 3. 查找元素（by text）
adb_find_text() {
    local text=$1
    if [ -z "$text" ]; then
        echo "用法: adb_find_text <文本内容>"
        return 1
    fi
    
    adb_dump
    grep "text=\"${text}\"" /tmp/ui_current.xml | grep -oP 'bounds="\[\K[^\]]*' | while read bounds; do
        # 解析 left,top][right,bottom
        echo "$bounds" | awk -F',' '{
            left=$1; 
            gsub(/[^0-9]/, "", left);
            top=$2; 
            gsub(/\]\[/, " ", $0);
            split($0, arr, " ");
            split(arr[2], arr2, ",");
            right=arr2[1];
            bottom=arr2[2];
            gsub(/[^0-9]/, "", right);
            gsub(/[^0-9]/, "", bottom);
            x=int((left+right)/2);
            y=int((top+bottom)/2);
            printf "🎯 text=\"%s\" 坐标: (%d, %d)\n", "'"$text"'", x, y;
        }'
    done
}

# 4. 查找元素（by resource-id）
adb_find_id() {
    local res_id=$1
    if [ -z "$res_id" ]; then
        echo "用法: adb_find_id <resource-id>"
        return 1
    fi
    
    adb_dump
    grep "resource-id=\"${res_id}\"" /tmp/ui_current.xml | grep -oP 'bounds="\[\K[^\]]*' | while read bounds; do
        echo "$bounds" | awk -F',' '{
            left=$1; 
            gsub(/[^0-9]/, "", left);
            top=$2;
            gsub(/\]\[/, " ", $0);
            split($0, arr, " ");
            split(arr[2], arr2, ",");
            right=arr2[1];
            bottom=arr2[2];
            gsub(/[^0-9]/, "", right);
            gsub(/[^0-9]/, "", bottom);
            x=int((left+right)/2);
            y=int((top+bottom)/2);
            printf "🎯 resource-id=\"%s\" 坐标: (%d, %d)\n", "'"$res_id"'", x, y;
        }'
    done
}

# 5. 点击文本元素
adb_tap_text() {
    local text=$1
    if [ -z "$text" ]; then
        echo "用法: adb_tap_text <文本内容>"
        return 1
    fi
    
    adb_dump
    local coords=$(grep "text=\"${text}\"" /tmp/ui_current.xml | grep -oP 'bounds="\[\K[^\]]*' | head -1 | awk -F',' '{
        left=$1; 
        gsub(/[^0-9]/, "", left);
        top=$2;
        gsub(/\]\[/, " ", $0);
        split($0, arr, " ");
        split(arr[2], arr2, ",");
        right=arr2[1];
        bottom=arr2[2];
        gsub(/[^0-9]/, "", right);
        gsub(/[^0-9]/, "", bottom);
        x=int((left+right)/2);
        y=int((top+bottom)/2);
        printf "%d %d", x, y;
    }')
    
    if [ -n "$coords" ]; then
        echo "👆 点击 \"$text\" at $coords"
        adb shell input tap $coords
    else
        echo "❌ 未找到文本: $text"
        return 1
    fi
}

# 6. 点击resource-id元素
adb_tap_id() {
    local res_id=$1
    if [ -z "$res_id" ]; then
        echo "用法: adb_tap_id <resource-id>"
        return 1
    fi
    
    adb_dump
    local coords=$(grep "resource-id=\"${res_id}\"" /tmp/ui_current.xml | grep -oP 'bounds="\[\K[^\]]*' | head -1 | awk -F',' '{
        left=$1; 
        gsub(/[^0-9]/, "", left);
        top=$2;
        gsub(/\]\[/, " ", $0);
        split($0, arr, " ");
        split(arr[2], arr2, ",");
        right=arr2[1];
        bottom=arr2[2];
        gsub(/[^0-9]/, "", right);
        gsub(/[^0-9]/, "", bottom);
        x=int((left+right)/2);
        y=int((top+bottom)/2);
        printf "%d %d", x, y;
    }')
    
    if [ -n "$coords" ]; then
        echo "👆 点击 resource-id=\"$res_id\" at $coords"
        adb shell input tap $coords
    else
        echo "❌ 未找到 resource-id: $res_id"
        return 1
    fi
}

# 7. 获取当前选中项
adb_selected() {
    adb_dump
    local selected=$(grep 'checked="true"' /tmp/ui_current.xml | grep -oP 'text="\K[^"]*' | head -1)
    if [ -n "$selected" ]; then
        echo "✅ 当前选中: $selected"
    else
        selected=$(grep 'selected="true"' /tmp/ui_current.xml | grep -oP 'text="\K[^"]*' | head -1)
        if [ -n "$selected" ]; then
            echo "✅ 当前选中: $selected"
        else
            echo "ℹ️  未找到选中项"
        fi
    fi
}

# 8. 列出所有可点击元素
adb_clickable() {
    adb_dump
    echo "🖱️  可点击元素列表："
    grep 'clickable="true"' /tmp/ui_current.xml | grep -oP '(text="\K[^"]*|resource-id="\K[^"]*)' | \
    grep -v '^$' | sort -u | head -20
}

# 9. 快照当前页面（UI Dump + 截图）
adb_snapshot() {
    local name=${1:-"snapshot_$(date +%Y%m%d_%H%M%S)"}
    local dir="logs/snapshots"
    mkdir -p "$dir"
    
    echo "📸 正在快照..."
    adb shell uiautomator dump > /dev/null 2>&1
    adb shell screencap -p /sdcard/screen.png > /dev/null 2>&1
    adb pull /sdcard/window_dump.xml "${dir}/${name}.xml" > /dev/null 2>&1 &
    adb pull /sdcard/screen.png "${dir}/${name}.png" > /dev/null 2>&1 &
    wait
    
    if [ -f "${dir}/${name}.xml" ] && [ -f "${dir}/${name}.png" ]; then
        echo "✅ 快照保存成功:"
        echo "   XML: ${dir}/${name}.xml"
        echo "   PNG: ${dir}/${name}.png"
    else
        echo "❌ 快照保存失败"
        return 1
    fi
}

# 10. 显示帮助信息
adb_help() {
    cat << 'EOF'
🤖 ADB自动化工具集 - 使用指南

基础工具:
  adb_dump          - 导出UI结构到 /tmp/ui_current.xml
  adb_title         - 显示当前页面标题
  adb_selected      - 显示当前选中项
  adb_clickable     - 列出所有可点击元素

查找元素:
  adb_find_text <text>     - 查找文本元素并显示坐标
  adb_find_id <resource-id> - 查找ID元素并显示坐标

操作元素:
  adb_tap_text <text>      - 点击文本元素
  adb_tap_id <resource-id>  - 点击ID元素

快照工具:
  adb_snapshot [name]      - 保存UI Dump + 截图（可选名称）

示例用法:
  adb_find_text "Next"                          # 查找Next按钮
  adb_tap_text "Next"                           # 点击Next按钮
  adb_tap_id "com.android.provision:id/next"   # 通过ID点击
  adb_snapshot "step1_language"                 # 保存快照

EOF
}

# 安装完成提示
echo "✅ ADB自动化工具集已加载! 输入 'adb_help' 查看使用指南"
```

**安装步骤**：

```bash
# 1. 编辑配置文件
nano ~/.bashrc  # 或 ~/.zshrc

# 2. 将上述代码复制到文件末尾

# 3. 重新加载配置
source ~/.bashrc  # 或 source ~/.zshrc

# 4. 验证安装
adb_help
```

---

### 🎮 快捷脚本使用示例

#### 示例1：查找并点击Next按钮

```bash
# 方法1：查找坐标
$ adb_find_text "Next"
🎯 text="Next" 坐标: (640, 2553)

# 方法2：直接点击
$ adb_tap_text "Next"
👆 点击 "Next" at 640 2553
```

#### 示例2：查看当前页面信息

```bash
$ adb_title
📄 页面标题: Choose language

$ adb_selected  
✅ 当前选中: English (United States)

$ adb_clickable
🖱️  可点击元素列表：
Next
Back
English (United Kingdom)
English (United States)
...
```

#### 示例3：自动化流程

```bash
# 完整的自动化流程示例
adb_snapshot "step1_start"           # 保存初始状态
adb_tap_text "Next"                  # 点击Next
sleep 2
adb_snapshot "step2_after_next"      # 保存下一页
adb_title                            # 查看页面标题
```

---

### 🔧 传统方式（手动解析）

如果不想使用脚本工具，也可以手动操作：

#### 1. 查找文本元素坐标

```bash
# 在UI dump中搜索文本并提取坐标
function find_text_element() {
    local text=$1
    adb shell uiautomator dump
    adb pull /sdcard/window_dump.xml /tmp/ui.xml 2>&1 > /dev/null
    grep -oP "text=\"${text}\".*?bounds=\"\[[0-9,\[\]]+\]\"" /tmp/ui.xml
}

# 使用示例
find_text_element "Next"
```

### 2. 等待元素出现

```bash
# 轮询等待元素出现（最多等待10秒）
function wait_for_element() {
    local resource_id=$1
    local timeout=10
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        adb shell uiautomator dump > /dev/null 2>&1
        adb pull /sdcard/window_dump.xml /tmp/ui.xml 2>&1 > /dev/null
        
        if grep -q "resource-id=\"${resource_id}\"" /tmp/ui.xml; then
            echo "元素已出现"
            return 0
        fi
        
        sleep 1
        elapsed=$((elapsed + 1))
    done
    
    echo "超时：元素未出现"
    return 1
}

# 使用示例
wait_for_element "com.android.provision:id/next_button"
```

### 3. 屏幕录制

```bash
# 开始录制（最长180秒）
adb shell screenrecord /sdcard/test_recording.mp4 &
RECORD_PID=$!

# 执行测试操作
# ...

# 停止录制
kill $RECORD_PID

# 拉取视频
adb pull /sdcard/test_recording.mp4 logs/videos/
```

---

## 📚 参考资料

### ADB官方文档
- [Android Debug Bridge (adb)](https://developer.android.com/studio/command-line/adb)
- [UI/Application Exerciser Monkey](https://developer.android.com/studio/test/monkey)

### 常用命令速查表

| 操作 | 命令 |
|------|------|
| 截图 | `adb shell screencap -p /sdcard/screen.png` |
| UI Dump | `adb shell uiautomator dump` |
| 点击 | `adb shell input tap <x> <y>` |
| 滑动 | `adb shell input swipe <x1> <y1> <x2> <y2> <duration>` |
| 输入文本 | `adb shell input text "text"` |
| 按键 | `adb shell input keyevent <keycode>` |
| 启动应用 | `adb shell am start -n <package>/<activity>` |
| 停止应用 | `adb shell am force-stop <package>` |
| 清除数据 | `adb shell pm clear <package>` |
| Bugreport | `adb bugreport <path>` |
| Logcat | `adb logcat` |

---

## 🔄 工作流程集成

### 1. Jira问题处理流程

```
1. 访问Jira，查看问题描述和复现步骤
   ↓
2. 根据描述编写自动化复现脚本
   ↓
3. 执行脚本，采集截图和日志
   ↓
4. AI分析截图，定位问题页面和操作
   ↓
5. 分析日志，找到根本原因
   ↓
6. 修改代码
   ↓
7. 重新执行脚本，验证修复效果
   ↓
8. 对比修复前后的截图和日志
   ↓
9. 更新Jira，提供分析文档
```

### 2. 自动化测试脚本模板

参考: `scripts/build_and_install.sh` 中的构建流程

```bash
#!/bin/bash
# 完整的测试流程脚本

set -e  # 遇到错误立即退出

PROJECT_ROOT="/mnt/01_lixin_workspace/master-w/packages/apps/MiuiProvisionAosp"
cd "$PROJECT_ROOT"

# 1. 编译并安装APK
echo "=== 编译并安装 ==="
./scripts/build_and_install.sh

# 2. 重启应用
echo "=== 重启应用 ==="
adb shell pm clear com.android.provision
adb shell am start -n com.android.provision/.DefaultActivity
sleep 3

# 3. 执行自动化测试
echo "=== 执行自动化测试 ==="
# ... 添加具体的测试步骤 ...

# 4. 采集日志
echo "=== 采集日志 ==="
adb bugreport logs/test_result_$(date +%Y%m%d_%H%M%S).zip

echo "=== 测试完成 ==="
```

---

## 📌 附录

### 常见页面resource-id清单

| 页面 | 主要resource-id | 说明 |
|------|----------------|------|
| 语言选择 | `provision_title` | 页面标题 |
| | `android:id/list` | 语言列表 |
| | `group_primary_button` | Next按钮 |
| 地区选择 | `search_input` | 搜索框 |
| | `item_view` | 地区选项 |
| WiFi连接 | `wifi_list` | WiFi列表 |
| | `skip_button` | 跳过按钮 |
| 账号登录 | `login_input` | 登录输入框 |
| | `skip_or_later` | 跳过按钮 |

### 屏幕坐标参考（1280x2772）

| 位置 | 坐标 (x, y) | 说明 |
|------|------------|------|
| 屏幕中心 | (640, 1386) | 中心点 |
| 返回按钮 | (128, 249) | 左上角 |
| Next按钮 | (640, 2553) | 底部中央 |
| 列表中部 | (640, 1500) | 列表项目 |

---

## 📝 变更日志

### v1.0 (2025-10-24)
- 初始版本
- 包含完整的ADB操作流程
- 添加问题复现和验证流程
- 提供自动化脚本模板

---

**文档维护人**: Cursor AI Assistant  
**最后更新**: 2025-10-24
