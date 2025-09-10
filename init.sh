#!/bin/bash
set -e

GAME_DIR="$GAME_INSTALL_DIR"
STEAMCMD_DIR="/home/steam/steamcmd"

# 检查游戏目录是否为空（首次运行）
if [ ! -f "$GAME_DIR/Unturned_Headless.x86_64" ]; then
    echo "[INFO] Game directory is empty, installing Unturned for the first time..."
    # 切换到steamcmd目录进行安装
    cd "$STEAMCMD_DIR"
    ./steamcmd.sh \
        +login anonymous \
        +force_install_dir "$GAME_DIR" \
        +app_update 1110390 validate \
        +quit
    
    # 设置Steam SDK
    mkdir -p /home/steam/.steam/sdk64/
    if [ -f "$GAME_DIR/linux64/steamclient.so" ]; then
        cp -f "$GAME_DIR/linux64/steamclient.so" /home/steam/.steam/sdk64/steamclient.so
    fi
    
    echo "[INFO] Unturned installation completed"
fi

# 切换到游戏目录
cd "$GAME_DIR" || exit 1

# 提高文件描述符限制
ulimit -n 2048
export TERM=xterm

# 设置插件库路径
if [ -d "./Unturned_Headless_Data" ]; then
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/Unturned_Headless_Data/Plugins/x86_64/"
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/Unturned_Headless/Plugins/x86_64/"
fi

# 检查并更新 Unturned
echo "[INFO] Checking for Unturned updates..."
$STEAMCMD_DIR/steamcmd.sh \
    +login anonymous \
    +force_install_dir "$GAME_DIR" \
    +app_update 1110390 validate \
    +quit

# 验证游戏文件
if [ ! -f "./Unturned_Headless.x86_64" ]; then
    echo "[ERROR] Unturned_Headless.x86_64 not found!"
    echo "[INFO] Listing game directory contents:"
    ls -la
    echo "[INFO] Checking for alternative executables:"
    find . -name "*Unturned*" -type f -executable 2>/dev/null || true
    exit 1
fi

# 确保可执行权限
chmod +x ./Unturned_Headless.x86_64

# RocketMod 安装（如果需要）
if [ "$SERVER_TYPE" == "rm4" ]; then
    echo "[INFO] Checking RocketMod installation..."
    if [ -d "./Extras/Rocket.Unturned" ] && [ ! -d "./Modules/Rocket.Unturned" ]; then
        echo "[INFO] Installing RocketMod..."
        mkdir -p "./Modules"
        cp -rf "./Extras/Rocket.Unturned/" "./Modules/"
    elif [ "$SERVER_TYPE" == "rm4" ] && [ ! -d "./Extras/Rocket.Unturned" ]; then
        echo "[WARNING] RocketMod requested but Extras/Rocket.Unturned not found"
        echo "[INFO] Available extras:"
        ls -la ./Extras/ 2>/dev/null || echo "No Extras directory found"
    fi
fi

# 创建服务器配置目录
mkdir -p "./Servers/$SERVER_NAME"

# 启动服务器
echo "[INFO] Starting Unturned server: $SERVER_NAME"
echo "[INFO] Server type: ${SERVER_TYPE:-vanilla}"
echo "[INFO] Game directory: $GAME_DIR"

# 启动参数
SERVER_ARGS="-batchmode -nographics -logfile /dev/stdout"
if [ -n "$SERVER_NAME" ]; then
    SERVER_ARGS="$SERVER_ARGS +secureserver/$SERVER_NAME"
fi

echo "[INFO] Starting with args: $SERVER_ARGS"
exec ./Unturned_Headless.x86_64 $SERVER_ARGS