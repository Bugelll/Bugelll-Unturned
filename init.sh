#!/bin/bash
set -e

GAME_DIR="$GAME_INSTALL_DIR"
STEAMCMD_DIR="/home/steam/steamcmd"

# 检查游戏目录是否为空（首次运行）
if [ ! -f "$GAME_DIR/Unturned_Headless.x86_64" ]; then
    echo "[INFO] Game directory is empty, installing Unturned for the first time..."
    echo "[INFO] Game directory: $GAME_DIR"
    echo "[INFO] SteamCMD directory: $STEAMCMD_DIR"
    
    # 显示当前目录和权限
    echo "[INFO] Current directory: $(pwd)"
    echo "[INFO] Game directory contents before installation:"
    ls -la "$GAME_DIR" 2>/dev/null || echo "[WARNING] Cannot access game directory"
    
    # 切换到steamcmd目录进行安装
    cd "$STEAMCMD_DIR"
    
    echo "[INFO] Starting SteamCMD installation..."
    echo "[INFO] SteamCMD directory contents:"
    ls -la
    
    # 检查steamcmd.sh是否存在
    if [ ! -f "./steamcmd.sh" ]; then
        echo "[ERROR] steamcmd.sh not found!"
        exit 1
    fi
    
    # 运行SteamCMD安装，增加错误检查
    if ! ./steamcmd.sh \
        +force_install_dir "$GAME_DIR" \
        +login anonymous \
        +app_update 1110390 validate \
        +quit; then
        echo "[ERROR] SteamCMD installation failed!"
        echo "[INFO] Game directory contents after failed installation:"
        ls -la "$GAME_DIR" 2>/dev/null || echo "[WARNING] Cannot access game directory"
        exit 1
    fi
    
    echo "[INFO] SteamCMD installation command completed"
    
    # 检查安装结果
    echo "[INFO] Game directory contents after installation:"
    ls -la "$GAME_DIR"
    
    # 检查关键文件
    if [ ! -f "$GAME_DIR/Unturned_Headless.x86_64" ]; then
        echo "[ERROR] Unturned_Headless.x86_64 not found after installation!"
        echo "[INFO] Looking for any Unturned files:"
        find "$GAME_DIR" -name "*Unturned*" -type f 2>/dev/null || echo "[WARNING] No Unturned files found"
        exit 1
    fi
    
    # 设置Steam SDK
    mkdir -p /home/steam/.steam/sdk64/
    if [ -f "$GAME_DIR/linux64/steamclient.so" ]; then
        cp -f "$GAME_DIR/linux64/steamclient.so" /home/steam/.steam/sdk64/steamclient.so
        echo "[INFO] Steam SDK copied successfully"
    else
        echo "[WARNING] Steam SDK file not found: $GAME_DIR/linux64/steamclient.so"
    fi
    
    echo "[INFO] Unturned installation completed successfully"
else
    echo "[INFO] Game directory already contains Unturned files"
fi

# 切换到游戏目录
cd "$GAME_DIR" || exit 1

echo "[INFO] Changed to game directory: $(pwd)"
echo "[INFO] Current directory contents:"
ls -la

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

# 检查并更新 Unturned
echo "[INFO] Checking for Unturned updates..."
if ! $STEAMCMD_DIR/steamcmd.sh \
    +force_install_dir "$GAME_DIR" \
    +login anonymous \
    +app_update 1110390 validate \
    +quit; then
    echo "[WARNING] Update check failed, continuing with current version"
fi

# 验证游戏文件
if [ ! -f "./Unturned_Headless.x86_64" ]; then
    echo "[ERROR] Unturned_Headless.x86_64 not found!"
    echo "[INFO] Listing game directory contents:"
    ls -la
    echo "[INFO] Checking for alternative executables:"
    find . -name "*Unturned*" -type f -executable 2>/dev/null || true
    exit 1
fi

echo "[INFO] Unturned_Headless.x86_64 found, continuing..."

# 确保可执行权限
chmod +x ./Unturned_Headless.x86_64

echo "[INFO] File permissions set"

# RocketMod 安装（如果需要）
if [ "$SERVER_TYPE" == "rm4" ]; then
    echo "[INFO] Checking RocketMod installation..."
    if [ -d "./Extras/Rocket.Unturned" ] && [ ! -d "./Modules/Rocket.Unturned" ]; then
        echo "[INFO] Installing RocketMod..."
        mkdir -p "./Modules"
        cp -rf "./Extras/Rocket.Unturned/" "./Modules/"
        echo "[INFO] RocketMod installed successfully"
    elif [ "$SERVER_TYPE" == "rm4" ] && [ ! -d "./Extras/Rocket.Unturned" ]; then
        echo "[WARNING] RocketMod requested but Extras/Rocket.Unturned not found"
        echo "[INFO] Available extras:"
        ls -la ./Extras/ 2>/dev/null || echo "No Extras directory found"
    fi
fi

# 创建服务器配置目录
mkdir -p "./Servers/$SERVER_NAME"
echo "[INFO] Server configuration directory created: ./Servers/$SERVER_NAME"

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
echo "[INFO] Final directory contents before startup:"
ls -la

exec ./Unturned_Headless.x86_64 $SERVER_ARGS