import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _connection;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Function(Map<String, dynamic>)? onNotificationReceived;

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _storage.read(key: 'token');
    if (token == null) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConfig.baseUrl}/hubs/notifications',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        onNotificationReceived?.call(data);
      }
    });

    try {
      await _connection!.start();
    } catch (e) {
      // SignalR connection failed silently
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}