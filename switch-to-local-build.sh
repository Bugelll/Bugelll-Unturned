#!/bin/bash
# 切换到本地构建的简单脚本

set -e

COMPOSE_FILE="docker-compose.yml"

echo "=========================================="
echo "切换到本地构建"
echo "=========================================="
echo ""

# 检查文件
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "✗ 未找到 $COMPOSE_FILE"
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    echo "✗ 未找到 Dockerfile"
    exit 1
fi

# 备份
BACKUP_FILE="${COMPOSE_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$COMPOSE_FILE" "$BACKUP_FILE"
echo "[INFO] 已备份: $BACKUP_FILE"
echo ""

# 检查是否已经是 build 模式
if grep -q "build:" "$COMPOSE_FILE"; then
    echo "✓ 已经是本地构建模式"
    echo ""
    echo "直接构建："
    echo "  docker compose build"
    echo "  docker compose up -d"
    exit 0
fi

echo "正在修改 docker-compose.yml..."
echo ""

# 创建新文件
cat > "$COMPOSE_FILE" << 'EOF'
services:
  Bugelll-Unturned-1:
    build:
      context: .
      dockerfile: Dockerfile
    image: bugelll-unturned:latest
    container_name: Bugelll-Unturned-1
    restart: unless-stopped
    ports:
      - "34567:34567/udp"
      - "34568:34568/udp"
    volumes:
      - ./UnturnedData1:/home/steam/Unturned
    environment:
      - SERVER_TYPE=rm4
      - SERVER_NAME=Bugelll-Unturned-1  # 重要：必须设置，否则会使用 Default 目录
      - GAME_DIR=/home/steam/Unturned
      - STEAMCMD_DIR=/home/steam/steamcmd
    stdin_open: true
    tty: true
    networks:
      unturned-net:
        ipv4_address: 172.20.0.2

  Bugelll-Unturned-2:
    build:
      context: .
      dockerfile: Dockerfile
    image: bugelll-unturned:latest
    container_name: Bugelll-Unturned-2
    restart: unless-stopped
    ports:
      - "35678:35678/udp"
      - "35679:35679/udp"
    volumes:
      - ./UnturnedData2:/home/steam/Unturned
    environment:
      - SERVER_TYPE=rm4
      - SERVER_NAME=Bugelll-Unturned-2  # 重要：必须设置，否则会使用 Default 目录
      - GAME_DIR=/home/steam/Unturned
      - STEAMCMD_DIR=/home/steam/steamcmd
    stdin_open: true
    tty: true
    networks:
      unturned-net:
        ipv4_address: 172.20.0.3

networks:
  unturned-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
EOF

echo "✓ docker-compose.yml 已修改为使用本地构建"
echo ""
echo "现在可以构建并启动："
echo "  docker compose build"
echo "  docker compose up -d"
echo ""
echo "原始配置已备份为: $BACKUP_FILE"

