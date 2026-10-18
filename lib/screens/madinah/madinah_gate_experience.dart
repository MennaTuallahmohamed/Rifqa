import 'dart:math' as math;

import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────
// رِفقة · بوابة المدينة المنورة
// ───────────────────────────────────────────────────────
// شاشة دخول سينمائية تُعرض مرة واحدة قبل الدخول إلى الجولة
// الافتراضية أو المسجد النبوي. الفكرة: بوابة ذهبية تُفتح في
// حركة ثلاثية الأبعاد (منظور + دوران حول المحور الرأسي)،
// ثم ينفتح المشهد على صور المسجد الحقيقية.
//
// ملاحظة أمانة: الدعاء المعروض في _DuaCard موثّق بدقة
// (صحيح مسلم، حديث 713) وهو النص فقط دون أي إضافة تحريرية.
// بقية الجمل في هذه الشاشة (العناوين والفرعيات) صياغة
// تحريرية من رِفقة وليست اقتباسًا من نص شرعي.

const _night = Color(0xFF04130F);
const _emerald = Color(0xFF104B39);
const _gold = Color(0xFFC9A96E);
const _goldBright = Color(0xFFF6E6C0);

class MadinahGateExperience extends StatefulWidget {
  const MadinahGateExperience({
    super.key,
    required this.onEnter,
    this.backgroundAsset = 'assets/images/madinah/minarets_sunset.png',
    this.gateAsset = 'assets/images/madinah/gate_sultan_abdulmajeed.png',
    this.title = 'المسجد النبوي الشريف',
    this.subtitle = 'قفي لحظة... واستشعري عظمة المكان قبل أن تدخلي',
  });

  /// يُستدعى بعد اكتمال حركة الدخول (أو فور الضغط على "تخطي").
  /// الشاشة لا تقوم بالتنقل بنفسها؛ القرار متروك للمستدعي:
  /// افتحي بعدها المسجد النبوي، أو الجولة البصرية، أو أي وجهة.
  final VoidCallback onEnter;

  final String backgroundAsset;
  final String gateAsset;
  final String title;
  final String subtitle;

  @override
  State<MadinahGateExperience> createState() => _MadinahGateExperienceState();
}

