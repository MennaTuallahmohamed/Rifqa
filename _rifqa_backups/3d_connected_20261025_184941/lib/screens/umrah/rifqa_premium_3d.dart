import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Interactive VISUAL GUIDE + optional actual GLB model.
/// The aerial art is AI illustration, not a certified architectural map.
/// The GLB is an illustrative 3D model, not photogrammetry.
class RifqaPremium3D extends StatefulWidget {
  const RifqaPremium3D({super.key, required this.kind});
  final String kind; // 'tawaf' or 'sai'

  @override
  State<RifqaPremium3D> createState() => _RifqaPremium3DState();
}

class _RifqaPremium3DState extends State<RifqaPremium3D> {
  static const _dark = Color(0xFF052C24);
  static const _dark2 = Color(0xFF0B4032);
  static const _gold = Color(0xFFE7C57B);
  static const _white = Color(0xFFFFF8E9);

  final TransformationController _photoTransform = TransformationController();
  int _laps = 0;
  int _mode = 0; // 0 illustrated interactive guide, 1 real GLB scene
  bool _rotate = false;
  bool _top = true;
  bool _showTips = true;

  bool get _tawaf => widget.kind == 'tawaf';
  String get _prefsKey => _tawaf ? 'rifqa_premium_tawaf' : 'rifqa_premium_sai';
  String get _model => _tawaf
      ? 'assets/models/rifqa_tawaf_focus.glb'
      : 'assets/models/rifqa_sai_focus.glb';
  String get _image => _tawaf
      ? 'assets/umrah/rifqa_premium/scene_5.jpg'
      : 'assets/umrah/rifqa_premium/scene_8.jpg';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _laps = (prefs.getInt(_prefsKey) ?? 0).clamp(0, 7).toInt();
    });
  }

  Future<void> _adjust(int delta) async {
    final value = (_laps + delta).clamp(0, 7).toInt();
    if (value == _laps) return;
    HapticFeedback.selectionClick();
    setState(() => _laps = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, value);
  }

  Future<void> _officialMap() async {
    final url = Uri.parse(
      'https://alharamain.gov.sa/public/?page=interactive_maps_ar',
    );
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _notice('تعذر فتح خريطة الحرمين — تحققي من الإنترنت');
    } catch (_) {
      if (mounted) _notice('تعذر فتح الخريطة الرسمية');
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _info() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _dark,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_tawaf ? 'كيف تؤدين الطواف؟' : 'كيف تؤدين السعي؟',
                style: const TextStyle(color: _gold,
                    fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text(_tawaf
                ? 'ابدئي من محاذاة الحجر الأسود، واجعلي الكعبة عن يسارك، وأتمي سبع دورات كاملة عكس اتجاه عقارب الساعة. تجنبي المزاحمة وامشي من خارج حِجر إسماعيل.'
                : 'ابدئي من الصفا. الذهاب إلى المروة يُحسب شوطًا، والعودة إلى الصفا شوطًا آخر. الشوط السابع ينتهي عند المروة. يسرع الرجال بين العلامتين الخضراوين إن تيسر، وتمشي النساء مشيًا عاديًا.',
                style: const TextStyle(color: _white,
                    height: 1.8, fontSize: 16)),
              const SizedBox(height: 13),
              const Text('هذه محاكاة تعليمية وليست خريطة ملاحية مباشرة.\nزيادة العداد هنا لتتبع التعلم، ولا تُثبت أداء النسك فعليًا.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _gold, fontSize: 12)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: _gold))),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _photoTransform.dispose();
    super.dispose();
  }

  Widget _switcher() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
    child: Row(children: [
      Expanded(child: _tab('مشهد تفاعلي', _mode == 0, () {
        setState(() => _mode = 0);
      })),
      const SizedBox(width: 8),
      Expanded(child: _tab('مجسم 3D', _mode == 1, () {
        setState(() => _mode = 1);
      })),
    ]),
  );

  Widget _tab(String title, bool selected, VoidCallback onTap) =>
      OutlinedButton(onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? _gold : _dark,
          foregroundColor: selected ? _dark : _gold,
          side: const BorderSide(color: _gold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          minimumSize: const Size.fromHeight(43),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      );

  Widget _photo() => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(fit: StackFit.expand, children: [
      InteractiveViewer(
        transformationController: _photoTransform,
        minScale: 1,
        maxScale: 4,
        child: Image.asset(_image, fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stack) => const ColoredBox(
            color: _dark2,
            child: Center(child: Icon(Icons.image_outlined,
              color: _gold, size: 60)),
          )),
      ),
      Positioned(top: 11, left: 10, child: Material(
        borderRadius: BorderRadius.circular(12),
        color: _dark.withValues(alpha: .90),
        child: IconButton(
          tooltip: 'إعادة التكبير',
          onPressed: () => _photoTransform.value = Matrix4.identity(),
          icon: const Icon(Icons.center_focus_strong, color: _gold),
        ),
      )),
      if (_showTips)
        Positioned(bottom: 10, left: 10, right: 10,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _dark.withValues(alpha: .93),
              border: Border.all(color: _gold.withValues(alpha: .5)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(_tawaf
              ? '↺ ابدئي عند الحجر الأسود، وأبقي الكعبة على يسارك'
              : 'الصفا ← المروة = شوط واحد · العودة = شوط ثانٍ',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontSize: 13)),
          ),
        ),
    ]),
  );

  Widget _glb() => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(fit: StackFit.expand, children: [
      // Old white floor is removed: app and model viewer share dark emerald.
      ModelViewer(
        key: ValueKey('${widget.kind}-$_top-$_rotate'),
        src: _model,
        alt: _tawaf ? 'مجسم تعليمي للكعبة والمطاف' : 'مجسم تعليمي للمسعى',
        ar: false,
        cameraControls: true,
        autoRotate: _rotate,
        disableZoom: false,
        backgroundColor: _dark2,
        cameraOrbit: _top ? '25deg 44deg auto' : '35deg 76deg auto',
      ),
      Positioned(top: 9, right: 9, child: Container(
        decoration: BoxDecoration(color: _dark.withValues(alpha: .93),
          borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'تغيير زاوية الكاميرا',
            onPressed: () => setState(() => _top = !_top),
            icon: const Icon(Icons.threed_rotation, color: _gold)),
          IconButton(tooltip: 'تدوير أو إيقاف',
            onPressed: () => setState(() => _rotate = !_rotate),
            icon: Icon(_rotate ? Icons.pause_circle_outline
                : Icons.rotate_right, color: _gold)),
        ]),
      )),
      Positioned(bottom: 10, left: 10, right: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _dark.withValues(alpha: .93),
            borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('المجسم توضيحي وليس نسخة هندسية دقيقة من الحرم.\nيمكن تدويره وتقريبه بإصبعين.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _white, fontSize: 11)),
          ),
        ),
      ),
    ]),
  );

  Widget _counter() {
    final direction = _tawaf
        ? 'عكس عقارب الساعة · الكعبة عن يسارك'
        : _laps.isEven ? 'الشوط القادم: الصفا ← المروة'
                       : 'الشوط القادم: المروة ← الصفا';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark2, borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _gold.withValues(alpha: .66)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_tawaf ? 'الطواف حول الكعبة' : 'السعي بين الصفا والمروة',
          style: const TextStyle(color: _white, fontSize: 14)),
        Text('الأشواط المكتملة: $_laps من 7',
          style: const TextStyle(color: _gold, fontSize: 19,
              fontWeight: FontWeight.bold)),
        Row(children: List.generate(7, (i) => Expanded(
          child: Container(height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            decoration: BoxDecoration(
              color: i < _laps ? _gold : Colors.white24,
              borderRadius: BorderRadius.circular(9)),
          ),
        ))),
        Text(_laps == 7 ? 'اكتملت الأشواط السبعة في العداد التعليمي' : direction,
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _white, fontSize: 12)),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _laps > 0 ? () => _adjust(-1) : null,
            style: OutlinedButton.styleFrom(foregroundColor: _gold,
              side: const BorderSide(color: _gold)),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('تراجع'),
          )),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(
            onPressed: _laps < 7 ? () => _adjust(1) : null,
            style: FilledButton.styleFrom(backgroundColor: _gold,
              foregroundColor: _dark),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('أتممت شوطًا'),
          )),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward, color: _gold)),
            Expanded(child: Column(children: [
              Text(_tawaf ? 'الطواف التفاعلي' : 'السعي التفاعلي',
                maxLines: 1, textAlign: TextAlign.center,
                style: const TextStyle(color: _gold, fontSize: 19,
                  fontWeight: FontWeight.bold)),
              const Text('مشهد تعليمي · عداد سبعة أشواط',
                style: TextStyle(color: _white, fontSize: 11)),
            ])),
            IconButton(onPressed: _info, tooltip: 'الشرح',
              icon: const Icon(Icons.menu_book_rounded, color: _gold)),
            IconButton(onPressed: _officialMap, tooltip: 'خريطة الحرمين الرسمية',
              icon: const Icon(Icons.map_rounded, color: _gold)),
          ]),
        ),
        _switcher(),
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: _mode == 0 ? _photo() : _glb(),
        )),
        _counter(),
      ])),
    ),
  );
}
