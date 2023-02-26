import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/subjects.dart';

class QuestBle {
  final _ble = FlutterBluePlus.instance;

  final _bluetoothStateController = BehaviorSubject<BluetoothState>();
  BehaviorSubject<BluetoothState> get bluetoothStateController =>
      _bluetoothStateController;

  final _scanStateController = BehaviorSubject<bool>();
  BehaviorSubject<bool> get scanStateController => _scanStateController;

  StreamSubscription<BluetoothState>? _stateSubscription;
  StreamSubscription<bool>? _scanStateSubscription;

  BluetoothState _bluetoothState = BluetoothState.unknown;
  BluetoothState get bluetoothState => _bluetoothState;

  bool _isScanning = false;

  QuestBle() {
    streamBlueoothState();
    streamBluetoothScanState();
  }

  void _log(Object object) {
    if (kDebugMode) print(object);
  }

  /// Checks whether the device supports Bluetooth
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _ble.isAvailable;
      return isAvailable;
    } catch (e) {
      _log('[isAvailable] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Checks if Bluetooth functionality is turned on
  Future<bool> isBluetoothOn() async {
    try {
      final isOn = await _ble.isOn;
      return isOn;
    } catch (e) {
      _log('[isBluetoothOn] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Stream for bluetooth state changes
  void streamBlueoothState() async {
    await _stateSubscription?.cancel();
    _stateSubscription = _ble.state.listen(
      (event) {
        _bluetoothState = event;
        _bluetoothStateController.add(event);
        _log('[streamBlueoothState] Bluetooth state: $event');
      },
    );
  }

  /// Stream for bluetooth scan state
  void streamBluetoothScanState() async {
    await _scanStateSubscription?.cancel();
    _scanStateSubscription = _ble.isScanning.listen(
      (event) {
        _isScanning = event;
        _scanStateController.add(event);
        _log('[streamBluetoothScanState] Scan state: $event');
      },
    );
  }

  /// Get current connected device
  Future<List<BluetoothDevice>> getConnectedDevices() async {
    try {
      final devices = await _ble.connectedDevices;
      return devices;
    } catch (e) {
      _log('[getConnectedDevices] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Start scan for devices
  ///
  /// Will return [Stream<ScanResult>]
  Future<Stream<ScanResult>> startScan({
    ScanMode scanMode = ScanMode.lowLatency,
    List<Guid> withServices = const [],
    List<Guid> withDevices = const [],
    List<String> macAddresses = const [],
    Duration? timeout,
    bool allowDuplicates = false,
  }) async {
    if (_isScanning) {
      _log('[startScan] Bluetooth currently on scan, will stop and start scan');
      await stopScan();
    }

    return _ble.scan(
      allowDuplicates: allowDuplicates,
      macAddresses: macAddresses,
      scanMode: scanMode,
      timeout: timeout,
      withDevices: withDevices,
      withServices: withServices,
    );
  }

  /// Stop bluetooth scanning
  Future<void> stopScan() async {
    if (_isScanning == false) {
      _log('[stopScan] Bluetooth is not scanning, will return.');
      return;
    }

    try {
      await _ble.stopScan();
      _log('[stopScan] Bluetooth scan stopped');
    } catch (e) {
      _log('[stopScan] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Connect to selected bluetooth device
  Future<void> connect({
    required BluetoothDevice device,
    Duration? timeout,
    bool autoConnect = true,
  }) async {
    try {
      await device.connect(autoConnect: autoConnect, timeout: timeout);
      _log('[connect] Success connect to: ${device.name}');
    } catch (e) {
      _log('[connect] Error: ${e.toString()}');
      final error = e.toString().toLowerCase();
      if (error.contains('reconnect_error, error when reconnecting')) {
        _log('[connect] gonna disconnect and reconnect');
        await disconnect(device: device);
        await connect(device: device);
      }

      return Future.error(e);
    }
  }

  /// Disconnect from device
  Future<void> disconnect({
    required BluetoothDevice device,
  }) async {
    try {
      await device.disconnect();
      _log('[disconnect] Success disconnect from: ${device.name}');
    } catch (e) {
      _log('[disconnect] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Stream for device state
  Stream<BluetoothDeviceState> streamDeviceState({
    required BluetoothDevice device,
  }) {
    return device.state;
  }

  /// Discover service from connected device
  Future<List<BluetoothService>> discoverService({
    required BluetoothDevice device,
  }) async {
    try {
      final services = await device.discoverServices();
      _log('[discoverService] Success discover service');
      return services;
    } catch (e) {
      _log('[discoverService] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Write characteristic to device
  Future<void> writeCharacteristic({
    required BluetoothCharacteristic characteristic,
    required List<int> data,
  }) async {
    try {
      await characteristic.write(data);
      _log('[writeCharacteristic] Success write characteristic');
    } catch (e) {
      _log('[writeCharacteristic] Error: ${e.toString()}');
      return Future.error(e);
    }
  }

  /// Subscribe for incoming data from characteristic
  Future<Stream<List<int>>> subscribeNotification({
    required BluetoothCharacteristic characteristic,
  }) async {
    if (characteristic.isNotifying) {
      _log('[subscribeNotification] Characteristic already subscribed.'
          ' will stop and re-subscribe');
      await characteristic.setNotifyValue(false);
    }

    await characteristic.setNotifyValue(true);
    _log('[subscribeNotification] Success subscribe characteristic');
    return characteristic.value;
  }
}
