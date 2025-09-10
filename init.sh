#!/bin/bash
set -e

GAME_DIR="$GAME_INSTALL_DIR"
STEAMCMD_DIR="/home/steam/steamcmd"

echo "[INFO] Starting Unturned server setup..."
echo "[INFO] Game directory: $GAME_DIR"
echo "[INFO] SteamCMD directory: $STEAMCMD_DIR"

# 确保游戏目录存在并设置权限
mkdir -p "$GAME_DIR"
chown steam:steam "$GAME_DIR"

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
mkdir -p "./Servers/$SERVER_NAME"
echo "[INFO] Server configuration directory created: ./Servers/$SERVER_NAME"

# 启动服务器
echo "[INFO] Starting Unturned server: $SERVER_NAME"
echo "[INFO] Server type: ${SERVER_TYPE:-vanilla}"

# 启动参数
SERVER_ARGS="-batchmode -nographics -logfile /dev/stdout"
if [ -n "$SERVER_NAME" ]; then
    SERVER_ARGS="$SERVER_ARGS +secureserver/$SERVER_NAME"
fi

echo "[INFO] Starting with args: $SERVER_ARGS"
exec ./Unturned_Headless.x86_64 $SERVER_ARGS