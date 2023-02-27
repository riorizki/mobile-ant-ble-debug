import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../packages/quest_ble/quest_ble.dart';

part 'second_ble_cubit.freezed.dart';
part 'second_ble_state.dart';

class SecondBleCubit extends Cubit<SecondBleState> {
  SecondBleCubit({
    required QuestBle questBle,
  })  : _questBle = questBle,
        super(const SecondBleState()) {
    // Bluetooth state
    _bluetoothStateSubscription = _questBle.bluetoothStateController.listen(
      (value) {
        _onBluetoothStateChange(value);
      },
    );

    // Scan state
    _scanSubscription = _questBle.scanStateController.listen(
      (value) {
        _onScanStateChange(value);
      },
    );
  }

  final QuestBle _questBle;
  late StreamSubscription<BluetoothState> _bluetoothStateSubscription;
  late StreamSubscription<bool> _scanSubscription;
  StreamSubscription<ScanResult>? _scanResultSubscription;
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _characteristicSubscription;

  String kServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  String kCharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  @override
  Future<void> close() async {
    await _bluetoothStateSubscription.cancel();
    await _scanSubscription.cancel();
    await _scanResultSubscription?.cancel();
    await _deviceStateSubscription?.cancel();
    await _characteristicSubscription?.cancel();

    return super.close();
  }

  void _log(Object object) {
    if (kDebugMode) print(object);
  }

  void _onScanStateChange(bool value) {
    emit(state.copyWith(
      action: SecondBleAction.onScanStateChange,
      isScanning: value,
    ));
  }

  void _onBluetoothStateChange(BluetoothState value) {
    emit(state.copyWith(
      action: SecondBleAction.onBluetoothStateChange,
      bluetoothState: value,
    ));
  }

