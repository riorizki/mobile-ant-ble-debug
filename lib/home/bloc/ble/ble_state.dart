part of 'ble_cubit.dart';

enum BleStatus { initial, loading, success, failure }

enum BleAction {
  initial,
  onBluetoothStateChange,
  onScanStateChange,
  onDeviceStateChange,
  onCharacteristicChange,
  checkBluetoothIsOn,
  getConnectedDevices,
  startScan,
  stopScan,
  connect,
  disconnect,
  getDeviceStateChange,
  discoverService,
  streamBluetoothNotification,
  write,
}

@freezed
class BleState with _$BleState {
  const factory BleState({
    @Default(BleAction.initial) BleAction action,
    @Default(BleStatus.initial) BleStatus status,
    @Default(BluetoothState.unknown) BluetoothState bluetoothState,
    @Default(false) bool hasConnected,
    @Default(false) bool isScanning,
    @Default(BluetoothDeviceState.disconnected)
        BluetoothDeviceState bluetoothDeviceState,
    @Default([]) List<int> rawData,
    BluetoothDevice? bluetoothDevice,
    BluetoothCharacteristic? bluetoothCharacteristic,
    String? errorMessage,
  }) = _BleState;
}
