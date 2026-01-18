import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebsocketService {
  static final WebsocketService _instance = WebsocketService._internal();
  factory WebsocketService() => _instance;
  WebsocketService._internal();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  Future<void> openWebSocketConnection(String url) async {
    if(_channel != null) return; //Prevent double connection

    debugPrint("Connecting to socket at: $url");
    _channel = WebSocketChannel.connect(Uri.parse(url));

    // Ensure connection is established
    try {
      await _channel!.ready;
      debugPrint("✅ WebSocket connected successfully");
    } catch (e) {
      debugPrint("❌ WebSocket connection failed: $e");
      _channel = null;
      return;
    }

    _channel!.stream.listen(
      (message) {
        debugPrint('WS received message: $message');
        _handleMessage(message);
      },
      onError: (error) {
        debugPrint('WS error: $error');
        close();
      },
      onDone: () {
        debugPrint('WS closed');
        _channel = null;
      },
    );

    debugPrint("WebSocket stream listener attached");
  }

  void send(dynamic data){
    if (_channel == null) {
      debugPrint("❌ Cannot send: WebSocket not connected");
      return;
    }

    try {
      final jsonString = jsonEncode(data);
      debugPrint("📤 Sending message to WS: $jsonString");
      _channel!.sink.add(jsonString);
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
    }
  }

  void _handleMessage(dynamic message){
    try {
      final decoded = jsonDecode(message) as Map<String, dynamic>;
      debugPrint("📥 Received and decoded message from socket");
      _controller.add(decoded);
    } catch (e) {
      debugPrint("❌ Error decoding message: $e");
    }
  }

  void close(){
    debugPrint("Closing WebSocket connection");
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }
}