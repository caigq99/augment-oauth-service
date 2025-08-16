#!/bin/bash

# Augment OAuth Service 一键安装脚本
# 支持 Linux 和 macOS 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO="caigq99/augment-oauth-service"
SERVICE_NAME="augment-oauth-service"
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/augment-oauth"
LOG_DIR="/var/log/augment-oauth"
USER="augment"

# 检测系统架构和操作系统
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $arch in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: $arch${NC}"
            exit 1
            ;;
    esac
    
    case $os in
        linux)
            PLATFORM="linux-$arch"
            ;;
        darwin)
            PLATFORM="macos-$arch"
            ;;
        *)
            echo -e "${RED}❌ 不支持的操作系统: $os${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}📋 检测到平台: $PLATFORM${NC}"
}

# 获取最新版本
get_latest_version() {
    echo -e "${BLUE}🔍 获取最新版本信息...${NC}"
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}❌ 无法获取最新版本信息${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 最新版本: $LATEST_VERSION${NC}"
}

# 下载二进制文件
download_binary() {
    local binary_name="$SERVICE_NAME-$PLATFORM"
    local download_url="https://github.com/$REPO/releases/download/$LATEST_VERSION/$binary_name"
    
    echo -e "${BLUE}📥 下载二进制文件...${NC}"
    echo -e "${BLUE}URL: $download_url${NC}"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 下载文件
    if ! curl -L -o "$SERVICE_NAME" "$download_url"; then
        echo -e "${RED}❌ 下载失败${NC}"
        exit 1
    fi
    
    # 验证文件
    if [ ! -f "$SERVICE_NAME" ]; then
        echo -e "${RED}❌ 下载的文件不存在${NC}"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x "$SERVICE_NAME"
    
    echo -e "${GREEN}✅ 下载完成${NC}"
    echo "$temp_dir/$SERVICE_NAME"
}

# 安装二进制文件
install_binary() {
    local binary_path="$1"
    
    echo -e "${BLUE}📦 安装二进制文件...${NC}"
    
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠️  需要 sudo 权限来安装到 $INSTALL_DIR${NC}"
        sudo cp "$binary_path" "$INSTALL_DIR/$SERVICE_NAME"
        sudo chmod +x "$INSTALL_DIR/$SERVICE_NAME"
    else
        cp "$binary_path" "$INSTALL_DIR/$SERVICE_NAME"
        chmod +x "$INSTALL_DIR/$SERVICE_NAME"
    fi
    
    echo -e "${GREEN}✅ 二进制文件已安装到 $INSTALL_DIR/$SERVICE_NAME${NC}"
}

# 创建用户
create_user() {
    if [ "$(uname -s)" = "Linux" ]; then
        echo -e "${BLUE}👤 创建服务用户...${NC}"
        
        if ! id "$USER" &>/dev/null; then
            if [ "$EUID" -ne 0 ]; then
                sudo useradd -r -s /bin/false -d /nonexistent "$USER"
            else
                useradd -r -s /bin/false -d /nonexistent "$USER"
            fi
            echo -e "${GREEN}✅ 用户 $USER 创建成功${NC}"
        else
            echo -e "${YELLOW}⚠️  用户 $USER 已存在${NC}"
        fi
    fi
}

# 创建目录
create_directories() {
    echo -e "${BLUE}📁 创建必要目录...${NC}"
    
    local dirs=("$CONFIG_DIR" "$LOG_DIR")
    
    for dir in "${dirs[@]}"; do
        if [ "$EUID" -ne 0 ]; then
            sudo mkdir -p "$dir"
            if [ "$(uname -s)" = "Linux" ]; then
                sudo chown "$USER:$USER" "$dir"
            fi
        else
            mkdir -p "$dir"
            if [ "$(uname -s)" = "Linux" ]; then
                chown "$USER:$USER" "$dir"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ 目录创建完成${NC}"
}

# 创建配置文件
create_config() {
    echo -e "${BLUE}⚙️  创建配置文件...${NC}"
    
    local config_file="$CONFIG_DIR/config.env"
    
    cat > /tmp/config.env << 'EOF'
# Augment OAuth Service 配置文件
RUST_LOG=info
PORT=3000
HOST=0.0.0.0

# OAuth 配置
OAUTH_AUTH_URL=https://auth.augmentcode.com/authorize
OAUTH_CLIENT_ID=v

# 服务配置
STATE_EXPIRE_MINUTES=30
EOF

    if [ "$EUID" -ne 0 ]; then
        sudo mv /tmp/config.env "$config_file"
        if [ "$(uname -s)" = "Linux" ]; then
            sudo chown "$USER:$USER" "$config_file"
        fi
        sudo chmod 640 "$config_file"
    else
        mv /tmp/config.env "$config_file"
        if [ "$(uname -s)" = "Linux" ]; then
            chown "$USER:$USER" "$config_file"
        fi
        chmod 640 "$config_file"
    fi
    
    echo -e "${GREEN}✅ 配置文件已创建: $config_file${NC}"
}

