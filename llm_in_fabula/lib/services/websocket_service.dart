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

  void openWebSocketConnection(String url){
    if(_channel != null) return; //Prevent double connection

    debugPrint("Connecting to socket");
    _channel = WebSocketChannel.connect(Uri.parse(url));

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
        close();
      },
    );
  }

  void send(dynamic data){
    if (_channel == null) return;

    debugPrint("Sending message to WS");
    _channel!.sink.add(jsonEncode(data));
  }

  void _handleMessage(dynamic message){
    final decoded = jsonDecode(message) as Map<String, dynamic>;
    debugPrint("Received message from socket");
    _controller.add(decoded);
    //TODO: non riaggiungere più volte lo stesso player
  }

  void dispose(){
    _controller.close();
    close();
  }

  void close(){
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }
}