# Panasonic FZ-G1 Volume Bridge Makefile

# 配置
BINARY_NAME=panasonic-volume-bridge
BUILD_DIR=build
INSTALL_DIR=/usr/local/bin
SERVICE_NAME=panasonic-volume-bridge.service
SERVICE_DIR=/etc/systemd/system

# Go构建标志
LDFLAGS=-ldflags "-X main.version=$(shell git describe --tags --always --dirty 2>/dev/null || echo 'dev')"

.PHONY: all build clean install uninstall service-install service-uninstall service-start service-stop service-restart service-status

# 默认目标
all: build

# 编译
build:
	@echo "🔨 编译 $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@go mod tidy
	@CGO_ENABLED=0 GOOS=linux go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) .
	@echo "✅ 编译完成: $(BUILD_DIR)/$(BINARY_NAME)"

# 清理
clean:
	@echo "🧹 清理构建文件..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ 清理完成"

# 安装二进制文件
install: build
	@echo "📦 安装 $(BINARY_NAME) 到 $(INSTALL_DIR)..."
	@sudo cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/
	@sudo chmod +x $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "✅ 安装完成"

# 卸载二进制文件
uninstall:
	@echo "🗑️  卸载 $(BINARY_NAME)..."
	@sudo rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "✅ 卸载完成"

# 安装系统服务
service-install: install
	@echo "🔧 安装系统服务..."
	@sudo cp ../scripts/$(SERVICE_NAME) $(SERVICE_DIR)/
	@sudo systemctl daemon-reload
	@echo "✅ 系统服务已安装"

# 卸载系统服务
service-uninstall:
	@echo "🗑️  卸载系统服务..."
	@sudo systemctl stop $(SERVICE_NAME) 2>/dev/null || true
	@sudo systemctl disable $(SERVICE_NAME) 2>/dev/null || true
	@sudo rm -f $(SERVICE_DIR)/$(SERVICE_NAME)
	@sudo systemctl daemon-reload
	@echo "✅ 系统服务已卸载"

# 启动服务
service-start:
	@echo "▶️  启动服务..."
	@sudo systemctl start $(SERVICE_NAME)
	@echo "✅ 服务已启动"

# 停止服务
service-stop:
	@echo "⏹️  停止服务..."
	@sudo systemctl stop $(SERVICE_NAME)
	@echo "✅ 服务已停止"

# 重启服务
service-restart:
	@echo "🔄 重启服务..."
	@sudo systemctl restart $(SERVICE_NAME)
	@echo "✅ 服务已重启"

# 查看服务状态
service-status:
	@echo "📊 服务状态:"
	@sudo systemctl status $(SERVICE_NAME)

# 启用服务（开机自启）
service-enable:
	@echo "🚀 启用开机自启..."
	@sudo systemctl enable $(SERVICE_NAME)
	@echo "✅ 开机自启已启用"

# 禁用服务（开机自启）
service-disable:
	@echo "🛑 禁用开机自启..."
	@sudo systemctl disable $(SERVICE_NAME)
	@echo "✅ 开机自启已禁用"

# 查看服务日志
service-logs:
	@echo "📋 服务日志:"
	@sudo journalctl -u $(SERVICE_NAME) -f

# 一键部署
deploy: service-install service-enable service-start
	@echo "🎉 部署完成！服务已启动并设置为开机自启"

# 完全卸载
remove: service-uninstall uninstall
	@echo "🗑️  完全卸载完成"

# 开发模式运行
dev:
	@echo "🧪 开发模式运行..."
	@go run .

# 测试
test:
	@echo "🧪 运行测试..."
	@go test -v ./...

# 显示帮助
help:
	@echo "Panasonic FZ-G1 Volume Bridge Makefile"
	@echo ""
	@echo "构建命令:"
	@echo "  make build        - 编译程序"
	@echo "  make clean        - 清理构建文件"
	@echo "  make install      - 安装二进制文件"
	@echo "  make uninstall    - 卸载二进制文件"
	@echo ""
	@echo "服务管理:"
	@echo "  make service-install   - 安装系统服务"
	@echo "  make service-uninstall - 卸载系统服务"
	@echo "  make service-start     - 启动服务"
	@echo "  make service-stop      - 停止服务"
	@echo "  make service-restart   - 重启服务"
	@echo "  make service-status    - 查看服务状态"
	@echo "  make service-enable    - 启用开机自启"
	@echo "  make service-disable   - 禁用开机自启"
	@echo "  make service-logs      - 查看服务日志"
	@echo ""
	@echo "快捷命令:"
	@echo "  make deploy       - 一键部署(安装+启用+启动)"
	@echo "  make remove       - 完全卸载"
	@echo "  make dev          - 开发模式运行"
	@echo "  make test         - 运行测试" 