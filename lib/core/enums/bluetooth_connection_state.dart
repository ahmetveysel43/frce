enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  unknown,
}

extension BluetoothConnectionStateExtension on BluetoothConnectionState {
  String get displayName {
    switch (this) {
      case BluetoothConnectionState.disconnected:
        return 'Bağlantı Kesildi';
      case BluetoothConnectionState.connecting:
        return 'Bağlanıyor';
      case BluetoothConnectionState.connected:
        return 'Bağlı';
      case BluetoothConnectionState.error:
        return 'Hata';
      case BluetoothConnectionState.unknown:
        return 'Bilinmiyor';
    }
  }

  bool get isConnected => this == BluetoothConnectionState.connected;
  bool get isConnecting => this == BluetoothConnectionState.connecting;
  bool get hasError => this == BluetoothConnectionState.error;
}