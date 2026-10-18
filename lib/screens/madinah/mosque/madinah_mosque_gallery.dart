import 'dart:math' as math;

import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────
// رِفقة · جولة المسجد النبوي البصرية
// ───────────────────────────────────────────────────────
// عرض بطاقات بمنظور ثلاثي الأبعاد (تدوير + تصغير حسب
// المسافة عن المركز) لصور حقيقية من المسجد النبوي، بأسلوب
// "Coverflow". كل عنصر هنا وصف معماري/مكاني بحت — لا يحمل
// أي نص حديثي أو اقتباس شرعي؛ الأحاديث الموثقة موجودة في
// قسم "حكايات المدينة" مع مصادرها الكاملة.

const _night = Color(0xFF04130F);
const _emerald = Color(0xFF104B39);
const _gold = Color(0xFFC9A96E);

double _clampD(double v, double lo, double hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

class MosqueGalleryItem {
  const MosqueGalleryItem({
    required this.assetPath,
    required this.title,
    required this.caption,
  });

  final String assetPath;
  final String title;
  final String caption;
}

/// مجموعة الصور الافتراضية التي رفعتها صاحبة التطبيق لهذا
/// القسم. يمكن استبدالها أو تمرير قائمة مختلفة عبر [MosqueGalleryItem]
/// في أي مكان آخر من التطبيق.
const List<MosqueGalleryItem> defaultMosqueGalleryItems = [
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/exterior_sunset_wide.png',
    title: 'المسجد النبوي الشريف',
    caption: 'حيث سكن الحبيب ﷺ، وحيث تهفو القلوب شوقًا',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/courtyard_day_umbrella.png',
    title: 'صحن المسجد',
    caption: 'المظلات الكبرى تفتح فوق الصحن كزهرة بيضاء',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/rawdah_grille.png',
    title: 'الروضة الشريفة',
    caption: 'موضعٌ ورد في فضله حديثٌ صحيح — اقرئي حكايته في قسم الحكايات',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/quran_courtyard.png',
    title: 'في رحاب القرآن',
    caption: 'لحظة تلاوة هادئة في صحن المسجد عند الفجر',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/minarets_sunset.png',
    title: 'مآذن المسجد',
    caption: 'تزيّن أفق المدينة المنورة عند الغروب',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/gate_umar.png',
    title: 'باب عمر بن الخطاب رضي الله عنه',
    caption: 'أحد أبواب المسجد النبوي الكثيرة، الباب رقم 17',
  ),
  MosqueGalleryItem(
    assetPath: 'assets/images/madinah/gate_sultan_abdulmajeed.png',
    title: 'باب السلطان عبد المجيد',
    caption: 'نُقش عليه: ادخلوها بسلام آمنين',
  ),
];

/// شاشة كاملة تحوي الجولة البصرية — جاهزة للفتح مباشرة من
/// أي مكان في التطبيق (push عادي، أو بعد MadinahGateExperience).
class MadinahMosqueGalleryScreen extends StatelessWidget {
  const MadinahMosqueGalleryScreen({
    super.key,
    this.items = defaultMosqueGalleryItems,
  });

  final List<MosqueGalleryItem> items;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'استشعري عظمة المكان ﷺ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(child: Mosque3DCarousel(items: items)),
            ],
          ),
        ),
      ),
    );
  }
}

/// الكاروسيل القابل لإعادة الاستخدام — يمكن وضعه داخل أي
/// شاشة أخرى (مثل شاشة المدينة الرئيسية) بارتفاع ثابت.
class Mosque3DCarousel extends StatefulWidget {
  const Mosque3DCarousel({
    super.key,
    this.items = defaultMosqueGalleryItems,
    this.onOpen,
  });

  final List<MosqueGalleryItem> items;

  /// يُستدعى عند الضغط على بطاقة (مثلًا لفتحها بملء الشاشة).
  final ValueChanged<MosqueGalleryItem>? onOpen;

  @override
  State<Mosque3DCarousel> createState() => _Mosque3DCarouselState();
}

class _Mosque3DCarouselState extends State<Mosque3DCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.78,
  );

  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncActiveIndex);
  }

  void _syncActiveIndex() {
    if (!_controller.hasClients) return;
    final double? page = _controller.page;
    if (page == null) return;

    final int rounded = page.round();
    final int bounded = rounded < 0
        ? 0
        : (rounded > widget.items.length - 1 ? widget.items.length - 1 : rounded);

    if (bounded != _activeIndex) {
      setState(() => _activeIndex = bounded);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncActiveIndex);
    _controller.dispose();
    super.dispose();
  }

  void _openGalleryItem(MosqueGalleryItem item) {
    if (widget.onOpen != null) {
      widget.onOpen!(item);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MadinahImageDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: math.min(430.0, math.max(165.0, MediaQuery.sizeOf(context).height - 175.0)),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = index.toDouble();
                  if (_controller.hasClients && _controller.page != null) {
                    page = _controller.page!;
                  }

                  final double delta = _clampD(page - index, -1.0, 1.0);
                  final double absDelta = delta < 0 ? -delta : delta;

                  final double angle = delta * 0.6;
                  final double scale = 1.0 - absDelta * 0.16;
                  final double fade = 1.0 - absDelta * 0.55;
                  final double liftY = absDelta * 22;

                  final Matrix4 transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0011)
                    ..rotateY(angle)
                    ..scale(scale, scale);

                  return Opacity(
                    opacity: _clampD(fade, 0.35, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, liftY),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: transform,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  child: _GalleryCard(
                    item: widget.items[index],
                    focused: index == _activeIndex,
                    onTap: () => _openGalleryItem(widget.items[index]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _Dots(count: widget.items.length, activeIndex: _activeIndex),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.item,
    required this.focused,
    required this.onTap,
  });

  final MosqueGalleryItem item;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: focused
                ? _gold.withValues(alpha: 0.9)
                : _gold.withValues(alpha: 0.18),
            width: focused ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _night.withValues(alpha: focused ? 0.55 : 0.25),
              blurRadius: focused ? 26 : 10,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: _emerald);
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD041009)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? _gold : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}


/// تفاصيل الصورة — باللمس للتكبير والتصغير، من غير باكدجات خارجية.
class MadinahImageDetailScreen extends StatelessWidget {
  const MadinahImageDetailScreen({super.key, required this.item});

  final MosqueGalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        appBar: AppBar(
          backgroundColor: _night,
          foregroundColor: Colors.white,
          title: Text(item.title, style: const TextStyle(fontSize: 16)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Text(
                  item.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
