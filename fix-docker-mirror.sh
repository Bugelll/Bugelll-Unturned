#!/bin/bash
# 修复 Docker 镜像拉取失败问题（429/403 错误）

set -e

echo "=========================================="
echo "Docker 镜像拉取修复脚本"
echo "=========================================="

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then 
    echo "[ERROR] 请使用 sudo 运行此脚本"
    exit 1
fi

DAEMON_JSON="/etc/docker/daemon.json"

echo "[INFO] 当前 Docker 配置："
if [ -f "$DAEMON_JSON" ]; then
    cat "$DAEMON_JSON"
else
    echo "[INFO] 配置文件不存在，将创建新配置"
fi

echo ""
echo "请选择操作："
echo "[1] 临时禁用镜像加速器（直接使用 Docker Hub）"
echo "[2] 恢复镜像加速器配置"
echo "[3] 查看当前配置"
read -p "请输入选项 [1-3]: " choice

case $choice in
    1)
        echo "[INFO] 备份当前配置..."
        if [ -f "$DAEMON_JSON" ]; then
            cp "$DAEMON_JSON" "${DAEMON_JSON}.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        
        echo "[INFO] 创建新配置（禁用镜像加速器）..."
        cat > "$DAEMON_JSON" <<EOF
{
  "registry-mirrors": []
}
EOF
        
        echo "[INFO] 重启 Docker 服务..."
        systemctl restart docker
        
        echo "[SUCCESS] 镜像加速器已禁用，现在将直接使用 Docker Hub"
        echo "[INFO] 等待 Docker 服务启动..."
        sleep 3
        
        echo "[INFO] 尝试拉取镜像..."
        docker pull emqo/bugelll-unturned:latest || {
            echo "[WARNING] 镜像拉取失败，请检查网络连接"
            echo "[INFO] 可以尝试：docker pull docker.io/emqo/bugelll-unturned:latest"
        }
        ;;
    2)
        if [ -f "${DAEMON_JSON}.bak"* ]; then
            echo "[INFO] 找到备份文件，恢复配置..."
            LATEST_BACKUP=$(ls -t ${DAEMON_JSON}.bak* 2>/dev/null | head -1)
            if [ -n "$LATEST_BACKUP" ]; then
                cp "$LATEST_BACKUP" "$DAEMON_JSON"
                echo "[INFO] 已恢复配置：$LATEST_BACKUP"
            else
                echo "[ERROR] 未找到备份文件"
                exit 1
            fi
        else
            echo "[INFO] 未找到备份文件，使用默认镜像加速器配置..."
            cat > "$DAEMON_JSON" <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF
        fi
        
        echo "[INFO] 重启 Docker 服务..."
        systemctl restart docker
        echo "[SUCCESS] 镜像加速器配置已恢复"
        ;;
    3)
        if [ -f "$DAEMON_JSON" ]; then
            echo "[INFO] 当前配置："
            cat "$DAEMON_JSON"
        else
            echo "[INFO] 配置文件不存在"
        fi
        ;;
    *)
        echo "[ERROR] 无效选项"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "完成"
echo "=========================================="

