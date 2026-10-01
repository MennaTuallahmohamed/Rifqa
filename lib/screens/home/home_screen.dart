import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import '../services/service_screen.dart';

class _C {
  static const ivory = Color(0xFFFAF7F0);
  static const ink = Color(0xFF17322A);
  static const muted = Color(0xFF6B7B74);
  static const goldLight = Color(0xFFE9CF8B);
  static const border = Color(0xFFEDE7D6);
}

class _Svc {
  final String label;
  final IconData icon;
  final int code; // >= 0 : تبويب ، < 0 : ServiceScreen
  final List<Color> colors;
  const _Svc(this.label, this.icon, this.code, this.colors);
}

class _Group {
  final String title;
  final String subtitle;
  final List<_Svc> items;
  const _Group(this.title, this.subtitle, this.items);
}

const _emerald = [Color(0xFF1E8F6A), Color(0xFF0F5E45)];
const _gold = [Color(0xFFD9B45A), Color(0xFFB88A2E)];
const _sky = [Color(0xFF3B8FC4), Color(0xFF22638F)];
const _plum = [Color(0xFF8A5FB0), Color(0xFF5E3C82)];
const _rose = [Color(0xFFD9675B), Color(0xFFA8403A)];
const _teal = [Color(0xFF2BA6A0), Color(0xFF17716C)];

