import 'package:flutter/material.dart';

/// Design tokens shared by the Umrah cinematic experience.
abstract final class UGold {
  static const deep = Color(0xFF073D31);
  static const green = Color(0xFF08634C);
  static const cream = Color(0xFFFCF8F0);
  static const gold = Color(0xFFDCC082);
  static const ink = Color(0xFF234439);
}

/// All premium imagery ships in assets/umrah; no network or insecure URLs.
class UPhoto extends StatelessWidget {
  const UPhoto(
      {super.key, required this.asset, this.alignment = Alignment.center});
  final String asset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [UGold.deep, UGold.green],
            ),
          ),
          child: Center(
              child: Icon(Icons.mosque_rounded, color: UGold.gold, size: 36)),
        ),
      );
}
