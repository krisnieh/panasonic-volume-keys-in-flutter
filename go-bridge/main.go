package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
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
	fmt.Println("🚀 启动Panasonic FZ-G1音量键桥接服务")
	fmt.Println("=====================================")

	// 启动音量键监听服务
	volumeService := NewVolumeService("/var/log/panasonic-volume-keys.log")
	go volumeService.Start(broadcast)

	// 启动WebSocket广播处理
	go handleBroadcast()

	// HTTP路由
	http.HandleFunc("/ws", handleWebSocket)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/", handleHome)

	port := ":8080"
	fmt.Printf("🌐 服务已启动，监听端口: %s\n", port)
	fmt.Printf("📱 Flutter连接地址: ws://localhost%s/ws\n", port)
	fmt.Printf("🏥 健康检查: http://localhost%s/health\n", port)

	log.Fatal(http.ListenAndServe(port, nil))
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