---
layout: default
title: 源码分析工具集
parent: 开发工具
nav_order: 2
---

#!/bin/bash
# Android源码分析工具集
# 使用说明：source 源码分析工具集.sh

ANDROID_ROOT="/mnt/01_lixin_workspace/master-w"
WORKSPACE_ROOT="/mnt/01_lixin_workspace"
OUTPUT_DIR="$WORKSPACE_ROOT/output"
LOG_DIR="$OUTPUT_DIR/analysis_logs"
DIAGRAM_DIR="$OUTPUT_DIR/diagrams"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 初始化分析环境
init_analysis_env() {
    echo -e "${GREEN}初始化Android源码分析环境...${NC}"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$DIAGRAM_DIR"
    
    # 设置环境变量
    export ANDROID_ROOT="$ANDROID_ROOT"
    export PATH=$PATH:$ANDROID_ROOT/prebuilts/jdk/jdk11/linux-x86/bin
    
    echo -e "${GREEN}✓ 环境初始化完成${NC}"
    echo -e "  输出目录: $OUTPUT_DIR"
    echo -e "  日志目录: $LOG_DIR"
    echo -e "  图表目录: $DIAGRAM_DIR"
}

# 搜索类定义
find_class() {
    local class_name=$1
    if [ -z "$class_name" ]; then
        echo -e "${RED}用法: find_class <类名>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}搜索类: $class_name${NC}"
    find "$ANDROID_ROOT" -name "*.java" -o -name "*.kt" | xargs grep -l "class $class_name"
}

# 搜索方法定义
find_method() {
    local method_name=$1
    if [ -z "$method_name" ]; then
        echo -e "${RED}用法: find_method <方法名>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}搜索方法: $method_name${NC}"
    find "$ANDROID_ROOT/frameworks" -name "*.java" | xargs grep -n "^\s*.*\s$method_name\s*("
}

# 搜索AIDL接口
find_aidl() {
    local aidl_name=$1
    if [ -z "$aidl_name" ]; then
        echo -e "${RED}用法: find_aidl <接口名>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}搜索AIDL接口: $aidl_name${NC}"
    find "$ANDROID_ROOT" -name "*.aidl" | xargs grep -l "interface $aidl_name"
}

# 搜索系统服务
find_system_service() {
    local service_name=$1
    if [ -z "$service_name" ]; then
        echo "系统服务列表："
        grep -r "ServiceManager.addService" "$ANDROID_ROOT/frameworks/base/services/java/com/android/server/SystemServer.java" | grep -o '"[^"]*"' | sort -u
        return 0
    fi
    
    echo -e "${BLUE}搜索系统服务: $service_name${NC}"
    grep -r "addService.*$service_name" "$ANDROID_ROOT/frameworks/base/services"
}

# 分析Activity启动流程
analyze_activity_start() {
    echo -e "${YELLOW}=== Activity启动流程关键文件 ===${NC}"
    
    local files=(
        "frameworks/base/core/java/android/app/Activity.java"
        "frameworks/base/core/java/android/app/ActivityThread.java"
        "frameworks/base/core/java/android/app/Instrumentation.java"
        "frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java"
        "frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$ANDROID_ROOT/$file" ]; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${RED}✗${NC} $file (不存在)"
        fi
    done
    
    echo -e "\n${YELLOW}核心方法调用链：${NC}"
    echo "1. Activity.startActivity()"
    echo "2. Instrumentation.execStartActivity()"
    echo "3. ActivityTaskManager.getService().startActivity()"
    echo "4. ActivityTaskManagerService.startActivity()"
    echo "5. ActivityStarter.execute()"
    echo "6. ActivityThread.handleLaunchActivity()"
    echo "7. Activity.onCreate()"
}

