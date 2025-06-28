package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/websocket"
)

// VolumeEvent 音量键事件结构
type VolumeEvent struct {
	Type      string    `json:"type"`      // VOLUME_UP 或 VOLUME_DOWN
	Timestamp time.Time `json:"timestamp"`
	Device    string    `json:"device"`    // panasonic-fz-g1
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // 允许跨域连接
	},
}

// WebSocket连接管理
var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan VolumeEvent)

func main() {
	// 设置日志格式
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	
	fmt.Println("🚀 启动Panasonic FZ-G1音量键桥接服务")
	fmt.Println("=====================================")
	log.Println("服务启动中...")

	// 启动音量键监听服务
	volumeService := NewVolumeService("/var/log/panasonic-volume-keys.log")
	go func() {
		if err := volumeService.Start(broadcast); err != nil {
			log.Fatalf("音量键服务启动失败: %v", err)
		}
	}()

	// 启动WebSocket广播处理
	go handleBroadcast()

	// HTTP路由
	http.HandleFunc("/ws", handleWebSocket)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/", handleHome)

	// 创建HTTP服务器
	port := ":8080"
	server := &http.Server{
		Addr:         port,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 启动服务器
	go func() {
		fmt.Printf("🌐 服务已启动，监听端口: %s\n", port)
		fmt.Printf("📱 Flutter连接地址: ws://localhost%s/ws\n", port)
		fmt.Printf("🏥 健康检查: http://localhost%s/health\n", port)
		log.Printf("HTTP服务器启动在端口%s", port)
		
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("HTTP服务器启动失败: %v", err)
		}
	}()

	// 等待中断信号以优雅地关闭服务器
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	
	log.Println("收到退出信号，开始优雅关闭...")
	fmt.Println("🛑 服务正在关闭...")

	// 创建关闭上下文，30秒超时
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 关闭音量键服务
	if err := volumeService.Stop(); err != nil {
		log.Printf("关闭音量键服务失败: %v", err)
	}

	// 关闭所有WebSocket连接
	for client := range clients {
		client.Close()
	}

	// 关闭HTTP服务器
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("HTTP服务器关闭失败: %v", err)
	}

	log.Println("服务已关闭")
	fmt.Println("✅ 服务已安全关闭")
}

// handleWebSocket 处理WebSocket连接
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket升级失败: %v", err)
		return
	}
	defer conn.Close()

	// 注册客户端
	clients[conn] = true
	fmt.Printf("📱 新的Flutter客户端连接: %s\n", conn.RemoteAddr())

	// 发送欢迎消息
	welcome := VolumeEvent{
		Type:      "CONNECTED",
		Timestamp: time.Now(),
		Device:    "panasonic-fz-g1",
	}
	conn.WriteJSON(welcome)

	// 保持连接并处理客户端消息
	for {
		var msg map[string]interface{}
		err := conn.ReadJSON(&msg)
		if err != nil {
			fmt.Printf("📱 客户端断开连接: %s\n", conn.RemoteAddr())
			delete(clients, conn)
			break
		}
		
		// 处理客户端心跳等消息
		if msgType, ok := msg["type"].(string); ok && msgType == "ping" {
			pong := map[string]interface{}{
				"type":      "pong",
				"timestamp": time.Now(),
			}
			conn.WriteJSON(pong)
		}
	}
}

// handleBroadcast 处理广播消息到所有客户端
func handleBroadcast() {
	for {
		event := <-broadcast
		fmt.Printf("🔊 广播音量键事件: %s\n", event.Type)
		
		// 发送到所有连接的客户端
		for client := range clients {
			err := client.WriteJSON(event)
			if err != nil {
				fmt.Printf("❌ 发送到客户端失败: %v\n", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

// handleHealth 健康检查接口
func handleHealth(w http.ResponseWriter, r *http.Request) {
	health := map[string]interface{}{
		"status":    "ok",
		"timestamp": time.Now(),
		"clients":   len(clients),
		"service":   "panasonic-volume-bridge",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(health)
}

// handleHome 首页
func handleHome(w http.ResponseWriter, r *http.Request) {
	html := `
<!DOCTYPE html>
<html>
<head>
    <title>Panasonic FZ-G1 音量键桥接服务</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>🎛️ Panasonic FZ-G1 音量键桥接服务</h1>
    <p><strong>服务状态:</strong> 运行中</p>
    <p><strong>连接的客户端:</strong> <span id="clients">0</span></p>
    <p><strong>WebSocket地址:</strong> <code>ws://localhost:8080/ws</code></p>
    
    <h2>📊 实时事件监控</h2>
    <div id="events" style="border: 1px solid #ccc; padding: 10px; height: 300px; overflow-y: scroll;">
        等待音量键事件...
    </div>
    
    <script>
        const ws = new WebSocket('ws://localhost:8080/ws');
        const eventsDiv = document.getElementById('events');
        const clientsSpan = document.getElementById('clients');
        
        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            const time = new Date(data.timestamp).toLocaleTimeString();
            const eventText = time + ' - ' + data.type + '\n';
            eventsDiv.textContent += eventText;
            eventsDiv.scrollTop = eventsDiv.scrollHeight;
        };
        
        // 定期更新客户端数量
        setInterval(async () => {
            try {
                const response = await fetch('/health');
                const health = await response.json();
                clientsSpan.textContent = health.clients;
            } catch (e) {
                console.error('获取健康状态失败:', e);
            }
        }, 5000);
    </script>
</body>
</html>
`
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(html))
} 