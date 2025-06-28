#!/bin/bash

echo "🚀 Panasonic FZ-G1 音量键捕获项目 - 一键安装"
echo "============================================"

# 错误处理
set -e
trap 'echo "❌ 安装过程中出现错误，请检查上述输出"; exit 1' ERR

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用sudo运行此脚本"
    echo "   sudo ./install.sh"
    exit 1
fi

# 获取实际用户信息
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo "📋 安装信息："
echo "   用户: $REAL_USER"
echo "   主目录: $REAL_HOME"
echo "   系统: $(uname -a)"
echo ""

# 检查必要的工具
echo "🔍 检查系统依赖..."
for tool in make go systemctl; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ 缺少必要工具: $tool"
        if [ "$tool" = "go" ]; then
            echo "   请安装 Go 1.19+:"
            echo "   wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz"
            echo "   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz"
            echo "   echo 'export PATH=\$PATH:/usr/local/go/bin' >> ~/.bashrc"
        elif [ "$tool" = "make" ]; then
            echo "   请安装 make: sudo apt-get install build-essential"
        fi
        exit 1
    else
        echo "  ✅ $tool: $(which $tool)"
    fi
done
echo ""

# 第1步：禁用PulseAudio
echo "🔧 第1步：禁用PulseAudio..."
if [ -f "./scripts/disable_pulseaudio.sh" ]; then
    chmod +x ./scripts/disable_pulseaudio.sh
    sudo -u $REAL_USER ./scripts/disable_pulseaudio.sh
    echo "  ✅ PulseAudio配置完成"
else
    echo "  ⚠️  PulseAudio配置脚本未找到，跳过此步骤"
fi
echo ""

# 第2步：配置ACPI事件
echo "🔧 第2步：配置ACPI事件..."
if [ -f "./scripts/setup_acpi.sh" ]; then
    chmod +x ./scripts/setup_acpi.sh
    ./scripts/setup_acpi.sh
    echo "  ✅ ACPI事件配置完成"
else
    echo "  ⚠️  ACPI配置脚本未找到，跳过此步骤"
fi
echo ""

# 第3步：编译和安装Go Bridge服务
echo "🔧 第3步：编译和安装Go Bridge服务..."
cd go-bridge

# 检查Go版本
GO_VERSION=$(go version | grep -oP 'go\d+\.\d+' | grep -oP '\d+\.\d+')
if [ "$(printf '%s\n' "1.19" "$GO_VERSION" | sort -V | head -n1)" != "1.19" ]; then
    echo "❌ Go版本过低，需要1.19+，当前版本: $GO_VERSION"
    exit 1
fi

echo "  📦 安装Go依赖..."
sudo -u $REAL_USER go mod tidy

echo "  🔨 编译Go Bridge服务..."
sudo -u $REAL_USER make build

echo "  📦 安装二进制文件..."
make install

echo "  🔧 安装系统服务..."
make service-install

echo "  🚀 启用并启动服务..."
make service-enable
make service-start

cd ..
echo "  ✅ Go Bridge服务安装完成"
echo ""

# 第4步：设置权限
echo "🔧 第4步：设置文件权限..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x install.sh
chown -R $REAL_USER:$REAL_USER go-bridge/ 2>/dev/null || true
echo "  ✅ 权限设置完成"
echo ""

# 第5步：验证安装
echo "🔍 第5步：验证安装..."
if [ -f "./scripts/verify_setup.sh" ]; then
    chmod +x ./scripts/verify_setup.sh
    sudo -u $REAL_USER ./scripts/verify_setup.sh
else
    echo "  ⚠️  验证脚本未找到，手动检查服务状态"
    echo "  📊 服务状态:"
    systemctl status panasonic-volume-bridge.service --no-pager -l || true
fi
echo ""

# 第6步：测试服务连接
echo "🔍 第6步：测试服务连接..."
echo "  🌐 等待服务启动..."
sleep 3

if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "  ✅ HTTP服务正常运行"
    echo "  📱 健康检查通过: http://localhost:8080/health"
else
    echo "  ⚠️  HTTP服务可能未完全启动，请稍后检查"
fi
echo ""

# 安装完成
echo "✅ 安装完成！"
echo ""
echo "📋 服务信息："
echo "   服务名称: panasonic-volume-bridge.service"
echo "   服务状态: $(systemctl is-active panasonic-volume-bridge.service)"
echo "   开机自启: $(systemctl is-enabled panasonic-volume-bridge.service)"
echo "   HTTP端口: http://localhost:8080"
echo "   WebSocket: ws://localhost:8080/ws"
echo ""
echo "🔧 管理命令："
echo "   查看服务状态:    sudo systemctl status panasonic-volume-bridge"
echo "   查看服务日志:    sudo journalctl -u panasonic-volume-bridge -f"
echo "   重启服务:        sudo systemctl restart panasonic-volume-bridge"
echo "   停止服务:        sudo systemctl stop panasonic-volume-bridge"
echo "   禁用服务:        sudo systemctl disable panasonic-volume-bridge"
echo ""
echo "   使用Makefile管理:"
echo "   cd go-bridge"
echo "   make help        - 查看所有可用命令"
echo "   make service-status    - 查看服务状态"
echo "   make service-logs      - 查看服务日志"
echo "   make service-restart   - 重启服务"
echo ""
echo "📋 接下来的步骤："
echo "1. 服务已自动启动并设置为开机自启"
echo "2. 在Flutter应用中连接: ws://localhost:8080/ws"
echo "3. 访问管理界面: http://localhost:8080"
echo "4. 如有问题，查看日志: sudo journalctl -u panasonic-volume-bridge -f"
echo ""
echo "🎉 享受你的Panasonic FZ-G1音量键控制功能！" 