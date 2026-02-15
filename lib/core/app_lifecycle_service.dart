import 'package:flutter/widgets.dart';

class AppLifecycleService {
  AppLifecycleService._();

  static final ValueNotifier<AppLifecycleState> state =
      ValueNotifier<AppLifecycleState>(AppLifecycleState.resumed);
}
