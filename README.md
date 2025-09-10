# Bugelll-Unturned Docker

[English](#english) | [中文](#chinese)

## English

This repository contains Docker scripts for hosting an Unturned game server with automatic updates and crash recovery. It supports RocketMod modules and provides both Docker and non-Docker installation methods.

### Features
- 🚀 Automatic game download and updates
- 🔄 Crash detection and auto-restart
- 📦 RocketMod 4/5 support
- 🐳 Docker containerization
- 🌐 Full console input/output support

### Quick Start with Docker

1. Clone this repository:
```bash
git clone https://github.com/Bugelll/Bugelll-Unturned.git
cd Bugelll-Unturned
```

2. Build the Docker image:
```bash
docker build . -t bugelll-unturned
```

3. Start the server using docker-compose:
```bash
docker-compose up -d
```

Or run manually:
```bash
docker run -d \
  -v ./unturned_data:/home/steam/Unturned \
  -p 27015:27015/udp \
  -p 27016:27016/udp \
  -e SERVER_TYPE=rm4 \
  --restart unless-stopped \
  --name unturned-server \
  bugelll-unturned
```

### Server Types
The following are supported for the `SERVER_TYPE` environment variable:
- `rm4` - Installs RocketMod 4 module
- `rm5` - Installs RocketMod 5 module
- `empty` - No modules installed (vanilla server)

### Environment Variables
- `SERVER_TYPE`: RocketMod version (rm4/rm5/empty)
- `STEAMCMD_ARGS`: Additional SteamCMD commands
- `GAME_DIR`: Game installation directory (default: /home/steam/Unturned)
- `STEAMCMD_DIR`: SteamCMD installation directory (default: /home/steam/steamcmd)

### Non-Docker Installation

1. Install dependencies:
```bash
sudo apt-get install -y unzip tar curl coreutils lib32gcc1 libgdiplus
```

2. Set environment variables:
```bash
export GAME_INSTALL_DIR=/path/to/Unturned
export SERVER_NAME=YOUR_SERVER_NAME
export GAME_ID=1110390
export SERVER_TYPE=rm4
```

3. Run the initialization script:
```bash
chmod +x init.sh
./init.sh
```

### Volume Mounting
The container supports full directory mounting for data persistence:
- `./unturned_data:/home/steam/Unturned` - Game files and server data
- The script automatically checks for empty directories and installs game files if needed

---

## 中文

本仓库包含用于托管Unturned游戏服务器的Docker脚本，支持自动更新和崩溃恢复。它支持RocketMod模块，并提供Docker和非Docker安装方式。

### 功能特性
- 🚀 自动游戏下载和更新
- 🔄 崩溃检测和自动重启
- 📦 RocketMod 4/5 支持
- 🐳 Docker容器化
- 🌐 完整的控制台输入/输出支持

### Docker快速开始

1. 克隆此仓库：
```bash
git clone https://github.com/Bugelll/Bugelll-Unturned.git
cd Bugelll-Unturned
```

2. 构建Docker镜像：
```bash
docker build . -t bugelll-unturned
```

3. 使用docker-compose启动服务器：
```bash
docker-compose up -d
```

或手动运行：
```bash
docker run -d \
  -v ./unturned_data:/home/steam/Unturned \
  -p 27015:27015/udp \
  -p 27016:27016/udp \
  -e SERVER_TYPE=rm4 \
  --restart unless-stopped \
  --name unturned-server \
  bugelll-unturned
```

### 服务器类型
`SERVER_TYPE`环境变量支持以下选项：
- `rm4` - 安装RocketMod 4模块
- `rm5` - 安装RocketMod 5模块
- `empty` - 不安装任何模块（原版服务器）

### 环境变量
- `SERVER_TYPE`: RocketMod版本 (rm4/rm5/empty)
- `STEAMCMD_ARGS`: 额外的SteamCMD命令
- `GAME_DIR`: 游戏安装目录 (默认: /home/steam/Unturned)
- `STEAMCMD_DIR`: SteamCMD安装目录 (默认: /home/steam/steamcmd)

### 非Docker安装

1. 安装依赖：
```bash
sudo apt-get install -y unzip tar curl coreutils lib32gcc1 libgdiplus
```

2. 设置环境变量：
```bash
export GAME_INSTALL_DIR=/path/to/Unturned
export SERVER_NAME=你的服务器名称
export GAME_ID=1110390
export SERVER_TYPE=rm4
```

3. 运行初始化脚本：
```bash
chmod +x init.sh
./init.sh
```

### 卷挂载
容器支持完整目录挂载以实现数据持久化：
- `./unturned_data:/home/steam/Unturned` - 游戏文件和服务器数据
- 脚本会自动检查空目录并在需要时安装游戏文件

### 故障排除
- 确保Docker和docker-compose已正确安装
- 检查端口27015和27016是否被占用
- 验证卷挂载路径的权限设置
- 查看容器日志：`docker logs unturned-server`

### 许可证
本项目采用MIT许可证 - 详见 [LICENSE](LICENSE) 文件