const _groups = <_Group>[
  _Group('مناسكك', 'كل ما تحتاجه لأداء النسك بطمأنينة', [
    _Svc('دليل العمرة', Icons.mosque_rounded, 1, _emerald),
    _Svc('الحج', Icons.landscape_rounded, -1, _gold),
    _Svc('الأدعية', Icons.front_hand_rounded, -4, _plum),
    _Svc('المنبه', Icons.alarm_rounded, -6, _sky),
  ]),
  _Group('أماكنك', 'اعرف طريقك في الحرمين والمدينة', [
    _Svc('خريطة الحرم', Icons.map_rounded, 2, _teal),
    _Svc('المدينة', Icons.location_city_rounded, -2, _emerald),
    _Svc('المزارات', Icons.place_rounded, -3, _rose),
    _Svc('الأسواق', Icons.storefront_rounded, -7, _gold),
  ]),
  _Group('رحلتك', 'رفقاؤك وأهم ما يلزمك', [
    _Svc('الرفاق', Icons.groups_rounded, -5, _sky),
    _Svc('أرقام مهمة', Icons.phone_in_talk_rounded, -8, _rose),
    _Svc('حسابي', Icons.person_rounded, -9, _plum),
  ]),
];

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> open;
  const HomeScreen({super.key, required this.open});

  void _go(BuildContext c, _Svc s) {
    if (s.code >= 0) {
      open(s.code);
    } else {
      Navigator.push(
          c, MaterialPageRoute(builder: (_) => ServiceScreen(code: s.code)));
    }
  }

  String _hint(int p) {
    if (p == 0) return 'ابدأ بنية خالصة، والبداية من الإحرام';
    if (p < 50) return 'ما شاء الله، واصل بخطى ثابتة';
    if (p < 100) return 'اقتربت من إتمام عمرتك، تقبّل الله منك';
    return 'أتممت عمرتك، تقبّل الله طاعتك';
  }

  @override
  Widget build(BuildContext c) {
    final st = AppScope.of(c);
    final p = st.progress.clamp(0, 100).toInt();

    return Container(
      color: _C.ivory,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _Hero(name: st.name),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 196, 16, 0),
                  child: _JourneyCard(
                    progress: p,
                    hint: _hint(p),
                    onTap: () => open(1),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: _SosCard(onTap: () => open(3)),
            ),
          ),
          for (final g in _groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.title,
                              style: const TextStyle(
                                  color: _C.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(g.subtitle,
                              style: const TextStyle(
                                  color: _C.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                itemCount: g.items.length,
                // ارتفاع ثابت بدل النسبة => لا يحدث overflow مهما كان حجم الخط
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: g.items.length >= 4 ? 4 : 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 118,
                ),
                itemBuilder: (ctx, i) => _ServiceTile(
                    svc: g.items[i], onTap: () => _go(ctx, g.items[i])),
              ),
            ),
          ],
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 26, 16, 0),
              child: _TalbiyahBanner(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ═════════════════════════ الهيدر ═════════════════════════
class _Hero extends StatelessWidget {
  final String name;
  const _Hero({required this.name});

  @override
  Widget build(BuildContext context) {
    final who = name.trim().isEmpty ? 'ضيف الرحمن' : name.trim();
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.green, AppColors.greenDark, Color(0xFF083D2D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _GeometricPatternPainter()),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('السلام عليكم ورحمة الله',
                              style: TextStyle(
                                  color: _C.goldLight,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(who,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          const Text('رفيق المعتمر',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('لبّيك اللهم لبّيك',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(.8),
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [_C.goldLight, AppColors.gold]),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.greenDark,
                        child: Icon(Icons.person_rounded,
                            color: Colors.white, size: 26),
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

class _GeometricPatternPainter extends CustomPainter {
  const _GeometricPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(.07);
    const step = 58.0;
    const r = 22.0;
    for (double y = -10; y < size.height + step; y += step) {
      for (double x = -10; x < size.width + step; x += step) {
        canvas.drawPath(_star(Offset(x, y), r), paint);
        canvas.drawPath(
            _star(Offset(x + step / 2, y + step / 2), r * .55), paint);
      }
    }
  }

  Path _star(Offset c, double r) {
    final path = Path();
    for (final rot in [math.pi / 4, 0.0]) {
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 + math.pi / 4;
        final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═════════════════════════ بطاقة الرحلة ═════════════════════════
class _JourneyCard extends StatelessWidget {
  final int progress;
  final String hint;
  final VoidCallback onTap;
  const _JourneyCard(
      {required this.progress, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // لون صريح => لا يظهر الظل داخل الكارت
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.gold.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withOpacity(.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CustomPaint(
                    painter: _RingPainter(progress / 100),
                    child: Center(
                      child: progress == 0
                          ? const Text('🕋', style: TextStyle(fontSize: 28))
                          : Text('$progress%',
                              style: const TextStyle(
                                  color: _C.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('رحلة عمرتك',
                          style: TextStyle(
                              color: _C.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(hint,
                          style: const TextStyle(
                              color: _C.muted, fontSize: 12.5, height: 1.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.green,
                            AppColors.greenDark
                          ]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                            progress == 0 ? 'ابدأ رحلتك' : 'تابع رحلتك',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
        arcRect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.softGreen);

    if (value > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = AppColors.gold;
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

// ═════════════════════════ زر أنا تائه ═════════════════════════
class _SosCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SosCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE0584C), Color(0xFFB02F2F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB02F2F).withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sos_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أنا تائه',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('اعرف أقرب باب وطريقك وأبلغ مجموعتك',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ بطاقة الخدمة ═════════════════════════
class _ServiceTile extends StatelessWidget {
  final _Svc svc;
  final VoidCallback onTap;
  const _ServiceTile({required this.svc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // لون صريح => لا يظهر الظل داخل الكارت
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: svc.colors.last.withOpacity(.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: svc.colors,
                    ),
                  ),
                  child: Icon(svc.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(svc.label,
                        maxLines: 1,
                        style: const TextStyle(
                            color: _C.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ لافتة التلبية ═════════════════════════
class _TalbiyahBanner extends StatelessWidget {
  const _TalbiyahBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.greenDark, Color(0xFF083D2D)],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(.6), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _GeometricPatternPainter()),
            ),
            Column(
              children: [
                const Text('✦',
                    style: TextStyle(color: AppColors.gold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text(
                  'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لا شَرِيكَ لَكَ لَبَّيْكَ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('تقبّل الله منك وبلّغك بيته الحرام',
                    style: TextStyle(
                        color: _C.goldLight.withOpacity(.9), fontSize: 12.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}