import 'package:flutter/material.dart';

/// Clean native illustration instead of the legacy Clock Towers screenshot
/// that contained phone status-bar symbols as part of its image.
class MarketClockArtwork extends StatelessWidget {
  const MarketClockArtwork({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(0),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: [Color(0xFF0D554B), Color(0xFF052E32), Color(0xFF153E39)],
        ),
      ),
      child: LayoutBuilder(builder: (context, limits) {
        final compact = limits.maxWidth < 130 || limits.maxHeight < 120;
        return Stack(fit: StackFit.expand, children: [
          Positioned(
            right: -30, top: -46, child: Container(width: 165, height: 165,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33E5BC6B), width: 18))),
          ),
          Positioned(left: -40, bottom: -75, child: Container(
            width: 200, height: 200,
            decoration: const BoxDecoration(shape: BoxShape.circle,
                color: Color(0x164AF5BC)),
          )),
          Align(alignment: Alignment.bottomCenter, child: Opacity(
            opacity: .18,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (final h in [0.48, 0.69, 0.88, 0.58, 0.4])
                Container(width: compact ? 11 : 29,
                    height: limits.maxHeight * h,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBD7AA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)))),
              ]),
          )),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time_filled_rounded,
                size: compact ? 28 : 55,
                color: const Color(0xFFEDD09B)),
            SizedBox(height: compact ? 3 : 10),
            Text('أبراج الساعة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 9 : 17,
                fontWeight: FontWeight.w900)),
          ])),
        ]);
      }),
    ),
  );
}