  Future<void> checkBluetoothIsOn() async {
    try {
      emit(state.copyWith(
        status: SecondBleStatus.loading,
        action: SecondBleAction.checkBluetoothIsOn,
      ));
      final isOn = await _questBle.isBluetoothOn();
      _log('[checkBluetoothIsOn] bluetooth is on: $isOn');
      emit(state.copyWith(
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> startScan() async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.startScan,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));

        return;
      }

      final stream = await _questBle.startScan(
        timeout: const Duration(seconds: 5),
      );

      await _scanResultSubscription?.cancel();
      _scanResultSubscription = stream.listen(
        (event) {
          final device = event.device;
          if (device.name != '') {
            _log('[scanResult] name: ${device.name}, rssi: ${event.rssi}');
          }
        },
        onDone: () {
          _log('[scanResult] scan finished');
          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.success,
          ));
        },
        onError: (e, s) {
          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.failure,
            errorMessage: e.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> startScanWithDeviceName(String deviceName) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.startScan,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));

        return;
      }

      final stream = await _questBle.startScan(
        timeout: const Duration(seconds: 5),
      );

      bool deviceFound = false;
      await _scanResultSubscription?.cancel();
      _scanResultSubscription = stream.listen(
        (event) async {
          final device = event.device;
          if (device.name != '') {
            _log('[scanResult] name: ${device.name}, rssi: ${event.rssi}');
            if (device.name == deviceName) {
              await _questBle.stopScan();
              _assignDeviceToState(device);
              deviceFound = true;
              _log('[scanResult] Device found, scan will stop');
            }
          }
        },
        onDone: () {
          _log('[scanResult] scan finished');
          if (deviceFound) {
            emit(state.copyWith(
              action: SecondBleAction.startScan,
              status: SecondBleStatus.success,
            ));
            return;
          }

          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.failure,
            errorMessage: 'Bike out of range',
          ));
        },
        onError: (e, s) {
          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.failure,
            errorMessage: e.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> startScanWithProperties({
    required String deviceName,
    List<Guid> services = const [],
  }) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.startScan,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));

        return;
      }

      final stream = await _questBle.startScan(
        timeout: const Duration(seconds: 5),
        withServices: services,
      );

      bool deviceFound = false;
      await _scanResultSubscription?.cancel();
      _scanResultSubscription = stream.listen(
        (event) async {
          final device = event.device;
          if (device.name != '') {
            _log('[scanResult] name: ${device.name}, rssi: ${event.rssi}');
            if (device.name == deviceName) {
              await _questBle.stopScan();
              _assignDeviceToState(device);
              deviceFound = true;
              _log('[scanResult] Device found, scan will stop');
            }
          }
        },
        onDone: () {
          _log('[scanResult] scan finished');

          if (deviceFound) {
            emit(state.copyWith(
              action: SecondBleAction.startScan,
              status: SecondBleStatus.success,
            ));
            return;
          }

          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.failure,
            errorMessage: 'Bike out of range',
          ));
        },
        onError: (e, s) {
          emit(state.copyWith(
            action: SecondBleAction.startScan,
            status: SecondBleStatus.failure,
            errorMessage: e.toString(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.startScan,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> stopScan() async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.stopScan,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.stopScan,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));
        return;
      }

      await _questBle.stopScan();

      emit(state.copyWith(
        action: SecondBleAction.stopScan,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.stopScan,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> getConnectedDevices() async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.getConnectedDevices,
        status: SecondBleStatus.loading,
      ));
      final isOn = await _questBle.isBluetoothOn();
      // if (state.bluetoothState != BluetoothState.on) {
      //   emit(state.copyWith(
      //     action: SecondBleAction.getConnectedDevices,
      //     status: SecondBleStatus.failure,
      //     errorMessage: 'Please turn on your bluetooth'
      //         ' before using this application',
      //   ));
      //   return;
      // }

      if (isOn == false) {
        emit(state.copyWith(
          action: SecondBleAction.getConnectedDevices,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));
        return;
      }

      final devices = await _questBle.getConnectedDevices();
      _log('[connectedDevices] connected device length: ${devices.length}');

      for (var device in devices) {
        _log('[connectedDevices] device name: ${device.name}');
        await _questBle.disconnect(device: device);
      }

      emit(state.copyWith(
        action: SecondBleAction.getConnectedDevices,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.getConnectedDevices,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> connectToDevice(String name) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.connect,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.connect,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));
        return;
      }

      final device = _getBluetoothDevice(name);
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.connect,
          status: SecondBleStatus.failure,
          errorMessage: 'Please select vehicle',
        ));
        return;
      }

      await _questBle.connect(
        device: device,
        timeout: const Duration(seconds: 5),
      );

      emit(state.copyWith(
        action: SecondBleAction.connect,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.connect,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> disconnectFromDevice(String name) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.disconnect,
        status: SecondBleStatus.loading,
      ));

      if (state.bluetoothState != BluetoothState.on) {
        emit(state.copyWith(
          action: SecondBleAction.disconnect,
          status: SecondBleStatus.failure,
          errorMessage: 'Please turn on your bluetooth'
              ' before using this application',
        ));
        return;
      }

      final device = _getBluetoothDevice(name);
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.disconnect,
          status: SecondBleStatus.failure,
          errorMessage: 'Please scan & connect before '
              'disconnecting from device',
        ));

        return;
      }
      await _deviceStateSubscription?.cancel();
      await _characteristicSubscription?.cancel();
      await _questBle.disconnect(device: device);
      emit(state.copyWith(
        action: SecondBleAction.disconnect,
        status: SecondBleStatus.success,
        bluetoothDevice: null,
        rawData: [],
        bluetoothDeviceState: BluetoothDeviceState.disconnected,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.disconnect,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> streamBluetoothDeviceState(String name) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.getDeviceStateChange,
        status: SecondBleStatus.loading,
      ));

      final device = _getBluetoothDevice(name);
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.getDeviceStateChange,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before stream to device state',
        ));
        return;
      }

      await _deviceStateSubscription?.cancel();
      final stream = _questBle.streamDeviceState(device: device);
      _deviceStateSubscription = stream.listen(
        (event) {
          emit(state.copyWith(
            bluetoothDeviceState: event,
            action: SecondBleAction.onDeviceStateChange,
          ));
        },
      );

      emit(state.copyWith(
        action: SecondBleAction.getDeviceStateChange,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.getDeviceStateChange,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> discoverService() async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.discoverService,
        status: SecondBleStatus.loading,
      ));

      final device = state.bluetoothDevice;
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.discoverService,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before discover service',
        ));
        return;
      }

      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid(kServiceUuid)) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(kCharacteristicUuid)) {
              emit(state.copyWith(
                action: SecondBleAction.discoverService,
                bluetoothCharacteristic: characteristic,
              ));
              _log('[discoverService] characteristic found');
            }
          }
        }
      }

      emit(state.copyWith(
        action: SecondBleAction.discoverService,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.discoverService,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> streamBluetoothNotification() async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.streamBluetoothNotification,
        status: SecondBleStatus.loading,
      ));

      final device = state.bluetoothDevice;
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.streamBluetoothNotification,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before stream to bluetooth notifcation',
        ));
        return;
      }

      final characteristic = state.bluetoothCharacteristic;
      if (characteristic == null) {
        emit(state.copyWith(
          action: SecondBleAction.streamBluetoothNotification,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before stream to bluetooth notifcation',
        ));
        return;
      }

      if (characteristic.isNotifying) {
        await characteristic.setNotifyValue(false);
      }

      await characteristic.setNotifyValue(true);
      await _characteristicSubscription?.cancel();
      _characteristicSubscription = characteristic.value.listen(
        (event) {
          if (event.isNotEmpty) {
            emit(state.copyWith(
              action: SecondBleAction.onCharacteristicChange,
              rawData: event,
            ));
          }
        },
      );

      emit(state.copyWith(
        action: SecondBleAction.streamBluetoothNotification,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.streamBluetoothNotification,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> write(List<int> payload) async {
    try {
      emit(state.copyWith(
        action: SecondBleAction.write,
        status: SecondBleStatus.loading,
      ));

      final device = state.bluetoothDevice;
      if (device == null) {
        emit(state.copyWith(
          action: SecondBleAction.write,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before stream to bluetooth notifcation',
        ));
        return;
      }

      final characteristic = state.bluetoothCharacteristic;
      if (characteristic == null) {
        emit(state.copyWith(
          action: SecondBleAction.write,
          status: SecondBleStatus.failure,
          errorMessage: 'Please connect before stream to bluetooth notifcation',
        ));
        return;
      }

      await characteristic.write(payload);

      emit(state.copyWith(
        action: SecondBleAction.write,
        status: SecondBleStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        action: SecondBleAction.write,
        status: SecondBleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void clearBluetoothDevice() {
    emit(state.copyWith(bluetoothDevice: null));
  }

  void _assignDeviceToState(BluetoothDevice device) {
    emit(state.copyWith(bluetoothDevice: device));
  }

  BluetoothDevice? _getBluetoothDevice(String name) {
    final device = state.bluetoothDevice;
    return device;
  }
}
