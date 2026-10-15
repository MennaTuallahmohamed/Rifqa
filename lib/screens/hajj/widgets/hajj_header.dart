import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../umrah/umrah_data.dart';

class HajjHeader extends StatelessWidget {
  final int done;
  final VoidCallback onBack;
  const HajjHeader({super.key, required this.done, required this.onBack});

  static const _days = [
    ['8', 'التروية'],
    ['9', 'عرفة'],
    ['10', 'النحر'],
    ['11-13', 'التشريق'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0A1F3D), Color(0xFF0F3B3A), Color(0xFF083D2D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _SkyPainter())),
            const Positioned.fill(
                child: CustomPaint(painter: UPatternPainter(opacity: .05))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackButton(color: Colors.white, onPressed: onBack),
                        const Spacer(),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('دليل الحج',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('من يوم التروية إلى طواف الوداع',
                                    style: TextStyle(
                                        color: UC.goldLight.withOpacity(.95),
                                        fontSize: 13.5)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 66,
                            height: 66,
                            child: CustomPaint(
                              painter: _Ring(done / 8),
                              child: Center(
                                child: Text('$done/8',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        children: [
                          for (final d in _days)
                            Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsetsDirectional.only(end: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.gold.withOpacity(.55)),
                                ),
                                child: Column(
                                  children: [
                                    Text(d[0],
                                        style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900)),
                                    Text(d[1],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  final double v;
  _Ring(this.v);
  @override
  void paint(Canvas c, Size s) {
    const w = 7.0;
    final r = (Offset.zero & s).deflate(w / 2);
    c.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = Colors.white24);
    if (v > 0) {
      c.drawArc(
          r,
          -math.pi / 2,
          math.pi * 2 * v,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = w
            ..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.v != v;
}

/// هلال ونجوم
class _SkyPainter extends CustomPainter {
  const _SkyPainter();
  @override
  void paint(Canvas c, Size s) {
    final rnd = math.Random(3);
    for (int i = 0; i < 40; i++) {
      c.drawCircle(
          Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .8),
          rnd.nextDouble() * 1.4 + .4,
          Paint()
            ..color = Colors.white.withOpacity(.15 + rnd.nextDouble() * .5));
    }
    final center = Offset(s.width * .2, 64);
    final moon = Path()..addOval(Rect.fromCircle(center: center, radius: 24));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: center.translate(11, -5), radius: 21));
    final crescent = Path.combine(PathOperation.difference, moon, cut);
    c.drawCircle(
        center,
        46,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.gold.withOpacity(.28),
            AppColors.gold.withOpacity(0)
          ]).createShader(Rect.fromCircle(center: center, radius: 46)));
    c.drawPath(crescent, Paint()..color = const Color(0xFFE9CF8B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
