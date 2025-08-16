#!/bin/bash

# Augment OAuth Service 启动脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_PORT=3000
DEFAULT_HOST="0.0.0.0"
DEFAULT_LOG_LEVEL="info"

# 从环境变量或使用默认值
PORT=${PORT:-$DEFAULT_PORT}
HOST=${HOST:-$DEFAULT_HOST}
RUST_LOG=${RUST_LOG:-$DEFAULT_LOG_LEVEL}

# 显示启动信息
echo -e "${BLUE}🚀 启动 Augment OAuth Service${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 配置信息:${NC}"
echo -e "   监听地址: ${GREEN}$HOST:$PORT${NC}"
echo -e "   日志级别: ${GREEN}$RUST_LOG${NC}"
echo -e "   进程ID: ${GREEN}$$${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 检查端口是否被占用
if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}❌ 端口 $PORT 已被占用${NC}"
        echo -e "${YELLOW}💡 请检查是否有其他服务在使用该端口${NC}"
        exit 1
    fi
fi

# 设置环境变量
export RUST_LOG="$RUST_LOG"
export PORT="$PORT"
export HOST="$HOST"

# 信号处理函数
cleanup() {
    echo -e "\n${YELLOW}🛑 收到停止信号，正在关闭服务...${NC}"
    exit 0
}

# 注册信号处理
trap cleanup SIGINT SIGTERM

# 检查二进制文件
BINARY_NAME="augment-oauth-service"
BINARY_PATH=""

# 查找二进制文件
if [ -f "./$BINARY_NAME" ]; then
    BINARY_PATH="./$BINARY_NAME"
elif [ -f "./target/release/$BINARY_NAME" ]; then
    BINARY_PATH="./target/release/$BINARY_NAME"
elif command -v "$BINARY_NAME" >/dev/null 2>&1; then
    BINARY_PATH="$BINARY_NAME"
else
    echo -e "${RED}❌ 找不到 $BINARY_NAME 二进制文件${NC}"
    echo -e "${YELLOW}💡 请确保已编译项目或安装了服务${NC}"
    echo -e "${YELLOW}   编译: cargo build --release${NC}"
    echo -e "${YELLOW}   安装: curl -fsSL https://raw.githubusercontent.com/your-repo/main/install.sh | bash${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 找到二进制文件: $BINARY_PATH${NC}"

# 显示服务URL
echo -e "\n${GREEN}🌐 服务地址:${NC}"
echo -e "   健康检查: ${BLUE}http://$HOST:$PORT/health${NC}"
echo -e "   获取授权链接: ${BLUE}http://$HOST:$PORT/api/auth-url${NC}"
echo -e "   完成授权: ${BLUE}http://$HOST:$PORT/api/complete-auth${NC}"

echo -e "\n${YELLOW}💡 按 Ctrl+C 停止服务${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 启动服务
echo -e "${GREEN}🚀 启动服务...${NC}"
exec "$BINARY_PATH"
