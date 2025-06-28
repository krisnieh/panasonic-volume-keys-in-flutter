# Panasonic FZ-G1 音量键捕获项目

## 项目概述
为Panasonic FZ-G1工业平板电脑实现音量键捕获并转发到Flutter应用的完整解决方案。

## 技术架构
```
音量键物理按键 → ACPI事件 → Go服务 → Flutter应用
```

## 核心解决方案
1. **禁用PulseAudio** - 防止系统拦截音量键事件
2. **ACPI事件捕获** - 在系统级别拦截音量键
3. **Go桥接服务** - 监听ACPI事件并转发到Flutter
4. **Flutter集成** - 接收并处理音量键事件

## 目录结构
```
panasonic-volume-keys-project/
├── README.md                    # 项目说明
├── install.sh                   # 一键安装脚本
├── scripts/                     # 系统配置脚本
│   ├── disable_pulseaudio.sh    # 禁用PulseAudio
│   ├── setup_acpi.sh            # 配置ACPI事件
│   └── verify_setup.sh          # 验证配置
├── acpi-config/                 # ACPI配置文件
│   ├── panasonic-volume-up      # 音量增加事件配置
│   ├── panasonic-volume-down    # 音量减少事件配置
│   └── volume-interceptor.sh   # 音量键拦截器
├── go-bridge/                   # Go桥接服务
│   ├── main.go                  # 主程序
│   ├── go.mod                   # Go模块配置
│   └── volume_service.go        # 音量键服务
└── docs/                        # 技术文档
    ├── setup-guide.md           # 安装指南
    └── troubleshooting.md       # 故障排除
```

## 快速开始
```bash
# 1. 运行一键安装
sudo ./install.sh

# 2. 重启系统（推荐）
sudo reboot

# 3. 验证配置
./scripts/verify_setup.sh

# 4. 启动Go桥接服务
cd go-bridge && go run .

# 5. 在Flutter应用中集成音量键监听
```

## 支持的事件
- `VOLUME_UP` - 音量增加键
- `VOLUME_DOWN` - 音量减少键

## 系统要求
- Ubuntu 22.04 LTS
- Panasonic FZ-G1设备
- Go 1.19+
- Flutter 3.0+

## 许可证
MIT License 