#!/bin/bash
# 快速修复脚本：尝试多种方式拉取镜像

set -e

IMAGE_NAME="emqo/bugelll-unturned:latest"

echo "=========================================="
echo "快速修复：尝试拉取 Docker 镜像"
echo "=========================================="
echo ""

# 方案 1: 尝试使用当前镜像加速器
echo "[方案 1] 尝试使用当前镜像加速器拉取..."
if docker pull "$IMAGE_NAME" 2>&1 | tee /tmp/docker-pull.log; then
    echo "✓ 镜像拉取成功！"
    echo ""
    echo "现在可以启动容器："
    echo "  docker compose up -d"
    exit 0
else
    echo "✗ 使用镜像加速器拉取失败"
    echo ""
fi

# 方案 2: 尝试直接使用 Docker Hub（如果网络允许）
echo "[方案 2] 尝试直接使用 Docker Hub..."
echo "  临时禁用镜像加速器..."

# 备份配置
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak.$(date +%Y%m%d_%H%M%S)
    # 临时禁用加速器
    echo '{"registry-mirrors": []}' | sudo tee /etc/docker/daemon.json > /dev/null
    sudo systemctl restart docker
    sleep 3
    
    if docker pull "docker.io/$IMAGE_NAME" 2>&1; then
        echo "✓ 直接使用 Docker Hub 拉取成功！"
        # 恢复配置
        sudo cp /etc/docker/daemon.json.bak.* /etc/docker/daemon.json 2>/dev/null || true
        sudo systemctl restart docker
        echo ""
        echo "现在可以启动容器："
        echo "  docker compose up -d"
        exit 0
    else
        echo "✗ 直接使用 Docker Hub 也失败"
        # 恢复配置
        sudo cp /etc/docker/daemon.json.bak.* /etc/docker/daemon.json 2>/dev/null || true
        sudo systemctl restart docker
    fi
fi

# 方案 3: 使用本地构建
echo ""
echo "[方案 3] 使用本地构建（推荐）..."
echo "  这是最可靠的方法，不依赖网络"

# 检查必要文件
if [ ! -f "Dockerfile" ]; then
    echo "✗ 未找到 Dockerfile，无法进行本地构建"
    echo "  请确保在项目目录中运行此脚本"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "✗ 未找到 docker-compose.yml"
    exit 1
fi

echo ""
echo "正在修改 docker-compose.yml 使用本地构建..."
echo "（将创建备份文件 docker-compose.yml.bak）"

# 备份 docker-compose.yml
cp docker-compose.yml docker-compose.yml.bak.$(date +%Y%m%d_%H%M%S)

# 检查是否已经有 build 配置
if grep -q "build:" docker-compose.yml; then
    echo "✓ docker-compose.yml 已配置为使用 build"
else
    echo "  需要修改 docker-compose.yml..."
    # 这里可以提供一个 Python 或 sed 脚本来修改，但为了简单，我们提示用户手动修改
    echo ""
    echo "请手动修改 docker-compose.yml："
    echo "  将 'image: emqo/bugelll-unturned:latest' 改为："
    echo "    build:"
    echo "      context: ."
    echo "      dockerfile: Dockerfile"
    echo "    image: bugelll-unturned:latest"
    echo ""
    read -p "修改完成后按回车继续，或按 Ctrl+C 取消..."
fi

echo ""
echo "开始构建镜像..."
if docker compose build; then
    echo ""
    echo "✓ 镜像构建成功！"
    echo ""
    echo "现在可以启动容器："
    echo "  docker compose up -d"
    exit 0
else
    echo "✗ 镜像构建失败"
    echo "  请检查错误信息"
    exit 1
fi

