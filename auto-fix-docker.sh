#!/bin/bash
# 自动修复：尝试远程拉取，失败则切换到本地构建

set -e

IMAGE_NAME="emqo/bugelll-unturned:latest"
COMPOSE_FILE="docker-compose.yml"

echo "=========================================="
echo "Docker 镜像自动修复工具"
echo "=========================================="
echo ""

# 检查文件
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "✗ 未找到 $COMPOSE_FILE"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "✗ 未找到 Dockerfile，无法进行本地构建"
    exit 1
fi

# 备份 docker-compose.yml
BACKUP_FILE="${COMPOSE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$COMPOSE_FILE" "$BACKUP_FILE"
echo "[INFO] 已备份配置文件: $BACKUP_FILE"
echo ""

# 方案 1: 尝试使用当前镜像加速器拉取
echo "[1/3] 尝试使用镜像加速器拉取远程镜像..."
if timeout 60 docker pull "$IMAGE_NAME" 2>&1 | grep -q "Downloaded\|Pulled\|up to date"; then
    echo "✓ 远程镜像拉取成功！"
    echo ""
    echo "启动容器："
    echo "  docker compose up -d"
    exit 0
else
    echo "✗ 远程镜像拉取失败"
    echo ""
fi

# 方案 2: 尝试直接使用 Docker Hub（临时禁用加速器）
echo "[2/3] 尝试直接使用 Docker Hub（临时禁用镜像加速器）..."
if [ -f /etc/docker/daemon.json ]; then
    DAEMON_BACKUP="/etc/docker/daemon.json.bak.$(date +%Y%m%d_%H%M%S)"
    sudo cp /etc/docker/daemon.json "$DAEMON_BACKUP"
    echo '{"registry-mirrors": []}' | sudo tee /etc/docker/daemon.json > /dev/null
    sudo systemctl restart docker
    sleep 3
    
    if timeout 60 docker pull "docker.io/$IMAGE_NAME" 2>&1 | grep -q "Downloaded\|Pulled\|up to date"; then
        echo "✓ 直接使用 Docker Hub 拉取成功！"
        # 恢复配置
        sudo cp "$DAEMON_BACKUP" /etc/docker/daemon.json
        sudo systemctl restart docker
        echo ""
        echo "启动容器："
        echo "  docker compose up -d"
        exit 0
    else
        echo "✗ 直接使用 Docker Hub 也失败"
        # 恢复配置
        sudo cp "$DAEMON_BACKUP" /etc/docker/daemon.json
        sudo systemctl restart docker
    fi
fi

# 方案 3: 切换到本地构建
echo "[3/3] 切换到本地构建（最可靠的方法）..."
echo "  修改 docker-compose.yml 使用本地构建..."

# 使用 Python 或 sed 修改 docker-compose.yml
# 检查是否已经有 build 配置
if grep -q "build:" "$COMPOSE_FILE"; then
    echo "✓ docker-compose.yml 已配置为使用 build"
else
    # 使用 sed 修改文件（针对两个服务）
    sed -i 's|image: emqo/bugelll-unturned:latest|build:\n      context: .\n      dockerfile: Dockerfile\n    image: bugelll-unturned:latest|g' "$COMPOSE_FILE"
    
    # 由于 sed 的局限性，我们使用更简单的方法
    # 创建临时文件
    python3 << 'PYTHON_SCRIPT' || {
import re

with open('docker-compose.yml', 'r') as f:
    content = f.read()

# 替换第一个服务
content = re.sub(
    r'  Bugelll-Unturned-1:\n    image: emqo/bugelll-unturned:latest',
    '''  Bugelll-Unturned-1:
    build:
      context: .
      dockerfile: Dockerfile
    image: bugelll-unturned:latest''',
    content
)

# 替换第二个服务
content = re.sub(
    r'  Bugelll-Unturned-2:\n    image: emqo/bugelll-unturned:latest',
    '''  Bugelll-Unturned-2:
    build:
      context: .
      dockerfile: Dockerfile
    image: bugelll-unturned:latest''',
    content
)

with open('docker-compose.yml', 'w') as f:
    f.write(content)

print("✓ docker-compose.yml 已修改为使用本地构建")
PYTHON_SCRIPT
    # 如果 Python 不可用，使用手动方法
    if [ $? -ne 0 ]; then
        echo ""
        echo "⚠ Python 不可用，需要手动修改 docker-compose.yml"
        echo ""
        echo "请将以下内容："
        echo "    image: emqo/bugelll-unturned:latest"
        echo ""
        echo "改为："
        echo "    build:"
        echo "      context: ."
        echo "      dockerfile: Dockerfile"
        echo "    image: bugelll-unturned:latest"
        echo ""
        echo "（需要修改两个服务：Bugelll-Unturned-1 和 Bugelll-Unturned-2）"
        echo ""
        read -p "修改完成后按回车继续，或按 Ctrl+C 取消..."
    fi
fi

echo ""
echo "开始构建镜像..."
echo "（这可能需要一些时间，请耐心等待）"
if docker compose build; then
    echo ""
    echo "✓ 镜像构建成功！"
    echo ""
    echo "现在可以启动容器："
    echo "  docker compose up -d"
    echo ""
    echo "注意：配置文件已备份为: $BACKUP_FILE"
    exit 0
else
    echo "✗ 镜像构建失败"
    echo "  已恢复原始配置"
    cp "$BACKUP_FILE" "$COMPOSE_FILE"
    echo "  请检查错误信息并重试"
    exit 1
fi

