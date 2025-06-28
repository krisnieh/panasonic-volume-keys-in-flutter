#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用sudo运行此脚本"
    exit 1
fi

echo "🔧 配置ACPI音量键事件 - Panasonic FZ-G1"
echo "====================================="

# 1. 创建ACPI事件配置文件
echo "📋 创建ACPI事件配置..."

# 音量增加事件
cat > /etc/acpi/events/panasonic-volume-up << 'EOF'
event=button/volumeup VOLUP 00000080 00000000
action=/etc/acpi/panasonic-volume-interceptor.sh VOLUME_UP %e
EOF

# 音量减少事件
cat > /etc/acpi/events/panasonic-volume-down << 'EOF'
event=button/volumedown VOLDN 00000080 00000000
action=/etc/acpi/panasonic-volume-interceptor.sh VOLUME_DOWN %e
EOF

# 2. 创建拦截器脚本
echo "📋 创建音量键拦截器..."
cat > /etc/acpi/panasonic-volume-interceptor.sh << 'EOF'
#!/bin/bash

# 音量键拦截器 - Panasonic FZ-G1
# 功能：捕获音量键事件并记录到日志

VOLUME_ACTION="$1"
EVENT_DETAILS="$2"
LOG_FILE="/var/log/panasonic-volume-keys.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 记录事件到日志
echo "[$TIMESTAMP] $VOLUME_ACTION: $EVENT_DETAILS" >> "$LOG_FILE"

# 可选：发送到系统日志
logger -t "panasonic-volume" "$VOLUME_ACTION event detected"

# 阻止事件继续传播（关键：不执行任何音量调整）
exit 0
EOF

# 3. 设置权限
echo "📋 设置文件权限..."
chmod 644 /etc/acpi/events/panasonic-volume-up
chmod 644 /etc/acpi/events/panasonic-volume-down
chmod 755 /etc/acpi/panasonic-volume-interceptor.sh

# 4. 创建日志文件
echo "📋 创建日志文件..."
touch /var/log/panasonic-volume-keys.log
chmod 666 /var/log/panasonic-volume-keys.log

# 5. 重启ACPI服务
echo "📋 重启ACPI服务..."
systemctl restart acpid

# 6. 验证配置
echo ""
echo "📊 验证ACPI配置："
if systemctl is-active --quiet acpid; then
    echo "  ✅ ACPI服务正在运行"
else
    echo "  ❌ ACPI服务未运行"
fi

if [ -f "/etc/acpi/events/panasonic-volume-up" ]; then
    echo "  ✅ 音量增加事件配置已创建"
else
    echo "  ❌ 音量增加事件配置创建失败"
fi

if [ -f "/etc/acpi/events/panasonic-volume-down" ]; then
    echo "  ✅ 音量减少事件配置已创建"
else
    echo "  ❌ 音量减少事件配置创建失败"
fi

if [ -f "/etc/acpi/panasonic-volume-interceptor.sh" ]; then
    echo "  ✅ 拦截器脚本已创建"
else
    echo "  ❌ 拦截器脚本创建失败"
fi

echo ""
echo "✅ ACPI音量键事件配置完成"
echo "📝 日志文件: /var/log/panasonic-volume-keys.log" 