class _MadinahGateExperienceState extends State<MadinahGateExperience>
    with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat(reverse: true);

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  late final Animation<double> _ambientScale = Tween<double>(
    begin: 1.0,
    end: 1.07,
  ).animate(CurvedAnimation(parent: _ambient, curve: Curves.easeInOut));

  late final Animation<double> _introFade = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(
    CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.12, 0.42, curve: Curves.easeIn),
    ),
  );

  late final Animation<double> _doorAngle = Tween<double>(
    begin: 0.0,
    end: math.pi * 0.47,
  ).animate(
    CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
    ),
  );

  late final Animation<double> _doorFade = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(
    CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
    ),
  );

  late final Animation<double> _burst = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.88), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 0.0), weight: 60),
  ]).animate(
    CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ),
  );

  late final Animation<double> _duaReveal = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.52, 1.0, curve: Curves.easeOut),
  );

  late final Animation<double> _vignette = Tween<double>(
    begin: 1.0,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));

  late final List<_Spark> _sparks = List.generate(24, (i) => _Spark.seeded(i));

  bool _opening = false;
  bool _didEnter = false;

  @override
  void initState() {
    super.initState();
    _entry.addStatusListener(_handleEntryStatus);
  }

  void _handleEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future.delayed(const Duration(milliseconds: 550), () {
        _finishOnce();
      });
    }
  }

  void _finishOnce() {
    if (!mounted || _didEnter) return;
    _didEnter = true;
    widget.onEnter();
  }

  @override
  void dispose() {
    _entry.removeStatusListener(_handleEntryStatus);
    _ambient.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _open() {
    if (_opening) return;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    setState(() => _opening = true);

    if (reduceMotion) {
      _finishOnce();
      return;
    }

    _entry.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            _sparkLayer(),
            _vignetteLayer(),
            _gateLayer(),
            _burstLayer(),
            _content(),
            _skipButton(),
          ],
        ),
      ),
    );
  }

  // ── Layers ──────────────────────────────────────────

  Widget _background() {
    return AnimatedBuilder(
      animation: _ambientScale,
      builder: (context, child) {
        return Transform.scale(scale: _ambientScale.value, child: child);
      },
      child: Image.asset(
        widget.backgroundAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_night, _emerald],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sparkLayer() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          return CustomPaint(
            painter: _SparkPainter(sparks: _sparks, t: _ambient.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _vignetteLayer() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _vignette,
        builder: (context, _) {
          final double dim = _vignette.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  _night.withValues(alpha: 0.38 * dim),
                  _night.withValues(alpha: 0.88 * dim),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _gateLayer() {
    return AnimatedBuilder(
      animation: _entry,
      builder: (context, _) {
        return Opacity(
          opacity: _doorFade.value,
          child: Row(
            children: [
              Expanded(
                child: _GateDoor(
                  asset: widget.gateAsset,
                  angle: _doorAngle.value,
                  pivotLeft: true,
                ),
              ),
              Expanded(
                child: _GateDoor(
                  asset: widget.gateAsset,
                  angle: _doorAngle.value,
                  pivotLeft: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _burstLayer() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burst,
        builder: (context, _) {
          return Opacity(
            opacity: _burst.value,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [_goldBright, Colors.transparent],
                  stops: [0, 0.78],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 34),
        child: Column(
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _introFade,
              builder: (context, child) {
                return Opacity(opacity: _introFade.value, child: child);
              },
              child: Column(
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(color: _gold, fontSize: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13.5,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _duaReveal,
              builder: (context, child) {
                return Opacity(
                  opacity: _duaReveal.value,
                  child: Transform.translate(
                    offset: Offset(0, (1.0 - _duaReveal.value) * 14),
                    child: child,
                  ),
                );
              },
              child: const _DuaCard(),
            ),
            const Spacer(),
            if (!_opening)
              Column(
                children: [
                  _EnterButton(onTap: _open),
                  const SizedBox(height: 12),
                  Text(
                    'المسي الباب لتدخلي',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(_gold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _skipButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: TextButton(
            onPressed: _finishOnce,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.72),
            ),
            child: const Text('تخطي'),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Gate door (perspective + rotateY swing)
// ───────────────────────────────────────────────────────

class _GateDoor extends StatelessWidget {
  const _GateDoor({
    required this.asset,
    required this.angle,
    required this.pivotLeft,
  });

  final String asset;
  final double angle;
  final bool pivotLeft;

  @override
  Widget build(BuildContext context) {
    final Alignment pivot =
        pivotLeft ? Alignment.centerLeft : Alignment.centerRight;
    final double signedAngle = pivotLeft ? angle : -angle;

    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateY(signedAngle);

    return Transform(
      alignment: pivot,
      transform: transform,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: pivotLeft
                ? BorderSide.none
                : const BorderSide(color: _gold, width: 1.1),
            right: pivotLeft
                ? const BorderSide(color: _gold, width: 1.1)
                : BorderSide.none,
          ),
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: pivotLeft ? Alignment.centerRight : Alignment.centerLeft,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: _emerald);
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Dua card — نص موثّق فقط
// ───────────────────────────────────────────────────────

class _DuaCard extends StatelessWidget {
  const _DuaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome, color: _gold, size: 18),
          SizedBox(height: 10),
          Text(
            'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.9,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'دعاء دخول المسجد · صحيح مسلم، حديث 713',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Enter button — نبضة ذهبية هادئة
// ───────────────────────────────────────────────────────

class _EnterButton extends StatefulWidget {
  const _EnterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final double glow = _pulse.value * 9 + 6;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.45),
                blurRadius: glow,
                spreadRadius: glow * 0.18,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: _gold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          child: const Padding(
            padding: EdgeInsets.all(22),
            child: Icon(Icons.mosque_rounded, color: _night, size: 26),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Sparks — غبار ذهبي عائم
// ───────────────────────────────────────────────────────

class _Spark {
  const _Spark({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  factory _Spark.seeded(int i) {
    final math.Random rand = math.Random(i * 97 + 11);
    final double x = rand.nextDouble();
    final double y = rand.nextDouble();
    final double size = rand.nextDouble() * 2.0 + 1.0;
    final double speed = rand.nextDouble() * 0.5 + 0.35;
    final double phase = rand.nextDouble();
    return _Spark(x: x, y: y, size: size, speed: speed, phase: phase);
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.sparks, required this.t});

  final List<_Spark> sparks;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (final _Spark spark in sparks) {
      double progress = t * spark.speed + spark.phase;
      progress = progress - progress.floor();

      final double dy =
          spark.y * size.height - progress * size.height * 0.22;
      final double dx =
          spark.x * size.width + math.sin(progress * math.pi * 2) * 9;

      final double wave = math.sin(progress * math.pi);
      final double alpha = wave < 0 ? 0 : wave;

      paint.color = _gold.withValues(alpha: alpha * 0.6);
      canvas.drawCircle(Offset(dx, dy), spark.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => true;
}
