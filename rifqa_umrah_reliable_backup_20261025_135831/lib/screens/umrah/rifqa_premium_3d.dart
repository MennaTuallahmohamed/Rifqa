import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A genuine rotatable GLB viewer for the project's existing Tawaf and Sa'i models.
/// These are educational models and never substitute for performing the rituals.
class RifqaPremium3D extends StatefulWidget {
  const RifqaPremium3D({super.key, required this.kind});
  final String kind; // tawaf / sai
  @override
  State<RifqaPremium3D> createState() => _RifqaPremium3DState();
}

class _RifqaPremium3DState extends State<RifqaPremium3D> {
  static const _dark = Color(0xFF052C24);
  static const _gold = Color(0xFFE7C57B);
  int _laps = 0;
  bool _rotate = true;
  bool _topView = true;

  bool get tawaf => widget.kind == 'tawaf';
  String get _key => tawaf ? 'rifqa_premium_tawaf' : 'rifqa_premium_sai';
  String get _model => tawaf
      ? 'assets/models/tawaf_haram_animated.glb'
      : 'assets/models/sai_haram_animated.glb';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _laps = (prefs.getInt(_key) ?? 0).clamp(0, 7).toInt());
  }

  Future<void> _change(int delta) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _laps = (_laps + delta).clamp(0, 7).toInt());
    await prefs.setInt(_key, _laps);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final description = tawaf
        ? 'من الحجر الأسود، والكعبة عن يسارك، حتى تكتملي سبعة أشواط.'
        : 'ابدئي من الصفا: الذهاب إلى المروة شوط، والرجوع شوط آخر.';
    final nextDirection = tawaf
        ? 'اتجاه الحركة: عكس عقارب الساعة، الكعبة عن اليسار'
        : _laps.isEven ? 'الشوط التالي: الصفا ← المروة' : 'الشوط التالي: المروة ← الصفا';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _dark,
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward_rounded, color: _gold)),
              Expanded(child: Text(tawaf ? 'الطواف ثلاثي الأبعاد' : 'السعي ثلاثي الأبعاد',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => setState(() => _rotate = !_rotate),
                tooltip: 'تشغيل / إيقاف دوران النموذج',
                icon: Icon(_rotate ? Icons.pause_circle_outline : Icons.threesixty, color: _gold)),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('محاكاة تعليمية ثلاثية الأبعاد — وليست تصويرًا حقيقيًا أو أداءً للنسك',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ChoiceChip(label: const Text('من الأعلى'), selected: _topView,
              selectedColor: _gold, onSelected: (_) => setState(() => _topView = true)),
            const SizedBox(width: 10),
            ChoiceChip(label: const Text('من الجانب'), selected: !_topView,
              selectedColor: _gold, onSelected: (_) => setState(() => _topView = false)),
          ]),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(fit: StackFit.expand, children: [
                ModelViewer(
                  key: ValueKey('${widget.kind}|$_topView|$_rotate'),
                  src: _model,
                  alt: tawaf ? 'نموذج توضيحي للطواف حول الكعبة' : 'نموذج توضيحي للمسعى',
                  ar: false,
                  autoRotate: _rotate,
                  cameraControls: true,
                  backgroundColor: const Color(0xFFF2E9D6),
                  cameraOrbit: _topView ? '20deg 28deg auto' : '20deg 72deg auto',
                  disableZoom: false,
                ),
                const Positioned(bottom: 12, left: 8, right: 8,
                  child: Text('حرّكي المجسم بإصبعك · قرّبيه بإصبعين',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _dark))),
              ]),
            ),
          )),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(13, 0, 13, 13),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF093F32),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _gold.withValues(alpha: .6)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(description, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.5)),
              const SizedBox(height: 8),
              Text('الأشواط المكتملة: $_laps / 7',
                style: const TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.bold)),
              Row(children: List.generate(7, (i) => Expanded(child: Container(
                height: 7, margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: i < _laps ? _gold : Colors.white24,
                ),
              )))),
              Text(_laps == 7 ? 'أكملتِ الأشواط السبعة في العداد التعليمي' : nextDirection,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 9),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _laps > 0 ? () => _change(-1) : null,
                  icon: const Icon(Icons.undo), label: const Text('التراجع'),
                  style: OutlinedButton.styleFrom(foregroundColor: _gold,
                    side: const BorderSide(color: _gold)))),
                const SizedBox(width: 9),
                Expanded(child: FilledButton.icon(onPressed: _laps < 7 ? () => _change(1) : null,
                  icon: const Icon(Icons.add), label: const Text('أتممت شوطًا'),
                  style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _dark))),
              ]),
            ]),
          ),
        ])),
      ),
    );
  }
}
