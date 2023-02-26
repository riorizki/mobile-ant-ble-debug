import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CustomDeviceStateModel extends Equatable {
  const CustomDeviceStateModel({
    required this.hasConnected,
    required this.deviceName,
    required this.deviceState,
  });

  final bool hasConnected;
  final String deviceName;
  final BluetoothDeviceState deviceState;

  CustomDeviceStateModel copyWith({
    String? deviceName,
    BluetoothDeviceState? deviceState,
    bool? hasConnected,
  }) {
    return CustomDeviceStateModel(
      deviceName: deviceName ?? this.deviceName,
      deviceState: deviceState ?? this.deviceState,
      hasConnected: hasConnected ?? this.hasConnected,
    );
  }

  @override
  List<Object?> get props => [deviceName, deviceState];
}