# 分析Binder机制
analyze_binder() {
    echo -e "${YELLOW}=== Binder IPC机制关键文件 ===${NC}"
    
    local files=(
        "frameworks/base/core/java/android/os/Binder.java"
        "frameworks/base/core/java/android/os/IBinder.java"
        "frameworks/base/core/java/android/os/ServiceManager.java"
        "frameworks/native/libs/binder/Binder.cpp"
        "frameworks/native/libs/binder/BpBinder.cpp"
        "frameworks/native/libs/binder/IPCThreadState.cpp"
        "kernel/drivers/android/binder.c"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$ANDROID_ROOT/$file" ]; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${RED}✗${NC} $file"
        fi
    done
    
    echo -e "\n${YELLOW}Binder架构层次：${NC}"
    echo "┌─────────────────────────────────┐"
    echo "│  Application (Client/Server)    │"
    echo "├─────────────────────────────────┤"
    echo "│  Java Binder (IBinder/Binder)   │"
    echo "├─────────────────────────────────┤"
    echo "│  JNI Layer                      │"
    echo "├─────────────────────────────────┤"
    echo "│  Native Binder (BpBinder/BBinder)│"
    echo "├─────────────────────────────────┤"
    echo "│  Binder Driver (/dev/binder)    │"
    echo "└─────────────────────────────────┘"
}

# 分析SystemServer启动
analyze_system_server() {
    echo -e "${YELLOW}=== SystemServer启动流程 ===${NC}"
    
    local system_server_file="$ANDROID_ROOT/frameworks/base/services/java/com/android/server/SystemServer.java"
    
    if [ -f "$system_server_file" ]; then
        echo -e "${GREEN}SystemServer.java 位置:${NC}"
        echo "  $system_server_file"
        
        echo -e "\n${YELLOW}启动的核心服务：${NC}"
        grep "startService\|startBootstrapServices\|startCoreServices\|startOtherServices" "$system_server_file" | grep -v "//" | head -20
        
        echo -e "\n${YELLOW}启动阶段 (BOOT_PHASE):${NC}"
        echo "  PHASE_WAIT_FOR_DEFAULT_DISPLAY = 100"
        echo "  PHASE_LOCK_SETTINGS_READY = 480"
        echo "  PHASE_SYSTEM_SERVICES_READY = 500"
        echo "  PHASE_ACTIVITY_MANAGER_READY = 550"
        echo "  PHASE_THIRD_PARTY_APPS_CAN_START = 600"
        echo "  PHASE_BOOT_COMPLETED = 1000"
    else
        echo -e "${RED}SystemServer.java 文件不存在${NC}"
    fi
}

# 生成模块依赖图
generate_module_deps() {
    echo -e "${BLUE}生成模块依赖关系...${NC}"
    
    local output_file="$DIAGRAM_DIR/module_dependencies.dot"
    
    cat > "$output_file" << 'EOF'
digraph AndroidModules {
    rankdir=TB;
    node [shape=box, style=rounded];
    
    // 应用层
    subgraph cluster_apps {
        label="Applications";
        style=filled;
        color=lightgrey;
        Launcher Settings Phone Contacts;
    }
    
    // Framework层
    subgraph cluster_framework {
        label="Android Framework";
        style=filled;
        color=lightblue;
        ActivityManagerService;
        PackageManagerService;
        WindowManagerService;
        PowerManagerService;
    }
    
    // Native层
    subgraph cluster_native {
        label="Native Services";
        style=filled;
        color=lightgreen;
        SurfaceFlinger;
        AudioFlinger;
        MediaServer;
    }
    
    // HAL层
    subgraph cluster_hal {
        label="Hardware Abstraction Layer";
        style=filled;
        color=lightyellow;
        CameraHAL;
        AudioHAL;
        SensorHAL;
    }
    
    // Kernel层
    subgraph cluster_kernel {
        label="Linux Kernel";
        style=filled;
        color=lightpink;
        BinderDriver;
        Drivers;
    }
    
    // 依赖关系
    Launcher -> ActivityManagerService;
    Settings -> PackageManagerService;
    ActivityManagerService -> SurfaceFlinger;
    WindowManagerService -> SurfaceFlinger;
    SurfaceFlinger -> BinderDriver;
    AudioFlinger -> AudioHAL;
    CameraHAL -> Drivers;
}
EOF
    
    echo -e "${GREEN}✓ 依赖图已生成: $output_file${NC}"
    echo -e "使用以下命令生成图片："
    echo -e "  ${BLUE}dot -Tpng $output_file -o $DIAGRAM_DIR/module_dependencies.png${NC}"
}

# 追踪方法调用链
trace_method_calls() {
    local class_name=$1
    local method_name=$2
    
    if [ -z "$class_name" ] || [ -z "$method_name" ]; then
        echo -e "${RED}用法: trace_method_calls <类名> <方法名>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}追踪方法调用: $class_name.$method_name()${NC}"
    
    # 查找类文件
    local class_file=$(find "$ANDROID_ROOT" -name "${class_name}.java" | head -1)
    
    if [ -z "$class_file" ]; then
        echo -e "${RED}找不到类: $class_name${NC}"
        return 1
    fi
    
    echo -e "${GREEN}类文件: $class_file${NC}"
    
    # 提取方法实现
    echo -e "\n${YELLOW}方法实现:${NC}"
    sed -n "/${method_name}\s*(/,/^    }/p" "$class_file" | head -50
}

# 编译单个模块
build_module() {
    local module_path=$1
    
    if [ -z "$module_path" ]; then
        echo -e "${RED}用法: build_module <模块路径>${NC}"
        echo -e "示例: build_module frameworks/base/services"
        return 1
    fi
    
    echo -e "${BLUE}编译模块: $module_path${NC}"
    
    cd "$ANDROID_ROOT" || return 1
    source build/envsetup.sh
    
    echo -e "${YELLOW}执行: mmm $module_path${NC}"
    mmm "$module_path"
}

# 查看系统服务状态
dump_system_service() {
    local service_name=$1
    
    if [ -z "$service_name" ]; then
        echo -e "${YELLOW}可用的系统服务:${NC}"
        adb shell service list
        return 0
    fi
    
    echo -e "${BLUE}Dump系统服务: $service_name${NC}"
    adb shell dumpsys "$service_name" | tee "$LOG_DIR/dumpsys_${service_name}_$(date +%Y%m%d_%H%M%S).log"
}

# 显示帮助信息
show_help() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Android源码分析工具集 - 使用指南                    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}【初始化】${NC}"
    echo -e "  ${BLUE}init_analysis_env${NC}                 - 初始化分析环境"
    echo ""
    echo -e "${YELLOW}【代码搜索】${NC}"
    echo -e "  ${BLUE}find_class <类名>${NC}                - 搜索Java/Kotlin类"
    echo -e "  ${BLUE}find_method <方法名>${NC}              - 搜索方法定义"
    echo -e "  ${BLUE}find_aidl <接口名>${NC}               - 搜索AIDL接口"
    echo -e "  ${BLUE}find_system_service [服务名]${NC}     - 搜索/列出系统服务"
    echo ""
    echo -e "${YELLOW}【流程分析】${NC}"
    echo -e "  ${BLUE}analyze_activity_start${NC}           - 分析Activity启动流程"
    echo -e "  ${BLUE}analyze_binder${NC}                   - 分析Binder IPC机制"
    echo -e "  ${BLUE}analyze_system_server${NC}            - 分析SystemServer启动"
    echo -e "  ${BLUE}trace_method_calls <类名> <方法名>${NC} - 追踪方法调用链"
    echo ""
    echo -e "${YELLOW}【图表生成】${NC}"
    echo -e "  ${BLUE}generate_module_deps${NC}             - 生成模块依赖图"
    echo ""
    echo -e "${YELLOW}【编译调试】${NC}"
    echo -e "  ${BLUE}build_module <模块路径>${NC}          - 编译单个模块"
    echo -e "  ${BLUE}dump_system_service [服务名]${NC}     - Dump系统服务状态"
    echo ""
    echo -e "${YELLOW}【示例命令】${NC}"
    echo -e "  ${GREEN}find_class ActivityManagerService${NC}"
    echo -e "  ${GREEN}analyze_activity_start${NC}"
    echo -e "  ${GREEN}trace_method_calls Activity onCreate${NC}"
    echo -e "  ${GREEN}build_module frameworks/base/services${NC}"
    echo -e "  ${GREEN}dump_system_service activity${NC}"
    echo ""
}

# 导出函数
export -f init_analysis_env
export -f find_class
export -f find_method
export -f find_aidl
export -f find_system_service
export -f analyze_activity_start
export -f analyze_binder
export -f analyze_system_server
export -f generate_module_deps
export -f trace_method_calls
export -f build_module
export -f dump_system_service
export -f show_help

# 启动时显示帮助
echo -e "${GREEN}Android源码分析工具集已加载${NC}"
echo -e "输入 ${BLUE}show_help${NC} 查看所有可用命令"

