#!/bin/bash

echo "🗑️  Panasonic FZ-G1 音量键捕获项目 - 卸载程序"
echo "============================================"

# 错误处理
set -e

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用sudo运行此脚本"
    echo "   sudo ./uninstall.sh"
    exit 1
fi

# 获取实际用户信息
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo "📋 卸载信息："
echo "   用户: $REAL_USER"
echo "   主目录: $REAL_HOME"
echo ""

# 确认卸载
read -p "⚠️  确定要卸载Panasonic Volume Bridge服务吗？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 卸载已取消"
    exit 0
fi

echo "🔄 开始卸载..."
echo ""

# 第1步：停止和卸载服务
echo "🛑 第1步：停止和卸载系统服务..."
if systemctl is-active --quiet panasonic-volume-bridge; then
    echo "  ⏹️  停止服务..."
    systemctl stop panasonic-volume-bridge || true
fi

if systemctl is-enabled --quiet panasonic-volume-bridge; then
    echo "  🚫 禁用开机自启..."
    systemctl disable panasonic-volume-bridge || true
fi

if [ -f "/etc/systemd/system/panasonic-volume-bridge.service" ]; then
    echo "  🗑️  删除服务文件..."
    rm -f /etc/systemd/system/panasonic-volume-bridge.service
    systemctl daemon-reload
    echo "  ✅ 系统服务已卸载"
else
    echo "  ℹ️  系统服务文件不存在"
fi
echo ""

# 第2步：删除二进制文件
echo "🗑️  第2步：删除二进制文件..."
if [ -f "/usr/local/bin/panasonic-volume-bridge" ]; then
    rm -f /usr/local/bin/panasonic-volume-bridge
    echo "  ✅ 二进制文件已删除"
else
    echo "  ℹ️  二进制文件不存在"
fi
echo ""

# 第3步：使用Makefile清理（如果存在）
echo "🧹 第3步：清理构建文件..."
if [ -d "go-bridge" ] && [ -f "go-bridge/Makefile" ]; then
    cd go-bridge
    if make clean &>/dev/null; then
        echo "  ✅ 构建文件已清理"
    else
        echo "  ⚠️  清理构建文件时出现问题，手动清理..."
        rm -rf build/ 2>/dev/null || true
    fi
    cd ..
else
    echo "  ℹ️  Makefile不存在，跳过构建文件清理"
fi
echo ""

# 第4步：清理日志文件（可选）
echo "📋 第4步：清理日志文件..."
read -p "是否删除日志文件 /var/log/panasonic-volume-keys.log？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "/var/log/panasonic-volume-keys.log" ]; then
        rm -f /var/log/panasonic-volume-keys.log
        echo "  ✅ 日志文件已删除"
    else
        echo "  ℹ️  日志文件不存在"
    fi
else
    echo "  ℹ️  保留日志文件"
fi
echo ""

# 第5步：恢复ACPI配置（可选）
echo "🔧 第5步：恢复ACPI配置..."
read -p "是否恢复ACPI配置到默认状态？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "./scripts/restore_acpi.sh" ]; then
        chmod +x ./scripts/restore_acpi.sh
        ./scripts/restore_acpi.sh
        echo "  ✅ ACPI配置已恢复"
    else
        echo "  ⚠️  ACPI恢复脚本不存在，请手动恢复"
        echo "     可能需要删除: /etc/acpi/events/panasonic-volume-*"
        echo "     可能需要删除: /etc/acpi/panasonic-volume-*.sh"
    fi
else
    echo "  ℹ️  保留ACPI配置"
fi
echo ""

# 第6步：恢复PulseAudio（可选）
echo "🔊 第6步：恢复PulseAudio配置..."
read -p "是否恢复PulseAudio配置？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "./scripts/restore_pulseaudio.sh" ]; then
        chmod +x ./scripts/restore_pulseaudio.sh
        sudo -u $REAL_USER ./scripts/restore_pulseaudio.sh
        echo "  ✅ PulseAudio配置已恢复"
    else
        echo "  ⚠️  PulseAudio恢复脚本不存在，请手动恢复"
        echo "     可能需要编辑: $REAL_HOME/.config/pulse/default.pa"
    fi
else
    echo "  ℹ️  保留PulseAudio配置"
fi
echo ""

# 第7步：最终检查
echo "🔍 第7步：最终检查..."
REMAINING_FILES=()

if [ -f "/usr/local/bin/panasonic-volume-bridge" ]; then
    REMAINING_FILES+=("/usr/local/bin/panasonic-volume-bridge")
fi

if [ -f "/etc/systemd/system/panasonic-volume-bridge.service" ]; then
    REMAINING_FILES+=("/etc/systemd/system/panasonic-volume-bridge.service")
fi

if [ ${#REMAINING_FILES[@]} -gt 0 ]; then
    echo "  ⚠️  以下文件可能需要手动删除："
    for file in "${REMAINING_FILES[@]}"; do
        echo "     $file"
    done
else
    echo "  ✅ 所有主要文件已成功删除"
fi
echo ""

# 卸载完成
echo "✅ 卸载完成！"
echo ""
echo "📋 卸载总结："
echo "   ✅ 系统服务已停止和卸载"
echo "   ✅ 二进制文件已删除"
echo "   ✅ 构建文件已清理"
echo ""
echo "📝 注意事项："
echo "   - 项目源代码保留在当前目录"
echo "   - 如果需要重新安装，运行: sudo ./install.sh"
echo "   - 如果需要完全删除项目目录，请手动删除"
echo ""
echo "🙋 如果遇到问题，请查看项目文档或提交issue"
echo "感谢使用 Panasonic FZ-G1 音量键控制项目！" 