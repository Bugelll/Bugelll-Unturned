# Bugelll-Unturned Docker

[English](#english) | [中文](#中文)

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

3. **IMPORTANT**: Set correct permissions for the data directory:
```bash
sudo mkdir -p ./unturned_data
sudo chown -R 1000:1000 ./unturned_data
```
   *Note: 1000:1000 is the UID/GID of the steam user inside the container*

4. Start the server using docker-compose:
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

**IMPORTANT**: Before mounting volumes, ensure the host directory has correct permissions:
```bash
sudo mkdir -p /path/to/your/data
sudo chown -R 1000:1000 /path/to/your/data
```
*Note: The steam user inside the container has UID/GID 1000:1000. Incorrect permissions will cause installation failures.*

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

3. **重要**：为数据目录设置正确的权限：
```bash
sudo mkdir -p ./unturned_data
sudo chown -R 1000:1000 ./unturned_data
```
   *注意：1000:1000 是容器内steam用户的UID/GID*

4. 使用docker-compose启动服务器：
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

**重要**：在挂载卷之前，确保主机目录具有正确的权限：
```bash
sudo mkdir -p /path/to/your/data
sudo chown -R 1000:1000 /path/to/your/data
```
*注意：容器内的steam用户UID/GID为1000:1000。权限不正确将导致安装失败。*

### 端口配置

**重要**：端口映射在 `docker-compose.yml` 中配置，Dockerfile 中不再声明 EXPOSE。

你可以根据需要修改端口映射：

```yaml
ports:
  - "34567:27015/udp"   # 宿主机端口:容器端口
  - "34568:27016/udp"
```

容器内端口（27015-27016）是 Unturned 默认端口，宿主机端口可以根据需要自由配置。

### 故障排除
- 确保Docker和docker-compose已正确安装
- 检查端口是否被占用
- **权限问题**：确保挂载目录的所有者为1000:1000（容器内steam用户）
  ```bash
  sudo chown -R 1000:1000 /path/to/mount/directory
  ```
- 验证卷挂载路径的权限设置
- 查看容器日志：`docker logs unturned-server`

**常见问题**：
- 如果游戏目录为空或安装失败，首先检查目录权限
- 确保挂载目录存在且具有正确的所有者权限
- 使用 `ls -la /path/to/directory` 检查权限

### 项目优化

本项目已进行以下优化：
- ✅ 移除 Dockerfile 中的 EXPOSE 声明，端口映射完全由 docker-compose.yml 控制
- ✅ 添加 procps 包支持健康检查
- ✅ 改进错误处理和日志输出
- ✅ 添加详细的中文注释

详见 [OPTIMIZATION.md](OPTIMIZATION.md)

### 许可证
本项目采用MIT许可证 - 详见 [LICENSE](LICENSE) 文件