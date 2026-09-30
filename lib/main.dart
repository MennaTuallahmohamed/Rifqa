import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/flow_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  await state.load();

  runApp(
    AppScope(
      state: state,
      child: const RafeeqApp(),
    ),
  );
}

class RafeeqApp extends StatelessWidget {
  const RafeeqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رفيق المعتمر',
      locale: const Locale('ar'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const FlowScreen(),
    );
  }
}