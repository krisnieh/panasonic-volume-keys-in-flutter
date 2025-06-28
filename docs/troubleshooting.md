# 故障排除指南

## 常见问题

### 1. PulseAudio仍在拦截音量键

**症状**: 按音量键时系统音量发生变化，ACPI日志无记录

**解决方案**:
```bash
# 检查PulseAudio状态
pgrep pulseaudio

# 如果仍有进程，强制停止
sudo pkill pulseaudio
systemctl --user mask pulseaudio.service pulseaudio.socket

# 重启系统
sudo reboot
```

### 2. ACPI事件不生效

**症状**: 按音量键没有任何日志记录

**检查步骤**:
```bash
# 检查ACPI服务状态
systemctl status acpid

# 检查ACPI配置文件
ls -la /etc/acpi/events/panasonic-*

# 手动测试ACPI监听
sudo acpi_listen
```

**解决方案**:
```bash
# 重新配置ACPI
sudo ./scripts/setup_acpi.sh

# 重启ACPI服务
sudo systemctl restart acpid
```

### 3. Go服务无法启动

**症状**: `go run .` 报错

**检查Go环境**:
```bash
go version
go env GOPATH
```

**解决方案**:
```bash
# 安装Go依赖
go mod tidy

# 检查网络连接
ping proxy.golang.org

# 使用国内代理
go env -w GOPROXY=https://goproxy.cn,direct
```

### 4. WebSocket连接失败

**症状**: Flutter应用无法连接到Go服务

**检查网络**:
```bash
# 检查端口占用
netstat -tlnp | grep 8080

# 测试连接
curl http://localhost:8080/health
```

**防火墙设置**:
```bash
# Ubuntu防火墙
sudo ufw allow 8080
sudo ufw status

# 检查iptables
sudo iptables -L
```

### 5. 权限问题

**症状**: 日志文件无法写入，设备无法访问

**解决方案**:
```bash
# 修复日志文件权限
sudo chmod 666 /var/log/panasonic-volume-keys.log

# 修复ACPI脚本权限
sudo chmod 755 /etc/acpi/panasonic-volume-interceptor.sh

# 添加用户到input组
sudo usermod -a -G input $USER
```

### 6. 设备检测问题

**症状**: 找不到Panasonic设备

**检查输入设备**:
```bash
# 列出所有输入设备
cat /proc/bus/input/devices

# 检查event设备
ls -la /dev/input/event*

# 测试设备响应
sudo evtest /dev/input/event4
```

## 调试工具

### 1. 实时监控脚本

```bash
#!/bin/bash
echo "🔍 实时监控 Panasonic FZ-G1 音量键"
echo "==================================="

# 并行监控多个来源
{
    echo "监听ACPI事件..." 
    sudo acpi_listen &
    
    echo "监听日志文件..."
    sudo tail -f /var/log/panasonic-volume-keys.log &
    
    echo "监听Go服务日志..."
    if systemctl is-active --quiet panasonic-volume-bridge; then
        sudo journalctl -u panasonic-volume-bridge -f &
    fi
    
    wait
}
```

### 2. 系统状态检查

```bash
#!/bin/bash
echo "📊 系统状态检查"
echo "=============="

echo "PulseAudio状态:"
pgrep pulseaudio || echo "  ✅ 未运行"

echo ""
echo "ACPI服务状态:"
systemctl is-active acpid && echo "  ✅ 运行中" || echo "  ❌ 未运行"

echo ""
echo "Go服务状态:"
systemctl is-active panasonic-volume-bridge && echo "  ✅ 运行中" || echo "  ⚠️  未运行"

echo ""
echo "日志文件状态:"
if [ -f "/var/log/panasonic-volume-keys.log" ]; then
    echo "  ✅ 存在，大小: $(du -h /var/log/panasonic-volume-keys.log | cut -f1)"
else
    echo "  ❌ 不存在"
fi

echo ""
echo "网络服务状态:"
curl -s http://localhost:8080/health > /dev/null && echo "  ✅ Go服务可访问" || echo "  ❌ Go服务不可访问"
```

### 3. 完整重置脚本

```bash
#!/bin/bash
echo "🔄 完整重置 Panasonic FZ-G1 配置"
echo "==============================="

# 停止所有相关服务
sudo systemctl stop panasonic-volume-bridge 2>/dev/null
sudo systemctl stop acpid
sudo pkill pulseaudio

# 清理配置文件
sudo rm -f /etc/acpi/events/panasonic-volume-*
sudo rm -f /etc/acpi/panasonic-volume-interceptor.sh
sudo rm -f /var/log/panasonic-volume-keys.log

# 重新运行安装
sudo ./install.sh

echo "✅ 重置完成，建议重启系统"
```

## 性能优化

### 1. 减少日志文件大小

```bash
# 定期清理日志（添加到crontab）
0 0 * * * truncate -s 100K /var/log/panasonic-volume-keys.log
```

### 2. 优化Go服务

```bash
# 编译为二进制文件
cd go-bridge
go build -o panasonic-volume-bridge .

# 更新系统服务配置
sudo sed -i 's/go run \./\.\/panasonic-volume-bridge/' /etc/systemd/system/panasonic-volume-bridge.service
sudo systemctl daemon-reload
```

## 联系支持

如果问题仍未解决，请提供以下信息：

1. 系统信息: `uname -a`
2. Go版本: `go version`
3. 设备信息: `cat /proc/bus/input/devices | grep -A 5 -B 5 Panasonic`
4. 服务状态: `./scripts/verify_setup.sh`
5. 完整日志: `sudo journalctl -u panasonic-volume-bridge --since today` 