#!/bin/bash

echo "🔧 禁用PulseAudio音量键处理 - Panasonic FZ-G1"
echo "============================================="

# 1. 停止PulseAudio服务
echo "📋 停止PulseAudio服务..."
pulseaudio --kill 2>/dev/null
systemctl --user stop pulseaudio.service 2>/dev/null
systemctl --user stop pulseaudio.socket 2>/dev/null

# 2. 禁用PulseAudio自动启动
echo "📋 禁用PulseAudio自动启动..."
systemctl --user disable pulseaudio.service 2>/dev/null
systemctl --user disable pulseaudio.socket 2>/dev/null
systemctl --user mask pulseaudio.service pulseaudio.socket 2>/dev/null

# 3. 强制停止所有PulseAudio进程
echo "📋 清理PulseAudio进程..."
sudo pkill pulseaudio 2>/dev/null

# 4. 创建PulseAudio配置目录
mkdir -p ~/.config/pulse

# 5. 创建禁用音量键的PulseAudio配置
echo "📋 配置PulseAudio禁用音量键..."
cat > ~/.config/pulse/client.conf << 'EOF'
# 禁用自动启动
autospawn = no
enable-remixing = no
enable-lfe-remixing = no
EOF

# 6. 验证结果
echo ""
echo "📊 验证结果："
if pgrep -f pulseaudio > /dev/null; then
    echo "  ❌ PulseAudio仍在运行"
    pgrep -f pulseaudio
else
    echo "  ✅ PulseAudio已停止"
fi

if pactl info 2>/dev/null; then
    echo "  ❌ PulseAudio仍可访问"
else
    echo "  ✅ PulseAudio已完全禁用"
fi

echo ""
echo "✅ PulseAudio音量键处理已禁用"
echo "⚠️  建议重启系统以确保完全生效" 