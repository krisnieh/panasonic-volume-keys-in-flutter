#!/bin/bash

echo "🚀 Panasonic FZ-G1 音量键捕获项目 - 一键安装"
echo "============================================"

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
echo ""

# 第1步：禁用PulseAudio
echo "🔧 第1步：禁用PulseAudio..."
sudo -u $REAL_USER ./scripts/disable_pulseaudio.sh
echo ""

# 第2步：配置ACPI事件
echo "🔧 第2步：配置ACPI事件..."
./scripts/setup_acpi.sh
echo ""

# 第3步：安装Go依赖
echo "🔧 第3步：检查Go环境..."
if command -v go &> /dev/null; then
    echo "  ✅ Go已安装: $(go version)"
    
    # 安装Go依赖
    echo "  📦 安装Go依赖..."
    cd go-bridge
    sudo -u $REAL_USER go mod tidy
    cd ..
else
    echo "  ⚠️  Go未安装，请手动安装Go 1.19+"
    echo "     wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz"
    echo "     sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz"
    echo "     echo 'export PATH=\$PATH:/usr/local/go/bin' >> ~/.bashrc"
fi
echo ""

# 第4步：设置权限
echo "🔧 第4步：设置文件权限..."
chmod +x scripts/*.sh
chmod +x install.sh
chown -R $REAL_USER:$REAL_USER go-bridge/
echo "  ✅ 权限设置完成"
echo ""

# 第5步：创建系统服务（可选）
echo "🔧 第5步：创建系统服务..."
cat > /etc/systemd/system/panasonic-volume-bridge.service << EOF
[Unit]
Description=Panasonic FZ-G1 Volume Key Bridge Service
After=network.target acpid.service

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$(pwd)/go-bridge
ExecStart=/usr/local/go/bin/go run .
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "  ✅ 系统服务已创建 (未启用)"
echo "     启用服务: sudo systemctl enable panasonic-volume-bridge"
echo "     启动服务: sudo systemctl start panasonic-volume-bridge"
echo ""

# 第6步：验证安装
echo "🔍 第6步：验证安装..."
sudo -u $REAL_USER ./scripts/verify_setup.sh
echo ""

# 安装完成
echo "✅ 安装完成！"
echo ""
echo "📋 接下来的步骤："
echo "1. 重启系统 (推荐): sudo reboot"
echo "2. 或重启ACPI服务: sudo systemctl restart acpid"
echo "3. 启动Go桥接服务: cd go-bridge && go run ."
echo "4. 在Flutter应用中连接: ws://localhost:8080/ws"
echo ""
echo "🔧 管理命令："
echo "   验证配置: ./scripts/verify_setup.sh"
echo "   启动服务: sudo systemctl start panasonic-volume-bridge"
echo "   查看日志: sudo journalctl -u panasonic-volume-bridge -f"
echo "   音量键日志: sudo tail -f /var/log/panasonic-volume-keys.log" 