# 创建 systemd 服务 (仅 Linux)
create_systemd_service() {
    if [ "$(uname -s)" != "Linux" ]; then
        return
    fi
    
    echo -e "${BLUE}🔧 创建 systemd 服务...${NC}"
    
    local service_file="$SERVICE_DIR/$SERVICE_NAME.service"
    
    cat > /tmp/$SERVICE_NAME.service << EOF
[Unit]
Description=Augment OAuth Service
Documentation=https://github.com/$REPO
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
ExecStart=$INSTALL_DIR/$SERVICE_NAME
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
EnvironmentFile=$CONFIG_DIR/config.env

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$LOG_DIR

[Install]
WantedBy=multi-user.target
EOF

    if [ "$EUID" -ne 0 ]; then
        sudo mv /tmp/$SERVICE_NAME.service "$service_file"
        sudo systemctl daemon-reload
    else
        mv /tmp/$SERVICE_NAME.service "$service_file"
        systemctl daemon-reload
    fi
    
    echo -e "${GREEN}✅ systemd 服务已创建${NC}"
}

# 创建 launchd 服务 (仅 macOS)
create_launchd_service() {
    if [ "$(uname -s)" != "Darwin" ]; then
        return
    fi
    
    echo -e "${BLUE}🔧 创建 launchd 服务...${NC}"
    
    local plist_file="$HOME/Library/LaunchAgents/com.augment.oauth-service.plist"
    
    mkdir -p "$(dirname "$plist_file")"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.augment.oauth-service</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$SERVICE_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>RUST_LOG</key>
        <string>info</string>
        <key>PORT</key>
        <string>3000</string>
    </dict>
</dict>
</plist>
EOF

    echo -e "${GREEN}✅ launchd 服务已创建${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}🚀 启动服务...${NC}"
    
    if [ "$(uname -s)" = "Linux" ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo systemctl enable "$SERVICE_NAME"
            sudo systemctl start "$SERVICE_NAME"
        else
            systemctl enable "$SERVICE_NAME"
            systemctl start "$SERVICE_NAME"
        fi
        
        # 检查服务状态
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ 服务启动成功${NC}"
        else
            echo -e "${RED}❌ 服务启动失败${NC}"
            echo -e "${YELLOW}查看日志: sudo journalctl -u $SERVICE_NAME -f${NC}"
            exit 1
        fi
        
    elif [ "$(uname -s)" = "Darwin" ]; then
        launchctl load "$HOME/Library/LaunchAgents/com.augment.oauth-service.plist"
        echo -e "${GREEN}✅ 服务已加载到 launchd${NC}"
    fi
}

# 显示服务信息
show_service_info() {
    echo -e "\n${GREEN}🎉 安装完成！${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📋 服务信息:${NC}"
    echo -e "   服务名称: $SERVICE_NAME"
    echo -e "   安装路径: $INSTALL_DIR/$SERVICE_NAME"
    echo -e "   配置文件: $CONFIG_DIR/config.env"
    echo -e "   日志目录: $LOG_DIR"
    echo -e "   服务地址: http://localhost:3000"
    
    echo -e "\n${BLUE}🔧 管理命令:${NC}"
    if [ "$(uname -s)" = "Linux" ]; then
        echo -e "   启动服务: sudo systemctl start $SERVICE_NAME"
        echo -e "   停止服务: sudo systemctl stop $SERVICE_NAME"
        echo -e "   重启服务: sudo systemctl restart $SERVICE_NAME"
        echo -e "   查看状态: sudo systemctl status $SERVICE_NAME"
        echo -e "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo -e "   启动服务: launchctl load ~/Library/LaunchAgents/com.augment.oauth-service.plist"
        echo -e "   停止服务: launchctl unload ~/Library/LaunchAgents/com.augment.oauth-service.plist"
        echo -e "   查看日志: tail -f $LOG_DIR/stdout.log"
    fi
    
    echo -e "\n${BLUE}🧪 测试服务:${NC}"
    echo -e "   curl http://localhost:3000/health"
    
    echo -e "\n${BLUE}📖 更多信息:${NC}"
    echo -e "   GitHub: https://github.com/$REPO"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}🚀 Augment OAuth Service 一键安装脚本${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 检查依赖
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl 未安装，请先安装 curl${NC}"
        exit 1
    fi
    
    # 检测平台
    detect_platform
    
    # 获取最新版本
    get_latest_version
    
    # 下载二进制文件
    binary_path=$(download_binary)
    
    # 安装
    install_binary "$binary_path"
    create_user
    create_directories
    create_config
    
    # 创建服务
    if [ "$(uname -s)" = "Linux" ]; then
        create_systemd_service
    elif [ "$(uname -s)" = "Darwin" ]; then
        create_launchd_service
    fi
    
    # 启动服务
    start_service
    
    # 清理临时文件
    rm -rf "$(dirname "$binary_path")"
    
    # 显示信息
    show_service_info
}

# 运行主函数
main "$@"
