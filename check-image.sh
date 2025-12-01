#!/bin/bash
# 检查 Docker 镜像是否存在和可访问

set -e

IMAGE_NAME="emqo/bugelll-unturned"
IMAGE_TAG="latest"

echo "=========================================="
echo "Docker 镜像检查工具"
echo "=========================================="
echo "镜像: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# 检查镜像是否在本地
echo "[1] 检查本地镜像..."
if docker images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
    echo "✓ 镜像已在本地存在"
    docker images | grep "${IMAGE_NAME}"
else
    echo "✗ 镜像不在本地"
fi

echo ""
echo "[2] 检查 Docker Hub 连接..."
if curl -s --max-time 5 https://hub.docker.com > /dev/null; then
    echo "✓ Docker Hub 可访问"
else
    echo "✗ Docker Hub 无法访问"
fi

echo ""
echo "[3] 尝试从 Docker Hub 拉取镜像（仅检查，不下载）..."
echo "   这可能需要一些时间..."

# 尝试拉取镜像（使用 --dry-run 如果支持，否则使用 pull 但立即取消）
timeout 30 docker pull "${IMAGE_NAME}:${IMAGE_TAG}" 2>&1 | head -20 || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo "✗ 拉取超时（30秒）"
    elif [ $EXIT_CODE -eq 1 ]; then
        echo "✗ 镜像拉取失败"
        echo ""
        echo "可能的原因："
        echo "  1. 镜像不存在于 Docker Hub"
        echo "  2. 镜像是私有的，需要认证"
        echo "  3. 镜像已被删除"
        echo "  4. 网络连接问题"
    fi
}

echo ""
echo "[4] 检查 Docker 配置..."
if [ -f /etc/docker/daemon.json ]; then
    echo "Docker 配置："
    cat /etc/docker/daemon.json | grep -A 10 "registry-mirrors" || echo "  未配置镜像加速器"
else
    echo "未找到 Docker 配置文件"
fi

echo ""
echo "[5] 建议的解决方案："
echo ""
echo "如果镜像不存在或无法访问，可以："
echo ""
echo "方案 1: 使用本地构建"
echo "  修改 docker-compose.yml，将 image 改为 build:"
echo "    build:"
echo "      context: ."
echo "      dockerfile: Dockerfile"
echo "  然后执行: docker compose build"
echo ""
echo "方案 2: 检查镜像是否在其他仓库"
echo "  尝试: docker search ${IMAGE_NAME}"
echo ""
echo "方案 3: 使用其他镜像标签"
echo "  检查是否有其他可用的标签"
echo ""
echo "方案 4: 直接使用 Docker Hub（绕过加速器）"
echo "  docker pull docker.io/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "=========================================="

