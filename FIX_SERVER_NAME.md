# 修复 SERVER_NAME 配置问题

## 问题描述

如果服务器日志显示 `[INFO] Server name: server`，并且服务器目录中出现了 `server` 目录而不是指定的 `SERVER_NAME` 目录，说明 `SERVER_NAME` 环境变量没有正确传递到容器中。

## 原因

Docker 容器的环境变量在容器**创建时**设置，仅仅重启容器不会重新读取 `docker-compose.yml` 中的环境变量更改。

## 解决方案

### 方法 1：重新创建容器（推荐）

1. **停止并删除现有容器**：
   ```bash
   cd /data/Unturned
   docker compose down
   ```

2. **确认 docker-compose.yml 配置正确**：
   ```bash
   cat docker-compose.yml | grep SERVER_NAME
   ```
   
   应该看到：
   ```
   - SERVER_NAME=Bugelll-Unturned-1
   - SERVER_NAME=Bugelll-Unturned-2
   ```

3. **重新创建并启动容器**：
   ```bash
   docker compose up -d
   ```

4. **验证环境变量**：
   ```bash
   docker exec Bugelll-Unturned-1 env | grep SERVER_NAME
   docker exec Bugelll-Unturned-2 env | grep SERVER_NAME
   ```
   
   应该显示：
   ```
   SERVER_NAME=Bugelll-Unturned-1
   SERVER_NAME=Bugelll-Unturned-2
   ```

5. **检查日志确认**：
   ```bash
   docker logs Bugelll-Unturned-1 | grep "Server name"
   ```
   
   应该显示：
   ```
   [INFO] Server name: Bugelll-Unturned-1
   ```

### 方法 2：手动设置环境变量（临时方案）

如果不想重新创建容器，可以手动设置环境变量：

1. **停止容器**：
   ```bash
   docker stop Bugelll-Unturned-1 Bugelll-Unturned-2
   ```

2. **使用 docker run 重新创建容器**（需要从 docker-compose.yml 复制完整配置）

   或者直接编辑容器配置（不推荐，复杂且容易出错）

3. **推荐使用方法 1**，更简单可靠

## 验证修复

修复后，检查服务器目录结构：

```bash
ls -l /data/Unturned/UnturnedData1/Servers/
ls -l /data/Unturned/UnturnedData2/Servers/
```

应该看到：
- `Bugelll-Unturned-1` 目录（而不是 `server`）
- `Bugelll-Unturned-2` 目录（而不是 `server`）
- `Default` 目录（基础配置）

## 注意事项

1. **数据不会丢失**：重新创建容器不会删除挂载的数据卷，游戏数据是安全的
2. **端口映射**：确保端口映射配置正确
3. **网络配置**：如果使用了自定义网络，确保网络配置正确

## 预防措施

在更新 `docker-compose.yml` 中的环境变量后，始终使用 `docker compose up -d --force-recreate` 来确保容器使用新的配置。

