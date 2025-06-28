# Panasonic FZ-G1 音量键捕获项目

## 项目概述
为Panasonic FZ-G1工业平板电脑实现音量键捕获并转发到Flutter应用的完整解决方案。本项目提供一键安装、系统服务管理和完整的生命周期支持。

## 技术架构
```
音量键物理按键 → ACPI事件 → Go系统服务 → WebSocket → Flutter应用
```

## 核心特性
1. **🔧 一键安装** - 自动化安装和配置
2. **🚀 系统服务** - 编译后的二进制文件作为systemd服务运行
3. **📊 服务管理** - 完整的服务启动、停止、重启功能
4. **🌐 WebSocket通信** - 实时音量键事件推送
5. **🏥 健康检查** - HTTP健康检查和状态监控
6. **📋 日志记录** - 完整的日志记录和监控
7. **🗑️ 完整卸载** - 支持完全卸载和配置恢复

## 目录结构
```
panasonic-volume-keys-in-flutter/
├── README.md                           # 项目说明
├── install.sh                          # 一键安装脚本 ⭐
├── uninstall.sh                        # 一键卸载脚本 ⭐
├── scripts/                            # 系统配置脚本
│   ├── disable_pulseaudio.sh           # 禁用PulseAudio
│   ├── setup_acpi.sh                   # 配置ACPI事件
│   ├── verify_setup.sh                 # 验证配置
│   └── panasonic-volume-bridge.service # systemd服务配置 ⭐
├── acpi-config/                        # ACPI配置文件
│   ├── panasonic-volume-up             # 音量增加事件配置
│   ├── panasonic-volume-down           # 音量减少事件配置
│   └── volume-interceptor.sh          # 音量键拦截器
├── go-bridge/                          # Go桥接服务 ⭐
│   ├── main.go                         # 主程序（支持优雅关闭）
│   ├── volume_service.go               # 音量键服务
│   ├── go.mod                          # Go模块配置
│   └── Makefile                        # 构建和服务管理 ⭐
└── docs/                               # 技术文档
    ├── setup-guide.md                  # 安装指南
    └── troubleshooting.md              # 故障排除
```

## 🚀 快速开始

### 一键安装
```bash
# 1. 克隆项目
git clone <repository-url>
cd panasonic-volume-keys-in-flutter

# 2. 运行一键安装（自动完成所有配置）
sudo ./install.sh

# 3. 验证服务状态
sudo systemctl status panasonic-volume-bridge

# 4. 测试连接
curl http://localhost:8080/health
```

安装完成后，服务将：
- ✅ 自动启动
- ✅ 设置为开机自启
- ✅ 监听端口8080
- ✅ 提供WebSocket接口

### Flutter应用集成
```dart
// 连接到WebSocket
WebSocketChannel channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8080/ws'),
);

// 监听音量键事件
channel.stream.listen((message) {
  final data = json.decode(message);
  if (data['type'] == 'VOLUME_UP') {
    // 处理音量增加
  } else if (data['type'] == 'VOLUME_DOWN') {
    // 处理音量减少
  }
});
```

## 🔧 服务管理

### 使用systemctl管理
```bash
# 查看服务状态
sudo systemctl status panasonic-volume-bridge

# 启动服务
sudo systemctl start panasonic-volume-bridge

# 停止服务
sudo systemctl stop panasonic-volume-bridge

# 重启服务
sudo systemctl restart panasonic-volume-bridge

# 查看服务日志
sudo journalctl -u panasonic-volume-bridge -f

# 启用开机自启
sudo systemctl enable panasonic-volume-bridge

# 禁用开机自启
sudo systemctl disable panasonic-volume-bridge
```

### 使用Makefile管理
```bash
cd go-bridge

# 查看所有可用命令
make help

# 编译项目
make build

# 安装服务
make deploy          # 一键部署（编译+安装+启动+启用）

# 服务管理
make service-start   # 启动服务
make service-stop    # 停止服务
make service-restart # 重启服务
make service-status  # 查看状态
make service-logs    # 查看日志

# 开发调试
make dev            # 开发模式运行
make test           # 运行测试
```

## 📊 监控和调试

### 健康检查
```bash
# HTTP健康检查
curl http://localhost:8080/health

# 响应示例
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00Z",
  "clients": 1,
  "service": "panasonic-volume-bridge"
}
```

### Web管理界面
访问 `http://localhost:8080` 查看：
- 服务状态
- 连接的客户端数量
- 实时音量键事件监控

### 日志文件位置
- **服务日志**: `sudo journalctl -u panasonic-volume-bridge -f`
- **音量键日志**: `sudo tail -f /var/log/panasonic-volume-keys.log`

## 🗑️ 卸载

### 完整卸载
```bash
# 运行卸载脚本
sudo ./uninstall.sh

# 卸载过程将：
# 1. 停止并禁用服务
# 2. 删除系统服务文件
# 3. 删除二进制文件
# 4. 清理构建文件
# 5. 可选：删除日志文件
# 6. 可选：恢复ACPI和PulseAudio配置
```

## 📋 支持的事件

### WebSocket事件格式
```json
{
  "type": "VOLUME_UP",           // 或 "VOLUME_DOWN"
  "timestamp": "2024-01-01T12:00:00Z",
  "device": "panasonic-fz-g1"
}
```

### 连接事件
```json
{
  "type": "CONNECTED",
  "timestamp": "2024-01-01T12:00:00Z",
  "device": "panasonic-fz-g1"
}
```

## 🛠️ 系统要求

- **操作系统**: Ubuntu 22.04 LTS (推荐)
- **硬件**: Panasonic FZ-G1工业平板电脑
- **软件依赖**:
  - Go 1.19+
  - make
  - systemctl (systemd)
  - curl (用于健康检查)
- **Flutter**: 3.0+ (客户端应用)

## ⚡ 性能特性

- **资源占用**: 低内存占用（<20MB）
- **启动时间**: 快速启动（<2秒）
- **优雅关闭**: 支持SIGTERM和SIGINT信号
- **自动重启**: 服务异常时自动重启
- **连接管理**: 自动清理断开的WebSocket连接

## 🔍 故障排除

### 常见问题
1. **服务无法启动**
   ```bash
   sudo journalctl -u panasonic-volume-bridge -n 50
   ```

2. **音量键无响应**
   ```bash
   sudo tail -f /var/log/panasonic-volume-keys.log
   ```

3. **WebSocket连接失败**
   ```bash
   curl http://localhost:8080/health
   netstat -tlnp | grep 8080
   ```

4. **重新安装**
   ```bash
   sudo ./uninstall.sh
   sudo ./install.sh
   ```

## 🤝 贡献

欢迎提交Issue和Pull Request！

## �� 许可证

MIT License 