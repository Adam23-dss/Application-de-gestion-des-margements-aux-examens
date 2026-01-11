import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend1/core/constants/app_constants.dart';

class SocketClient {
  WebSocketChannel? _channel;
  final List<Function(Map<String, dynamic>)> _listeners = [];

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.authTokenKey);
      
      String url = ApiEndpoints.wsUrl;
      if (token != null) {
        url += '?token=$token';
      }
      
      _channel = IOWebSocketChannel.connect(url);
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _notifyListeners(data);
          } catch (e) {
            print('Erreur de parsing WebSocket: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          print('WebSocket disconnected');
          _reconnect();
        },
      );
      
      print('✅ WebSocket connecté: $url');
    } catch (e) {
      print('❌ Erreur de connexion WebSocket: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (var listener in _listeners) {
      listener(data);
    }
  }

  bool get isConnected => _channel != null;
}