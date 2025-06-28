# Flutter集成指南

## WebSocket连接

在Flutter应用中添加以下依赖：

```yaml
dependencies:
  web_socket_channel: ^2.4.0
  get: ^4.6.5
```

## 音量键服务

创建音量键服务类：

```dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';

class VolumeKeyService extends GetxService {
  WebSocketChannel? _channel;
  final RxString lastEvent = ''.obs;
  final RxBool isConnected = false.obs;
  
  // 连接到Go桥接服务
  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080/ws')
      );
      
      isConnected.value = true;
      print('🔗 已连接到音量键桥接服务');
      
      // 监听音量键事件
      _channel!.stream.listen(
        (data) {
          final event = jsonDecode(data);
          _handleVolumeEvent(event);
        },
        onError: (error) {
          print('❌ WebSocket错误: $error');
          isConnected.value = false;
        },
        onDone: () {
          print('🔌 WebSocket连接关闭');
          isConnected.value = false;
        },
      );
      
    } catch (e) {
      print('❌ 连接失败: $e');
      isConnected.value = false;
    }
  }
  
  // 处理音量键事件
  void _handleVolumeEvent(Map<String, dynamic> event) {
    final type = event['type'];
    final timestamp = event['timestamp'];
    
    print('🎵 收到音量键事件: $type');
    lastEvent.value = type;
    
    switch (type) {
      case 'VOLUME_UP':
        _onVolumeUp();
        break;
      case 'VOLUME_DOWN':
        _onVolumeDown();
        break;
      case 'CONNECTED':
        print('✅ 服务连接成功');
        break;
      default:
        print('ℹ️  其他事件: $type');
    }
  }
  
  // 音量增加处理
  void _onVolumeUp() {
    print('🔊 音量增加');
    // 在这里添加你的业务逻辑
    Get.snackbar('音量键', '音量增加');
  }
  
  // 音量减少处理
  void _onVolumeDown() {
    print('🔉 音量减少');
    // 在这里添加你的业务逻辑
    Get.snackbar('音量键', '音量减少');
  }
  
  // 发送心跳
  void sendHeartbeat() {
    if (_channel != null && isConnected.value) {
      _channel!.sink.add(jsonEncode({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }
  
  // 断开连接
  void disconnect() {
    _channel?.sink.close();
    isConnected.value = false;
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
```

## 控制器集成

在你的控制器中使用音量键服务：

```dart
class HomeController extends GetxController {
  late VolumeKeyService volumeKeyService;
  
  @override
  void onInit() {
    super.onInit();
    volumeKeyService = Get.find<VolumeKeyService>();
    
    // 连接音量键服务
    volumeKeyService.connect();
    
    // 定期发送心跳
    Timer.periodic(Duration(seconds: 30), (timer) {
      volumeKeyService.sendHeartbeat();
    });
  }
  
  @override
  void onClose() {
    volumeKeyService.disconnect();
    super.onClose();
  }
}
```

## 主应用初始化

在`main.dart`中注册服务：

```dart
void main() {
  // 注册音量键服务
  Get.put(VolumeKeyService());
  
  runApp(MyApp());
}
```

## UI示例

显示音量键状态的UI组件：

```dart
class VolumeKeyStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final volumeService = Get.find<VolumeKeyService>();
    
    return Obx(() => Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  volumeService.isConnected.value 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                  color: volumeService.isConnected.value 
                    ? Colors.green 
                    : Colors.red,
                ),
                SizedBox(width: 8),
                Text(volumeService.isConnected.value 
                  ? '音量键服务已连接' 
                  : '音量键服务未连接'),
              ],
            ),
            if (volumeService.lastEvent.value.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '最后事件: ${volumeService.lastEvent.value}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
```

## 自动重连

实现自动重连机制：

```dart
class VolumeKeyService extends GetxService {
  Timer? _reconnectTimer;
  
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!isConnected.value) {
        print('🔄 尝试重连音量键服务...');
        connect();
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void onClose() {
    _reconnectTimer?.cancel();
    disconnect();
    super.onClose();
  }
}
```

## 测试

1. 启动Go桥接服务：
```bash
cd go-bridge && go run .
```

2. 启动Flutter应用

3. 按音量键测试事件接收

4. 检查控制台输出和Snackbar显示 