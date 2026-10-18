import 'package:flutter/material.dart';
import 'screens/pilgrim_watch/pilgrim_watch_screen.dart';

/// Standalone visual/interaction preview. The production app's main.dart stays untouched.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RifqaPilgrimWatchPreview());
}

class RifqaPilgrimWatchPreview extends StatelessWidget {
  const RifqaPilgrimWatchPreview({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'ساعة رِفقة', debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFFE2B961)),
    home: const RifqaPilgrimWatchScreen(),
  );
}
