import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../app/extensions/modal.dart';
import '../../packages/quest_ble/quest_ble.dart';
import '../bloc/ble/ble_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BleCubit(
            questBle: context.read<QuestBle>(),
          )..checkBluetoothIsOn(),
        ),
      ],
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _textController.text = 'Vicky-20s10p';
    context.read<BleCubit>().getConnectedDevices();
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
      final cubit = BlocProvider.of<BleCubit>(context);
      cubit.startScanWithDeviceName(_textController.text);
    }
  }

  void _disconnect() {
    if (_formKey.currentState!.validate()) {
      final cubit = BlocProvider.of<BleCubit>(context);
      cubit.disconnectFromDevice(_textController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ANT-BMS',
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BleCubit, BleState>(
            listener: (context, state) {
              final action = state.action;
              final status = state.status;

              switch (status) {
                case BleStatus.loading:
                  if (action == BleAction.onBluetoothStateChange) return;
                  if (action == BleAction.onScanStateChange) return;
                  if (action == BleAction.onDeviceStateChange) return;
                  if (action == BleAction.onCharacteristicChange) return;

                  context.showLoading();
                  break;
                case BleStatus.success:
                  if (action == BleAction.onBluetoothStateChange) return;
                  if (action == BleAction.onScanStateChange) return;
                  if (action == BleAction.onDeviceStateChange) return;
                  if (action == BleAction.onCharacteristicChange) return;

                  if (action == BleAction.getConnectedDevices) {}

                  if (action == BleAction.startScan) {
                    context.showSnackbar('Success assign device');

                    final cubit = BlocProvider.of<BleCubit>(context);
                    cubit.connectToDevice(_textController.text);
                  }

                  if (action == BleAction.connect) {
                    final cubit = BlocProvider.of<BleCubit>(context);
                    cubit.streamBluetoothDeviceState(_textController.text);
                  }

                  if (action == BleAction.getDeviceStateChange) {
                    _log('gonna discover service');
                    final cubit = BlocProvider.of<BleCubit>(context);
                    cubit.discoverService();
                  }

                  if (action == BleAction.discoverService) {
                    _log('gonna stream notification');
                    final cubit = BlocProvider.of<BleCubit>(context);
                    cubit.streamBluetoothNotification();
                  }

                  context.closeLoading();
                  break;
                case BleStatus.failure:
                  if (action == BleAction.onBluetoothStateChange) return;
                  if (action == BleAction.onScanStateChange) return;
                  if (action == BleAction.onDeviceStateChange) return;
                  if (action == BleAction.onCharacteristicChange) return;

                  context.closeLoading();
                  context.showSnackbar(state.errorMessage);
                  break;
                default:
                  if (action == BleAction.onBluetoothStateChange) return;
                  if (action == BleAction.onScanStateChange) return;
                  if (action == BleAction.onDeviceStateChange) return;
                  if (action == BleAction.onCharacteristicChange) return;

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
                          BlocBuilder<BleCubit, BleState>(
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
                          BlocBuilder<BleCubit, BleState>(
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
                        child: BlocBuilder<BleCubit, BleState>(
                          builder: (context, state) {
                            final bluetoothOn =
                                state.bluetoothState == BluetoothState.on;
                            final device = state.bluetoothDevice;
                            final deviceState = state.bluetoothDeviceState;
                            final connected =
                                deviceState == BluetoothDeviceState.connected;
                            final characteristic =
                                state.bluetoothCharacteristic;

                            final canSend = bluetoothOn &&
                                device != null &&
                                connected &&
                                characteristic != null;

                            return ElevatedButton(
                              onPressed: canSend
                                  ? () {
                                      final cubit =
                                          BlocProvider.of<BleCubit>(context);

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
                      child: BlocBuilder<BleCubit, BleState>(
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
                    BlocBuilder<BleCubit, BleState>(
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
                                      BlocProvider.of<BleCubit>(context);

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
                                      BlocProvider.of<BleCubit>(context);

                                  cubit.write(
                                    [
                                      0x7E,
                                      0xA1,
                                      0x51,
                                      0x01,
                                      0x00,
                                      0x00,
                                      0xD8,
                                      0xEE,
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
                    BlocBuilder<BleCubit, BleState>(
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
                                      BlocProvider.of<BleCubit>(context);

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
                                      BlocProvider.of<BleCubit>(context);

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
                    BlocBuilder<BleCubit, BleState>(
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
                                      BlocProvider.of<BleCubit>(context);

                                  cubit.write(
                                    [],
                                  );
                                }
                              : null,
                          onSecondButtonPressed: canSend
                              ? () {
                                  final cubit =
                                      BlocProvider.of<BleCubit>(context);

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
