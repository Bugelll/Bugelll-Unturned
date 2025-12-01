# 故障排除指南

## Docker 镜像拉取失败

### 问题症状

常见错误包括：
```
short read: expected 29536798 bytes but got 0: unexpected EOF
429 Too Many Requests
403 Forbidden
failed to resolve reference
```

### 原因

1. 网络连接不稳定
2. Docker Hub 镜像仓库问题
3. Docker 镜像缓存损坏
4. **镜像加速器限制**：某些镜像加速器不支持特定镜像或请求过于频繁（429/403 错误）
5. **镜像不存在**：镜像可能不存在于 Docker Hub 或加速器中

### 解决方案

#### 方案 1：直接使用 Docker Hub（推荐，解决 429/403 错误）

如果遇到 429 Too Many Requests 或 403 Forbidden 错误，通常是镜像加速器的问题。可以临时禁用加速器，直接使用 Docker Hub：

```bash
# 1. 备份当前配置
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak 2>/dev/null || true

# 2. 临时禁用镜像加速器（注释掉或删除 registry-mirrors）
sudo nano /etc/docker/daemon.json
# 将 registry-mirrors 注释掉或删除，或者改为空数组：
# {
#   "registry-mirrors": []
# }

# 3. 重启 Docker 服务
sudo systemctl restart docker

# 4. 直接拉取镜像（使用 Docker Hub）
docker pull emqo/bugelll-unturned:latest

# 5. 启动容器
docker compose up -d
```

**或者临时使用 Docker Hub 官方地址**：

```bash
# 直接指定使用 Docker Hub
docker pull docker.io/emqo/bugelll-unturned:latest
docker compose up -d
```

#### 方案 2：清理缓存并重试拉取

如果必须使用远程镜像：

```bash
# 清理 Docker 系统缓存
docker system prune -a --volumes

# 清理特定镜像
docker rmi emqo/bugelll-unturned:latest 2>/dev/null || true

# 等待一段时间（避免 429 错误）
sleep 60

# 重试拉取
docker compose pull
docker compose up -d
```

#### 方案 3：使用镜像加速器（如果方案 1 失败）

如果在中国大陆，可以配置 Docker 镜像加速器：

1. 编辑 `/etc/docker/daemon.json`：
   ```json
   {
     "registry-mirrors": [
       "https://docker.mirrors.ustc.edu.cn",
       "https://hub-mirror.c.163.com"
     ]
   }
   ```

2. 重启 Docker 服务：
   ```bash
   sudo systemctl restart docker
   ```

3. 重新拉取镜像：
   ```bash
   docker compose pull
   docker compose up -d
   ```

#### 方案 4：使用本地构建（如果远程拉取持续失败）

如果远程镜像拉取持续失败，可以临时改为本地构建：

1. 修改 `docker-compose.yml`，将 `image` 改为 `build`：
   ```yaml
   services:
     Bugelll-Unturned-1:
       build:
         context: .
         dockerfile: Dockerfile
       image: bugelll-unturned:latest
   ```

2. 本地构建并启动：
   ```bash
   docker compose build
   docker compose up -d
   ```

## 容器启动失败

### 检查容器日志

```bash
docker logs Bugelll-Unturned-1
docker logs Bugelll-Unturned-2
```

### 检查容器状态

```bash
docker compose ps
```

### 常见问题

1. **端口冲突**：确保端口 34567-34568 和 35678-35679 未被占用
2. **权限问题**：确保数据目录权限正确
3. **网络问题**：检查 Docker 网络配置

## SERVER_NAME 配置问题

如果服务器仍使用 `Default` 或 `server` 目录：

1. **确认环境变量**：
   ```bash
   docker exec Bugelll-Unturned-1 env | grep SERVER_NAME
   ```

2. **重新创建容器**（环境变量在创建时设置）：
   ```bash
   docker compose down
   docker compose up -d
   ```

3. **验证配置**：
   ```bash
   docker logs Bugelll-Unturned-1 | grep "Server name"
   ```

详细说明请参考 [FIX_SERVER_NAME.md](./FIX_SERVER_NAME.md)

## 网络问题

### 检查 Docker 网络

```bash
docker network ls
docker network inspect unturned-net
```

### 重新创建网络

```bash
docker compose down
docker network rm unturned-net 2>/dev/null || true
docker compose up -d
```

## 数据目录问题

### 检查数据目录权限

```bash
ls -la /data/Unturned/UnturnedData1
ls -la /data/Unturned/UnturnedData2
```

### 修复权限

```bash
sudo chown -R 1000:1000 /data/Unturned/UnturnedData1
sudo chown -R 1000:1000 /data/Unturned/UnturnedData2
```

## 构建失败

### 清理构建缓存

```bash
docker compose build --no-cache
```

### 检查 Dockerfile

确保 `Dockerfile` 和 `init.sh` 文件存在且可读：

```bash
ls -la Dockerfile init.sh
```

## 获取帮助

如果问题仍然存在：

1. 收集错误日志：
   ```bash
   docker compose logs > docker-compose.log 2>&1
   ```

2. 检查系统资源：
   ```bash
   df -h
   free -h
   docker system df
   ```

3. 查看 Docker 版本：
   ```bash
   docker --version
   docker compose version
   ```

