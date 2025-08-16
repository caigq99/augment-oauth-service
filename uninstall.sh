#!/bin/bash

# Augment OAuth Service 卸载脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SERVICE_NAME="augment-oauth-service"
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/augment-oauth"
LOG_DIR="/var/log/augment-oauth"
USER="augment"

echo -e "${BLUE}🗑️  Augment OAuth Service 卸载脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 确认卸载
read -p "$(echo -e ${YELLOW}确定要卸载 Augment OAuth Service 吗？[y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}取消卸载${NC}"
    exit 0
fi

# 停止并禁用服务
if [ "$(uname -s)" = "Linux" ]; then
    echo -e "${BLUE}🛑 停止 systemd 服务...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        if [ "$EUID" -ne 0 ]; then
            sudo systemctl stop "$SERVICE_NAME"
        else
            systemctl stop "$SERVICE_NAME"
        fi
        echo -e "${GREEN}✅ 服务已停止${NC}"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        if [ "$EUID" -ne 0 ]; then
            sudo systemctl disable "$SERVICE_NAME"
        else
            systemctl disable "$SERVICE_NAME"
        fi
        echo -e "${GREEN}✅ 服务已禁用${NC}"
    fi
    
    # 删除服务文件
    if [ -f "$SERVICE_DIR/$SERVICE_NAME.service" ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo rm -f "$SERVICE_DIR/$SERVICE_NAME.service"
            sudo systemctl daemon-reload
        else
            rm -f "$SERVICE_DIR/$SERVICE_NAME.service"
            systemctl daemon-reload
        fi
        echo -e "${GREEN}✅ systemd 服务文件已删除${NC}"
    fi
    
elif [ "$(uname -s)" = "Darwin" ]; then
    echo -e "${BLUE}🛑 停止 launchd 服务...${NC}"
    
    local plist_file="$HOME/Library/LaunchAgents/com.augment.oauth-service.plist"
    
    if [ -f "$plist_file" ]; then
        launchctl unload "$plist_file" 2>/dev/null || true
        rm -f "$plist_file"
        echo -e "${GREEN}✅ launchd 服务已删除${NC}"
    fi
fi

# 删除二进制文件
if [ -f "$INSTALL_DIR/$SERVICE_NAME" ]; then
    echo -e "${BLUE}🗑️  删除二进制文件...${NC}"
    if [ "$EUID" -ne 0 ]; then
        sudo rm -f "$INSTALL_DIR/$SERVICE_NAME"
    else
        rm -f "$INSTALL_DIR/$SERVICE_NAME"
    fi
    echo -e "${GREEN}✅ 二进制文件已删除${NC}"
fi

# 删除配置目录
if [ -d "$CONFIG_DIR" ]; then
    echo -e "${BLUE}🗑️  删除配置目录...${NC}"
    if [ "$EUID" -ne 0 ]; then
        sudo rm -rf "$CONFIG_DIR"
    else
        rm -rf "$CONFIG_DIR"
    fi
    echo -e "${GREEN}✅ 配置目录已删除${NC}"
fi

# 询问是否删除日志
if [ -d "$LOG_DIR" ]; then
    read -p "$(echo -e ${YELLOW}是否删除日志目录 $LOG_DIR？[y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$EUID" -ne 0 ]; then
            sudo rm -rf "$LOG_DIR"
        else
            rm -rf "$LOG_DIR"
        fi
        echo -e "${GREEN}✅ 日志目录已删除${NC}"
    else
        echo -e "${YELLOW}⚠️  保留日志目录: $LOG_DIR${NC}"
    fi
fi

# 询问是否删除用户
if [ "$(uname -s)" = "Linux" ] && id "$USER" &>/dev/null; then
    read -p "$(echo -e ${YELLOW}是否删除用户 $USER？[y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$EUID" -ne 0 ]; then
            sudo userdel "$USER" 2>/dev/null || true
        else
            userdel "$USER" 2>/dev/null || true
        fi
        echo -e "${GREEN}✅ 用户已删除${NC}"
    else
        echo -e "${YELLOW}⚠️  保留用户: $USER${NC}"
    fi
fi

echo -e "\n${GREEN}🎉 卸载完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}感谢使用 Augment OAuth Service！${NC}"
