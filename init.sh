#!/bin/bash
set -euo pipefail

# Signal handling for graceful shutdown
cleanup() {
    echo "[INFO] Received shutdown signal, stopping server..."
    if [ -n "${SERVER_PID:-}" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# ============================================
# Unturned 服务器初始化脚本
# ============================================

# 设置时区（优先使用环境变量，否则使用默认值）
export TZ="${TZ:-Asia/Shanghai}"
if [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime 2>/dev/null || true
    echo "$TZ" > /etc/timezone 2>/dev/null || true
    echo "[INFO] Timezone set to: $TZ"
else
    echo "[WARNING] Timezone file not found: /usr/share/zoneinfo/$TZ"
fi

GAME_DIR="${GAME_INSTALL_DIR:-/home/steam/Unturned}"
STEAMCMD_DIR="${STEAMCMD_DIR:-/home/steam/steamcmd}"
SERVER_TYPE="${SERVER_TYPE:-empty}"
SERVER_NAME="${SERVER_NAME:-server}"

echo "[INFO] ==========================================="
echo "[INFO] Unturned Server Initialization"
echo "[INFO] ==========================================="
echo "[INFO] Game directory: $GAME_DIR"
echo "[INFO] SteamCMD directory: $STEAMCMD_DIR"
echo "[INFO] Server name: $SERVER_NAME"
echo "[INFO] Server type: $SERVER_TYPE"
echo "[INFO] ==========================================="

# 确保游戏目录存在并设置权限
if ! mkdir -p "$GAME_DIR" 2>/dev/null; then
    echo "[ERROR] Failed to create game directory: $GAME_DIR"
    exit 1
fi

# 设置目录权限（如果可能）
if [ -w "$(dirname "$GAME_DIR")" ]; then
    chown steam:steam "$GAME_DIR" 2>/dev/null || true
fi

# 检查游戏是否已安装
if [ ! -f "$GAME_DIR/Unturned_Headless.x86_64" ]; then
    echo "[INFO] Game not found, installing Unturned for the first time..."
    
    # 切换到SteamCMD目录
    cd "$STEAMCMD_DIR"
    
    # 安装游戏
    echo "[INFO] Installing Unturned (App ID: $GAME_ID)..."
    if ! ./steamcmd.sh \
        +force_install_dir "$GAME_DIR" \
        +login anonymous \
        +app_update $GAME_ID validate \
        +quit; then
        echo "[ERROR] SteamCMD installation failed"
        exit 1
    fi
    
    echo "[INFO] Installation completed successfully"
else
    echo "[INFO] Game found, checking for updates..."
    
    # 切换到SteamCMD目录进行更新
    cd "$STEAMCMD_DIR"
    
    # 更新游戏
    echo "[INFO] Updating Unturned..."
    if ! ./steamcmd.sh \
        +force_install_dir "$GAME_DIR" \
        +login anonymous \
        +app_update $GAME_ID validate \
        +quit; then
        echo "[WARNING] Update failed, continuing with current version"
    fi
fi

# 设置Steam SDK
mkdir -p /home/steam/.steam/sdk64/
if [ -f "$GAME_DIR/linux64/steamclient.so" ]; then
    cp -f "$GAME_DIR/linux64/steamclient.so" /home/steam/.steam/sdk64/steamclient.so
    echo "[INFO] Steam SDK configured"
fi

# 切换到游戏目录
cd "$GAME_DIR" || exit 1

echo "[INFO] Changed to game directory: $(pwd)"

# 提高文件描述符限制
ulimit -n 2048
export TERM=xterm

# 设置插件库路径
if [ -d "./Unturned_Headless_Data" ]; then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/Unturned_Headless_Data/Plugins/x86_64/"
    echo "[INFO] Set LD_LIBRARY_PATH for Unturned_Headless_Data"
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/Unturned_Headless/Plugins/x86_64/"
    echo "[INFO] Set LD_LIBRARY_PATH for Unturned_Headless"
fi

# 确保可执行权限
chmod +x ./Unturned_Headless.x86_64

# RocketMod 安装（如果需要）
if [ "$SERVER_TYPE" == "rm4" ]; then
    echo "[INFO] Setting up RocketMod..."
    if [ -d "./Extras/Rocket.Unturned" ] && [ ! -d "./Modules/Rocket.Unturned" ]; then
        echo "[INFO] Installing RocketMod..."
        mkdir -p "./Modules"
        cp -rf "./Extras/Rocket.Unturned/" "./Modules/"
        echo "[INFO] RocketMod installed successfully"
    elif [ ! -d "./Extras/Rocket.Unturned" ]; then
        echo "[WARNING] RocketMod requested but Extras/Rocket.Unturned not found"
    fi
fi

# 创建服务器配置目录
# 重要：确保服务器配置目录存在，即使为空也会被使用
mkdir -p "./Servers/$SERVER_NAME"
echo "[INFO] Server configuration directory created: ./Servers/$SERVER_NAME"

# 如果服务器配置目录为空，从 Default 目录复制基础配置（如果存在）
if [ -d "./Servers/Default" ] && [ -z "$(ls -A ./Servers/$SERVER_NAME 2>/dev/null)" ]; then
    echo "[INFO] Server directory is empty, copying base configuration from Default..."
    # 复制 Default 目录的内容（但不包括 Default 目录本身）
    cp -r ./Servers/Default/* ./Servers/$SERVER_NAME/ 2>/dev/null || true
    echo "[INFO] Base configuration copied to ./Servers/$SERVER_NAME"
fi

# 启动服务器
echo "[INFO] ==========================================="
echo "[INFO] Starting Unturned server"
echo "[INFO] Server name: $SERVER_NAME"
echo "[INFO] Server type: ${SERVER_TYPE:-vanilla}"
echo "[INFO] ==========================================="

# 验证可执行文件存在
if [ ! -f "./Unturned_Headless.x86_64" ]; then
    echo "[ERROR] Unturned_Headless.x86_64 not found!"
    echo "[ERROR] Please check game installation."
    exit 1
fi

# 构建启动参数
SERVER_ARGS="-batchmode -nographics -logfile /dev/stdout"

# 添加服务器名称参数
# 重要：必须指定服务器名称，否则 Unturned 会使用 Default 目录
if [ -n "$SERVER_NAME" ]; then
    SERVER_ARGS="$SERVER_ARGS +secureserver/$SERVER_NAME"
    echo "[INFO] Server will use configuration from: ./Servers/$SERVER_NAME"
else
    echo "[WARNING] SERVER_NAME not set, server will use Default configuration"
fi

# 显示启动信息
echo "[INFO] Executable: ./Unturned_Headless.x86_64"
echo "[INFO] Arguments: $SERVER_ARGS"
echo "[INFO] Working directory: $(pwd)"
echo "[INFO] ==========================================="
echo ""

# Start server in background to allow signal handling
./Unturned_Headless.x86_64 $SERVER_ARGS &
SERVER_PID=$!

# Wait for server process
wait $SERVER_PID