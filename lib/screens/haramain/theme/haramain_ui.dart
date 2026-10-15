import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

abstract final class HmUi {
  static const emerald = AppColors.green;
  static const emeraldDark = AppColors.greenDark;
  static const gold = AppColors.gold;
  static const ivory = Color(0xFFF7F4ED);
  static const ink = AppColors.ink;
  static const muted = AppColors.muted;
  static const line = AppColors.line;
  static const blue = Color(0xFF1677FF);
  static const warn = Color(0xFFE08A1E);

  static const iconSize = 0.5;

  static BoxDecoration sheet({bool highContrast = false}) => BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: highContrast ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -5))
        ],
      );

  static BoxDecoration card({bool highContrast = false}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: highContrast ? Colors.black : AppColors.line, width: highContrast ? 2 : 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))
        ],
      );
}
