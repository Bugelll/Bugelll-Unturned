# 故障排除指南

## Docker 镜像拉取失败

### 问题症状

```
short read: expected 29536798 bytes but got 0: unexpected EOF
```

### 原因

1. 网络连接不稳定
2. Docker Hub 镜像仓库问题
3. Docker 镜像缓存损坏

### 解决方案

#### 方案 1：使用本地构建（推荐）

当前 `docker-compose.yml` 已配置为本地构建，无需拉取远程镜像：

```bash
cd /data/Unturned
docker compose build
docker compose up -d
```

#### 方案 2：清理缓存并重试拉取

如果必须使用远程镜像：

```bash
# 清理 Docker 系统缓存
docker system prune -a --volumes

# 清理特定镜像
docker rmi emqo/bugelll-unturned:latest 2>/dev/null || true

# 重试拉取
docker compose pull
docker compose up -d
```

#### 方案 3：使用镜像加速器

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

