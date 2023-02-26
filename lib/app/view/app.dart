import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/view/home_page.dart';
import '../../packages/quest_ble/src/quest_ble.dart';

class App extends StatelessWidget {
  const App({super.key, required this.questBle});

  final QuestBle questBle;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider(
          create: (context) => questBle,
        ),
      ],
      child: MaterialApp(
        title: 'Ant BMS - Bluetooth',
        builder: BotToastInit(),
        navigatorObservers: [
          BotToastNavigatorObserver(),
        ],
        home: const HomePage(),
      ),
    );
  }
}
