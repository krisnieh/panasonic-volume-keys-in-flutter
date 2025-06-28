#!/bin/bash

echo "🔍 验证Panasonic FZ-G1音量键配置"
echo "================================"

# 1. 检查PulseAudio状态
echo "📋 第1步：检查PulseAudio状态..."
if pgrep -f pulseaudio > /dev/null; then
    echo "  ❌ PulseAudio仍在运行"
    echo "     进程: $(pgrep -f pulseaudio)"
else
    echo "  ✅ PulseAudio已停止"
fi

if pactl info 2>/dev/null; then
    echo "  ❌ PulseAudio仍可访问"
else
    echo "  ✅ PulseAudio已完全禁用"
fi

# 2. 检查ACPI配置
echo ""
echo "📋 第2步：检查ACPI配置..."
if [ -f "/etc/acpi/events/panasonic-volume-up" ]; then
    echo "  ✅ 音量增加ACPI配置存在"
else
    echo "  ❌ 音量增加ACPI配置缺失"
fi

if [ -f "/etc/acpi/events/panasonic-volume-down" ]; then
    echo "  ✅ 音量减少ACPI配置存在"
else
    echo "  ❌ 音量减少ACPI配置缺失"
fi

if [ -f "/etc/acpi/panasonic-volume-interceptor.sh" ]; then
    echo "  ✅ 音量拦截器脚本存在"
else
    echo "  ❌ 音量拦截器脚本缺失"
fi

# 3. 检查ACPI服务
echo ""
echo "📋 第3步：检查ACPI服务..."
if systemctl is-active --quiet acpid; then
    echo "  ✅ ACPI服务正在运行"
else
    echo "  ❌ ACPI服务未运行"
    echo "     尝试启动: sudo systemctl start acpid"
fi

# 4. 检查日志文件
echo ""
echo "📋 第4步：检查日志文件..."
if [ -f "/var/log/panasonic-volume-keys.log" ]; then
    echo "  ✅ 日志文件存在"
    if [ -s "/var/log/panasonic-volume-keys.log" ]; then
        echo "  📄 最近的日志记录:"
        sudo tail -5 /var/log/panasonic-volume-keys.log | sed 's/^/       /'
    else
        echo "  ⚠️  日志文件为空（正常，等待按键事件）"
    fi
else
    echo "  ❌ 日志文件不存在"
fi

# 5. 实时测试
echo ""
echo "📋 第5步：实时测试音量键..."
echo "请按音量键进行测试，10秒后自动结束"
echo "或按Ctrl+C提前结束"

# 清空日志用于测试
sudo truncate -s 0 /var/log/panasonic-volume-keys.log 2>/dev/null

# 监听10秒
timeout 10 sudo tail -f /var/log/panasonic-volume-keys.log 2>/dev/null &
TAIL_PID=$!

echo "监听中..."
sleep 10

# 停止监听
kill $TAIL_PID 2>/dev/null

# 检查测试结果
echo ""
echo "📊 测试结果："
if [ -s "/var/log/panasonic-volume-keys.log" ]; then
    echo "  ✅ 捕获到音量键事件:"
    sudo cat /var/log/panasonic-volume-keys.log | sed 's/^/       /'
else
    echo "  ⚠️  未捕获到音量键事件"
    echo "     请确保按了音量键并检查配置"
fi

echo ""
echo "🔚 验证完成" 