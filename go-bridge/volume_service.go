package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
)

// VolumeService 音量键监听服务
type VolumeService struct {
	logFile string
	watcher *fsnotify.Watcher
}

// NewVolumeService 创建音量键服务
func NewVolumeService(logFile string) *VolumeService {
	return &VolumeService{
		logFile: logFile,
	}
}

// Start 启动监听服务
func (vs *VolumeService) Start(broadcast chan<- VolumeEvent) error {
	fmt.Printf("🎵 启动音量键监听服务: %s\n", vs.logFile)

	// 创建文件监听器
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return fmt.Errorf("创建文件监听器失败: %v", err)
	}
	vs.watcher = watcher

	// 确保日志文件存在
	if err := vs.ensureLogFile(); err != nil {
		return fmt.Errorf("创建日志文件失败: %v", err)
	}

	// 添加文件监听
	err = watcher.Add(vs.logFile)
	if err != nil {
		return fmt.Errorf("添加文件监听失败: %v", err)
	}

	// 读取现有日志内容
	go vs.readExistingLogs(broadcast)

	// 监听文件变化
	go vs.watchFileChanges(broadcast)

	return nil
}

// ensureLogFile 确保日志文件存在
func (vs *VolumeService) ensureLogFile() error {
	if _, err := os.Stat(vs.logFile); os.IsNotExist(err) {
		file, err := os.Create(vs.logFile)
		if err != nil {
			return err
		}
		file.Close()
		fmt.Printf("📝 创建日志文件: %s\n", vs.logFile)
	}
	return nil
}

// readExistingLogs 读取现有日志
func (vs *VolumeService) readExistingLogs(broadcast chan<- VolumeEvent) {
	file, err := os.Open(vs.logFile)
	if err != nil {
		fmt.Printf("❌ 打开日志文件失败: %v\n", err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if event := vs.parseLogLine(line); event != nil {
			broadcast <- *event
		}
	}
}

// watchFileChanges 监听文件变化
func (vs *VolumeService) watchFileChanges(broadcast chan<- VolumeEvent) {
	for {
		select {
		case event, ok := <-vs.watcher.Events:
			if !ok {
				return
			}
			
			// 只处理写入事件
			if event.Op&fsnotify.Write == fsnotify.Write {
				vs.handleFileWrite(broadcast)
			}
			
		case err, ok := <-vs.watcher.Errors:
			if !ok {
				return
			}
			fmt.Printf("❌ 文件监听错误: %v\n", err)
		}
	}
}

// handleFileWrite 处理文件写入
func (vs *VolumeService) handleFileWrite(broadcast chan<- VolumeEvent) {
	// 等待一小段时间确保文件写入完成
	time.Sleep(10 * time.Millisecond)
	
	file, err := os.Open(vs.logFile)
	if err != nil {
		fmt.Printf("❌ 打开日志文件失败: %v\n", err)
		return
	}
	defer file.Close()

	// 读取最后几行
	lines := vs.readLastLines(file, 5)
	for _, line := range lines {
		if event := vs.parseLogLine(line); event != nil {
			fmt.Printf("🔑 检测到音量键事件: %s\n", event.Type)
			broadcast <- *event
		}
	}
}

// readLastLines 读取文件最后几行
func (vs *VolumeService) readLastLines(file *os.File, n int) []string {
	var lines []string
	scanner := bufio.NewScanner(file)
	
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
		if len(lines) > n {
			lines = lines[1:] // 保持最后n行
		}
	}
	
	return lines
}

// parseLogLine 解析日志行
func (vs *VolumeService) parseLogLine(line string) *VolumeEvent {
	// 日志格式: [2025-06-28 17:09:10] VOLUME_DOWN: button/volumedown
	line = strings.TrimSpace(line)
	if line == "" {
		return nil
	}

	// 查找时间戳
	if !strings.HasPrefix(line, "[") {
		return nil
	}

	timestampEnd := strings.Index(line, "]")
	if timestampEnd == -1 {
		return nil
	}

	timestampStr := line[1:timestampEnd]
	timestamp, err := time.Parse("2006-01-02 15:04:05", timestampStr)
	if err != nil {
		fmt.Printf("⚠️  解析时间戳失败: %v\n", err)
		timestamp = time.Now()
	}

	// 查找事件类型
	content := strings.TrimSpace(line[timestampEnd+1:])
	
	var eventType string
	if strings.Contains(content, "VOLUME_UP") {
		eventType = "VOLUME_UP"
	} else if strings.Contains(content, "VOLUME_DOWN") {
		eventType = "VOLUME_DOWN"
	} else {
		return nil // 不是音量键事件
	}

	return &VolumeEvent{
		Type:      eventType,
		Timestamp: timestamp,
		Device:    "panasonic-fz-g1",
	}
}

// Stop 停止服务
func (vs *VolumeService) Stop() error {
	if vs.watcher != nil {
		return vs.watcher.Close()
	}
	return nil
} 