import 'package:flutter/material.dart';
import '../lib/screens/refqa_community/refqa_community.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale('ar'),
    home: RefqaCommunityScreen(),
  ));
}
