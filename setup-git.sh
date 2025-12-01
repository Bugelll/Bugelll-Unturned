#!/bin/bash

# ============================================
# Git 仓库快速设置脚本
# 用于将项目上传到 GitHub
# ============================================

set -e

REPO_URL="git@github.com:Bugelll/Bugelll-Unturned.git"
BRANCH="main"

echo "=========================================="
echo "  Git 仓库设置"
echo "=========================================="
echo ""

# 检查是否已经是 Git 仓库
if [ -d ".git" ]; then
    echo "[INFO] 检测到已存在的 Git 仓库"
    read -p "是否重新初始化? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[INFO] 备份现有 .git 目录..."
        mv .git .git.backup.$(date +%s)
        git init
    else
        echo "[INFO] 使用现有 Git 仓库"
    fi
else
    echo "[INFO] 初始化 Git 仓库..."
    git init
fi

# 设置默认分支
echo "[INFO] 设置默认分支为: $BRANCH"
git branch -M "$BRANCH" 2>/dev/null || true

# 检查远程仓库
if git remote get-url origin &>/dev/null; then
    CURRENT_URL=$(git remote get-url origin)
    echo "[INFO] 当前远程仓库: $CURRENT_URL"
    read -p "是否更新远程仓库地址? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url origin "$REPO_URL"
        echo "[INFO] 远程仓库已更新"
    fi
else
    echo "[INFO] 添加远程仓库: $REPO_URL"
    git remote add origin "$REPO_URL"
fi

# 添加所有文件
echo "[INFO] 添加文件到 Git..."
git add .

# 检查是否有更改
if git diff --staged --quiet; then
    echo "[WARN] 没有更改需要提交"
    exit 0
fi

# 显示将要提交的文件
echo ""
echo "将要提交的文件:"
git status --short
echo ""

# 提交更改
COMMIT_MSG="Initial commit: Optimized Unturned Docker server

- Removed EXPOSE declarations from Dockerfile
- Added procps package for healthcheck
- Improved error handling and logging
- Added detailed Chinese comments
- Optimized docker-compose.yml configuration"

read -p "使用默认提交信息? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git commit -m "$COMMIT_MSG"
else
    echo "请输入提交信息:"
    read -r CUSTOM_MSG
    git commit -m "$CUSTOM_MSG"
fi

echo ""
echo "[INFO] 提交完成"
echo ""

# 询问是否推送
read -p "是否推送到 GitHub? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "[INFO] 推送到 GitHub..."
    
    # 检查是否需要强制推送
    if git ls-remote --heads origin "$BRANCH" &>/dev/null; then
        echo "[WARN] 远程仓库已存在 $BRANCH 分支"
        read -p "是否先拉取远程更改? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "[INFO] 拉取远程更改..."
            git pull origin "$BRANCH" --allow-unrelated-histories --no-edit || {
                echo "[ERROR] 拉取失败，可能需要手动解决冲突"
                exit 1
            }
        fi
    fi
    
    # 推送
    if git push -u origin "$BRANCH"; then
        echo ""
        echo "[SUCCESS] 推送成功！"
        echo "[INFO] 仓库地址: https://github.com/Bugelll/Bugelll-Unturned"
    else
        echo ""
        echo "[ERROR] 推送失败"
        echo "[INFO] 请检查："
        echo "  1. SSH 密钥是否配置正确"
        echo "  2. 是否有推送权限"
        echo "  3. 远程仓库是否存在"
        exit 1
    fi
else
    echo "[INFO] 跳过推送"
    echo "[INFO] 稍后可以使用以下命令推送:"
    echo "  git push -u origin $BRANCH"
fi

echo ""
echo "=========================================="
echo "  设置完成"
echo "=========================================="

