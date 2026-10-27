import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A photo-first teaching scene. The optional model is illustrative, not a
/// photogrammetric reconstruction of the Grand Mosque.
class RifqaPremium3D extends StatefulWidget {
  const RifqaPremium3D({super.key, required this.kind});
  final String kind; // tawaf or sai

  @override
  State<RifqaPremium3D> createState() => _RifqaPremium3DState();
}

class _RifqaPremium3DState extends State<RifqaPremium3D> {
  static const _dark = Color(0xFF052C24);
  static const _gold = Color(0xFFE7C57B);
  static const _cream = Color(0xFFFFF7E8);
  static const _green = Color(0xFF0B6B52);
  int _laps = 0;
  bool _showModel = false;
  bool _rotate = false;
  bool _topView = true;

  bool get tawaf => widget.kind == 'tawaf';
  String get _key => tawaf ? 'rifqa_premium_tawaf' : 'rifqa_premium_sai';
  String get _model => tawaf
      ? 'assets/models/tawaf_haram_animated.glb'
      : 'assets/models/sai_haram_animated.glb';
  String get _photo => tawaf
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
    setState(() => _laps = (prefs.getInt(_key) ?? 0).clamp(0, 7).toInt());
  }

  Future<void> _change(int by) async {
    final count = (_laps + by).clamp(0, 7).toInt();
    setState(() => _laps = count);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, count);
    HapticFeedback.selectionClick();
  }

  Future<void> _officialMap() async {
    final uri = Uri.parse('https://alharamain.gov.sa/public/?page=interactive_maps_ar');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذر فتح خريطة الحرمين الآن، تحققي من الإنترنت'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذر فتح الخريطة الرسمية'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = tawaf ? 'الطواف حول الكعبة' : 'السعي بين الصفا والمروة';
    final description = tawaf
        ? 'ابدئي من الحجر الأسود، والكعبة عن يسارك. كل دورة حول الكعبة شوط واحد.'
        : 'ابدئي من الصفا؛ الوصول إلى المروة شوط، والعودة إلى الصفا شوط آخر.';
    final next = tawaf
        ? 'اتجاه الطواف عكس عقارب الساعة؛ الكعبة عن يسارك.'
        : _laps.isEven ? 'الاتجاه التالي: الصفا ← المروة' : 'الاتجاه التالي: المروة ← الصفا';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _dark,
        body: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 3),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward_rounded, color: _gold)),
              Expanded(child: Text(title, textAlign: TextAlign.center,
                style: const TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w800))),
              IconButton(onPressed: _officialMap, tooltip: 'خريطة الحرمين الرسمية',
                icon: const Icon(Icons.map_outlined, color: _gold)),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('تجربة تعليمية؛ الصور والمجسمات توضيحية وليست ملاحة مباشرة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(children: [
              Expanded(child: _tab('مشهد مصوّر', !_showModel, () => setState(() => _showModel = false))),
              const SizedBox(width: 9),
              Expanded(child: _tab('المجسم ثلاثي الأبعاد', _showModel, () => setState(() => _showModel = true))),
            ]),
          ),
          if (_showModel)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton.icon(onPressed: () => setState(() => _topView = !_topView),
                  icon: const Icon(Icons.threed_rotation, size: 17),
                  label: Text(_topView ? 'من الأعلى' : 'من الجانب'),
                  style: TextButton.styleFrom(foregroundColor: _gold)),
                TextButton.icon(onPressed: () => setState(() => _rotate = !_rotate),
                  icon: Icon(_rotate ? Icons.pause : Icons.play_arrow, size: 17),
                  label: Text(_rotate ? 'إيقاف الدوران' : 'تدوير المجسم'),
                  style: TextButton.styleFrom(foregroundColor: _gold)),
              ]),
            ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(fit: StackFit.expand, children: [
                if (_showModel)
                  ModelViewer(
                    key: ValueKey('${widget.kind}|$_topView|$_rotate'),
                    src: _model,
                    alt: title,
                    ar: false,
                    autoRotate: _rotate,
                    cameraControls: true,
                    backgroundColor: const Color(0xFFF2E9D6),
                    cameraOrbit: _topView ? '20deg 28deg auto' : '20deg 72deg auto',
                    disableZoom: false,
                  )
                else
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 3.5,
                    child: SizedBox.expand(child: Image.asset(
                      _photo, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: _green, child: Center(child: Icon(Icons.image_not_supported,
                          size: 50, color: _gold)),
                      ),
                    )),
                  ),
                if (!_showModel)
                  Positioned(bottom: 12, left: 9, right: 9,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _dark.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(15)),
                      child: Text(tawaf
                          ? '↺ الكعبة عن يسارك · يبدأ الشوط من الحجر الأسود'
                          : 'الصفا ← المروة ← الصفا · كل اتجاه شوط مستقل',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _gold, fontSize: 13)),
                    ),
                  ),
              ]),
            ),
          )),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF093F32),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withValues(alpha: .6)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(description, textAlign: TextAlign.center,
                style: const TextStyle(color: _cream, fontSize: 13, height: 1.5)),
              const SizedBox(height: 6),
              Text('الأشواط المكتملة: $_laps / 7',
                style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold)),
              Row(children: List.generate(7, (i) => Expanded(child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: i < _laps ? _gold : Colors.white24,
                ),
              )))),
              Text(_laps == 7 ? 'اكتملت الأشواط السبعة في الدليل التعليمي' : next,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _laps > 0 ? () => _change(-1) : null,
                  icon: const Icon(Icons.undo, size: 17), label: const Text('تراجع'),
                  style: OutlinedButton.styleFrom(foregroundColor: _gold,
                    side: const BorderSide(color: _gold)),
                )),
                const SizedBox(width: 9),
                Expanded(child: FilledButton.icon(
                  onPressed: _laps < 7 ? () => _change(1) : null,
                  icon: const Icon(Icons.add, size: 17), label: const Text('أتممت شوطًا'),
                  style: FilledButton.styleFrom(backgroundColor: _gold,
                    foregroundColor: _dark),
                )),
              ]),
            ]),
          ),
        ])),
      ),
    );
  }

  Widget _tab(String title, bool selected, VoidCallback action) => OutlinedButton(
    onPressed: action,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected ? _gold : _dark,
      foregroundColor: selected ? _dark : _gold,
      side: const BorderSide(color: _gold),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  );
}
