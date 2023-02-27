part of 'second_ble_cubit.dart';

enum SecondBleStatus { initial, loading, success, failure }

enum SecondBleAction {
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
class SecondBleState with _$SecondBleState {
  const factory SecondBleState({
    @Default(SecondBleAction.initial) SecondBleAction action,
    @Default(SecondBleStatus.initial) SecondBleStatus status,
    @Default(BluetoothState.unknown) BluetoothState bluetoothState,
    @Default(false) bool hasConnected,
    @Default(false) bool isScanning,
    @Default(BluetoothDeviceState.disconnected)
        BluetoothDeviceState bluetoothDeviceState,
    @Default([]) List<int> rawData,
    BluetoothDevice? bluetoothDevice,
    BluetoothCharacteristic? bluetoothCharacteristic,
    String? errorMessage,
  }) = _SecondBleState;
}
