import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light).copyWith(scaffoldBackgroundColor: AppColors.bg);
  static ThemeData dark() => _base(Brightness.dark).copyWith(scaffoldBackgroundColor: const Color(0xFF0E1512), cardColor: const Color(0xFF17211D));
  static ThemeData _base(Brightness b) => ThemeData(
    useMaterial3: true, brightness: b, colorSchemeSeed: AppColors.green,
    textTheme: GoogleFonts.tajawalTextTheme(ThemeData(brightness:b).textTheme),
    fontFamily: GoogleFonts.tajawal().fontFamily,
    cardTheme: CardThemeData(elevation:0, shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20), side:BorderSide(color:b==Brightness.light?AppColors.line:const Color(0xFF26332D)))),
    inputDecorationTheme: InputDecorationTheme(filled:true, fillColor:b==Brightness.light?AppColors.bg:const Color(0xFF0E1512), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none)),
  );
}
