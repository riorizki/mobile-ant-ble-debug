import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../app/extensions/modal.dart';
import '../bloc/ble/ble_cubit.dart';
import '../bloc/second_ble/second_ble_cubit.dart';

class SecondBleView extends StatefulWidget {
  const SecondBleView({super.key});

  @override
  State<SecondBleView> createState() => _SecondBleViewState();
}

class _SecondBleViewState extends State<SecondBleView> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = 'ANT-BLE20PHUB-0012';
    context.read<SecondBleCubit>().getConnectedDevices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _log(Object object) {
    if (kDebugMode) print(object);
  }

  void _connect() {
    if (_formKey.currentState!.validate()) {
      final cubit = BlocProvider.of<SecondBleCubit>(context);
      cubit.startScanWithProperties(
        deviceName: _textController.text,
        services: [Guid(kServiceUuid)],
      );
    }
  }

  void _disconnect() {
    if (_formKey.currentState!.validate()) {
      final cubit = BlocProvider.of<SecondBleCubit>(context);
      cubit.disconnectFromDevice(_textController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SecondBleCubit, SecondBleState>(
          listener: (context, state) {
            final action = state.action;
            final status = state.status;

            switch (status) {
              case SecondBleStatus.loading:
                if (action == SecondBleAction.onBluetoothStateChange) return;
                if (action == SecondBleAction.onScanStateChange) return;
                if (action == SecondBleAction.onDeviceStateChange) return;
                if (action == SecondBleAction.onCharacteristicChange) return;

                context.showLoading();
                break;
              case SecondBleStatus.success:
                if (action == SecondBleAction.onBluetoothStateChange) return;
                if (action == SecondBleAction.onScanStateChange) return;
                if (action == SecondBleAction.onDeviceStateChange) return;
                if (action == SecondBleAction.onCharacteristicChange) return;

                if (action == SecondBleAction.getConnectedDevices) {}

                if (action == SecondBleAction.startScan) {
                  context.showSnackbar('Success assign device');

                  final cubit = BlocProvider.of<SecondBleCubit>(context);
                  cubit.connectToDevice(_textController.text);
                }

                if (action == SecondBleAction.connect) {
                  final cubit = BlocProvider.of<SecondBleCubit>(context);
                  cubit.streamBluetoothDeviceState(_textController.text);
                }

                if (action == SecondBleAction.getDeviceStateChange) {
                  _log('gonna discover service');
                  final cubit = BlocProvider.of<SecondBleCubit>(context);
                  cubit.discoverService();
                }

                if (action == SecondBleAction.discoverService) {
                  _log('gonna stream notification');
                  final cubit = BlocProvider.of<SecondBleCubit>(context);
                  cubit.streamBluetoothNotification();
                }

                context.closeLoading();
                break;
              case SecondBleStatus.failure:
                if (action == SecondBleAction.onBluetoothStateChange) return;
                if (action == SecondBleAction.onScanStateChange) return;
                if (action == SecondBleAction.onDeviceStateChange) return;
                if (action == SecondBleAction.onCharacteristicChange) return;

                context.closeLoading();
                context.showSnackbar(state.errorMessage);
                break;
              default:
                if (action == SecondBleAction.onBluetoothStateChange) return;
                if (action == SecondBleAction.onScanStateChange) return;
                if (action == SecondBleAction.onDeviceStateChange) return;
                if (action == SecondBleAction.onCharacteristicChange) return;

                context.closeLoading();
            }
          },
        ),
      ],
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // ! BLE Name & Connect Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<SecondBleCubit, SecondBleState>(
                          builder: (context, state) {
                            return Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Bluetooth Name',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _textController,
                                enabled: state.bluetoothDeviceState !=
                                    BluetoothDeviceState.connected,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please provide bluetooth name';
                                  }
                                  return null;
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        BlocBuilder<SecondBleCubit, SecondBleState>(
                          builder: (context, state) {
                            final bluetoothOn =
                                state.bluetoothState == BluetoothState.on;
                            final device = state.bluetoothDevice;
                            final deviceState = state.bluetoothDeviceState;
                            final connected =
                                deviceState == BluetoothDeviceState.connected;

                            if (device != null && connected) {
                              return ElevatedButton(
                                onPressed: bluetoothOn ? _disconnect : null,
                                child: const Text('Disconnect'),
                              );
                            }

                            return ElevatedButton(
                              onPressed: bluetoothOn ? _connect : null,
                              child: const Text('Connect'),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  const _Spacing(),
                  // ! Button Send Hex
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<SecondBleCubit, SecondBleState>(
                        builder: (context, state) {
                          final bluetoothOn =
                              state.bluetoothState == BluetoothState.on;
                          final device = state.bluetoothDevice;
                          final deviceState = state.bluetoothDeviceState;
                          final connected =
                              deviceState == BluetoothDeviceState.connected;
                          final characteristic = state.bluetoothCharacteristic;

                          final canSend = bluetoothOn &&
                              device != null &&
                              connected &&
                              characteristic != null;

                          return ElevatedButton(
                            onPressed: canSend
                                ? () {
                                    final cubit =
                                        BlocProvider.of<SecondBleCubit>(
                                            context);

                                    cubit.write(
                                      [0xDB, 0xDB, 0x00, 0x00, 0x00, 0x00],
                                    );
                                  }
                                : null,
                            child: const Text(
                              'Send HEX',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const _Spacing(),
                  // ! Label Received
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: BlocBuilder<SecondBleCubit, SecondBleState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          child: Text('${state.rawData}'),
                        );
                      },
                    ),
                  ),
                  const _Spacing(),
                  // ! Discharge ON/OFF
                  BlocBuilder<SecondBleCubit, SecondBleState>(
                    builder: (context, state) {
                      final bluetoothOn =
                          state.bluetoothState == BluetoothState.on;
                      final device = state.bluetoothDevice;
                      final deviceState = state.bluetoothDeviceState;
                      final connected =
                          deviceState == BluetoothDeviceState.connected;
                      final characteristic = state.bluetoothCharacteristic;

                      final canSend = bluetoothOn &&
                          device != null &&
                          connected &&
                          characteristic != null;

                      return TwoButtonWidget(
                        firstButtonTitle: 'Discharge ON',
                        secondButtonTitle: 'Discharge OFF',
                        onFirstButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [
                                    0x7E,
                                    0xA1,
                                    0x51,
                                    0x03,
                                    0x00,
                                    0x00,
                                    0x79,
                                    0x25,
                                    0xAA,
                                    0x55
                                  ],
                                );
                              }
                            : null,
                        onSecondButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [
                                    0x7E,
                                    0xA1,
                                    0x51,
                                    0x01,
                                    0x00,
                                    0x00,
                                    0xD8,
                                    0xE5,
                                    0xAA,
                                    0x55
                                  ],
                                );
                              }
                            : null,
                      );
                    },
                  ),
                  const _Spacing(),
                  // ! Charge
                  BlocBuilder<SecondBleCubit, SecondBleState>(
                    builder: (context, state) {
                      final bluetoothOn =
                          state.bluetoothState == BluetoothState.on;
                      final device = state.bluetoothDevice;
                      final deviceState = state.bluetoothDeviceState;
                      final connected =
                          deviceState == BluetoothDeviceState.connected;
                      final characteristic = state.bluetoothCharacteristic;

                      final canSend = bluetoothOn &&
                          device != null &&
                          connected &&
                          characteristic != null;

                      return TwoButtonWidget(
                        firstButtonTitle: 'Charge ON',
                        secondButtonTitle: 'Charge OFF',
                        onFirstButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [
                                    0x7E,
                                    0xA1,
                                    0x51,
                                    0x06,
                                    0x00,
                                    0x00,
                                    0x69,
                                    0x24,
                                    0xAA,
                                    0x55
                                  ],
                                );
                              }
                            : null,
                        onSecondButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [
                                    0x7E,
                                    0xA1,
                                    0x51,
                                    0x04,
                                    0x00,
                                    0x00,
                                    0xC8,
                                    0xE4,
                                    0xAA,
                                    0x55
                                  ],
                                );
                              }
                            : null,
                      );
                    },
                  ),
                  const _Spacing(),
                  // ! Balancing
                  BlocBuilder<SecondBleCubit, SecondBleState>(
                    builder: (context, state) {
                      final bluetoothOn =
                          state.bluetoothState == BluetoothState.on;
                      final device = state.bluetoothDevice;
                      final deviceState = state.bluetoothDeviceState;
                      final connected =
                          deviceState == BluetoothDeviceState.connected;
                      final characteristic = state.bluetoothCharacteristic;

                      final canSend = bluetoothOn &&
                          device != null &&
                          connected &&
                          characteristic != null;

                      return TwoButtonWidget(
                        firstButtonTitle: 'Balancing ON',
                        secondButtonTitle: 'Balancing OFF',
                        onFirstButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [],
                                );
                              }
                            : null,
                        onSecondButtonPressed: canSend
                            ? () {
                                final cubit =
                                    BlocProvider.of<SecondBleCubit>(context);

                                cubit.write(
                                  [],
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing({Key? key, this.height = 14}) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class TwoButtonWidget extends StatelessWidget {
  const TwoButtonWidget({
    super.key,
    this.onFirstButtonPressed,
    this.onSecondButtonPressed,
    required this.firstButtonTitle,
    required this.secondButtonTitle,
  });

  final String firstButtonTitle, secondButtonTitle;
  final void Function()? onFirstButtonPressed;
  final void Function()? onSecondButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onFirstButtonPressed,
              child: Text(firstButtonTitle),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: onSecondButtonPressed,
              child: Text(secondButtonTitle),
            ),
          ),
        ],
      ),
    );
  }
}
