import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_data.dart';
import 'hajj_data.dart';
import 'hajj_duas.dart';
import 'hajj_voice.dart';
import 'widgets/hajj_scenes.dart';

/// وضع المرشد: يمشي بك في المنسك خطوة خطوة، بصوت وصورة ودعاء كل خطوة.
/// يرجع true عند الضغط على «أتممت المنسك».
class HajjGuidePage extends StatefulWidget {
  final int index;
  final UStep step;
  const HajjGuidePage({super.key, required this.index, required this.step});

  @override
  State<HajjGuidePage> createState() => _HajjGuidePageState();
}

class _HajjGuidePageState extends State<HajjGuidePage> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _auto = true;
  final Map<String, int> _counts = {};

  UStep get s => widget.step;
  int get _total => s.how.length + 1; // الخطوات + صفحة الختام

  HDua? _duaFor(int p) {
    final id = hajjMicroDuas[widget.index]?[p];
    return id == null ? null : hajjDuaById(id);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  void dispose() {
    HajjSpeaker.I.stop();
    _pc.dispose();
    super.dispose();
  }

  List<HSay> _items(int p) {
    if (p < s.how.length) {
      final d = _duaFor(p);
      return [
        HSay(hajjMicroNarration(p, s.how.length, s.how[p])),
        if (d != null) ...[
          const HSay('ويقال فيها:', rate: .5),
          HSay(d.ar, rate: d.rate),
        ],
      ];
    }
    return [
      HSay('نصيحة: ${s.tip}'),
      if (s.women != null) HSay('للمرأة: ${s.women}'),
      const HSay(
          'تقبّل الله منك. اضغط أتممت المنسك للانتقال إلى الخطوة التالية.'),
    ];
  }

  void _speak() {
    if (!mounted || !_auto) return;
    HajjSpeaker.I.queue(_items(_page));
  }

  void _go(int delta) {
    final n = (_page + delta).clamp(0, _total - 1).toInt();
    if (n == _page) return;
    HapticFeedback.selectionClick();
    _pc.animateToPage(n,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071322),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1F3D), Color(0xFF0B2E2B), Color(0xFF071322)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _top(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HajjScene(
                  index: widget.index,
                  height: 150,
                  overlay: Positioned(
                    right: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${hajjStepSite[widget.index]} · ${hajjStepDay[widget.index]}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _segments(),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _total,
                  onPageChanged: (p) {
                    setState(() => _page = p);
                    _speak();
                  },
                  itemBuilder: (_, p) =>
                      p < s.how.length ? _stepPage(p) : _finalPage(),
                ),
              ),
              _bottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _top() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وضع المرشد · المنسك ${widget.index + 1} من 8',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(s.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: HajjSpeaker.I.busy,
              builder: (_, busy, __) => IconButton(
                tooltip: busy ? 'إيقاف الصوت' : 'اسمع الخطوة',
                onPressed: () => busy ? HajjSpeaker.I.stop() : _forceSpeak(),
                icon: Icon(
                  busy ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: busy ? AppColors.gold : Colors.white70,
                ),
              ),
            ),
            Column(
              children: [
                Switch(
                  value: _auto,
                  activeColor: AppColors.gold,
                  onChanged: (v) {
                    setState(() => _auto = v);
                    if (v) {
                      _speak();
                    } else {
                      HajjSpeaker.I.stop();
                    }
                  },
                ),
                const Text('تلقائي',
                    style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  void _forceSpeak() {
    HajjSpeaker.I.queue(_items(_page));
  }

  Widget _segments() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            for (int k = 0; k < _total; k++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: k <= _page ? AppColors.gold : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      );

  // ───── صفحة خطوة فرعية
  Widget _stepPage(int p) {
    final d = _duaFor(p);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [AppColors.gold, Color(0xFFB88A2E)]),
                    ),
                    child: Text('${p + 1}',
                        style: const TextStyle(
                            color: Color(0xFF3B2A00),
                            fontSize: 19,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Text('من ${s.how.length} خطوات',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 14),
              Text(s.how[p],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.85,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (d != null) ...[const SizedBox(height: 14), _duaCard(d)],
      ],
    );
  }

  Widget _duaCard(HDua d) {
    final n = _counts[d.id] ?? 0;
    final done = n >= d.reps;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F5E45), Color(0xFF083D2D)],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(.7), width: 1.3),
      ),
      child: Column(
        children: [
          Text('✦ ${d.title} ✦',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5)),
          const SizedBox(height: 10),
          Text(d.ar,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 2.0,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(d.source,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 11.5, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              _mini(Icons.volume_up_rounded, 'اسمعه', () {
                HajjSpeaker.I.say(d.ar, rate: d.rate);
              }),
              const SizedBox(width: 8),
              _mini(Icons.copy_rounded, 'نسخ', () {
                Clipboard.setData(ClipboardData(text: d.ar));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الدعاء')));
              }),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _counts[d.id] = done ? 0 : n + 1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        done ? AppColors.gold : Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(.6)),
                  ),
                  child: Text(
                    done ? '✓ تم' : 'عدّاد  $n / ${d.reps}',
                    style: TextStyle(
                        color: done ? const Color(0xFF3B2A00) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(IconData i, String t, VoidCallback on) => GestureDetector(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, color: Colors.white, size: 18),
              const SizedBox(width: 5),
              Text(t,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  // ───── صفحة الختام
  Widget _finalPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      physics: const BouncingScrollPhysics(),
      children: [
        _note('💡 نصيحة', s.tip, const Color(0xFF3A3220)),
        if (s.women != null)
          _note('🌸 للمرأة', s.women!, const Color(0xFF332443)),
        if (s.errors.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text('أخطاء شائعة تجنّبها',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ),
          for (final e in s.errors)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ ${e.wrong}',
                      style: const TextStyle(
                          color: Color(0xFFFFB4AB),
                          height: 1.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('✅ ${e.right}',
                      style: const TextStyle(
                          color: Color(0xFFB7F0D2), height: 1.55)),
                ],
              ),
            ),
        ],
        const SizedBox(height: 6),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: const Color(0xFF3B2A00),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('أتممت المنسك',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _note(String t, String x, Color c) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t,
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(x,
                style: const TextStyle(
                    color: Colors.white, height: 1.65, fontSize: 14.5)),
          ],
        ),
      );

  Widget _bottom() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _page == 0 ? null : () => _go(-1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white24,
                  side: BorderSide(
                      color: _page == 0 ? Colors.white12 : Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('السابقة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _page >= _total - 1 ? null : () => _go(1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('الخطوة التالية',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
}
