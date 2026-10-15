import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_data.dart';
import '../umrah/umrah_tools.dart';
import 'hajj_duas.dart';
import 'hajj_voice.dart';

/// مكتبة أدعية الحج: تصنيفات، بحث، نطق، عدّاد، مفضلة، تكبير الخط.
class HajjDuasPage extends StatefulWidget {
  /// لفتح الصفحة على تصنيف معيّن (اختياري)
  final String? initialCat;
  final List<HDua> duas;
  final List<List<String>> cats;
  final String title;

  const HajjDuasPage({
    super.key,
    this.initialCat,
    this.duas = hajjDuas,
    this.cats = hajjDuaCats,
    this.title = 'أدعية الحج',
  });

  @override
  State<HajjDuasPage> createState() => _HajjDuasPageState();
}

class _HajjDuasPageState extends State<HajjDuasPage> {
  static final Set<String> _favs = {}; // تبقى طوال عمر التطبيق
  late String cat = widget.initialCat ??
      (widget.cats.isNotEmpty ? widget.cats.first[0] : 'الكل');
  String q = '';
  bool onlyFav = false;
  double scale = 1.0;
  final Map<String, int> _counts = {};
  String? _playing;

  List<HDua> get _list => widget.duas.where((d) {
        if (onlyFav && !_favs.contains(d.id)) return false;
        if (cat != 'الكل' && d.cat != cat) return false;
        if (q.isEmpty) return true;
        return d.title.contains(q) || d.ar.contains(q) || d.source.contains(q);
      }).toList();

  @override
  void dispose() {
    HajjSpeaker.I.stop();
    super.dispose();
  }

  Future<void> _play(HDua d) async {
    setState(() => _playing = d.id);
    await HajjSpeaker.I.say(d.ar, rate: d.rate);
    if (mounted && _playing == d.id) setState(() => _playing = null);
  }

  Future<void> _playAll(List<HDua> l) async {
    if (l.isEmpty) return;
    setState(() => _playing = '*');
    await HajjSpeaker.I.queue([
      for (final d in l) ...[
        HSay('${d.title}.', rate: .5),
        HSay(d.ar, rate: d.rate)
      ]
    ]);
    if (mounted) setState(() => _playing = null);
  }

  void _stop() {
    HajjSpeaker.I.stop();
    setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    return UToolPage(
      title: widget.title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث عن دعاء أو موضع',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: UC.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: UC.border),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in widget.cats)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => cat = c[0]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              cat == c[0] ? AppColors.greenDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cat == c[0] ? AppColors.gold : UC.border),
                        ),
                        child: Text('${c[1]} ${c[0]}',
                            style: TextStyle(
                              color: cat == c[0] ? Colors.white : UC.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                      () => scale = (scale - .1).clamp(.85, 1.5).toDouble()),
                  icon: const Icon(Icons.text_decrease_rounded),
                  color: AppColors.greenDark,
                ),
                IconButton(
                  onPressed: () => setState(
                      () => scale = (scale + .1).clamp(.85, 1.5).toDouble()),
                  icon: const Icon(Icons.text_increase_rounded),
                  color: AppColors.greenDark,
                ),
                FilterChip(
                  label: const Text('المفضلة ♥'),
                  selected: onlyFav,
                  onSelected: (v) => setState(() => onlyFav = v),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _playing == '*' ? _stop : () => _playAll(l),
                  icon: Icon(_playing == '*'
                      ? Icons.stop_circle_rounded
                      : Icons.headphones_rounded),
                  label: Text(_playing == '*' ? 'إيقاف' : 'اسمع الكل'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.greenDark),
                ),
              ],
            ),
          ),
          Expanded(
            child: l.isEmpty
                ? const Center(
                    child: Text('لا توجد أدعية مطابقة.',
                        style: TextStyle(color: UC.muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: l.length + 1,
                    itemBuilder: (_, k) {
                      if (k == l.length) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'الأدعية المنسوبة لمواضع بعينها غير ثابتة إلا ما نُصّ عليه في المصدر؛ والدعاء بما تحب بلغتك جائز في كل موضع.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: UC.muted, fontSize: 12, height: 1.6),
                          ),
                        );
                      }
                      return _card(l[k]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(HDua d) {
    final fav = _favs.contains(d.id);
    final n = _counts[d.id] ?? 0;
    final done = n >= d.reps;
    final playing = _playing == d.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: UC.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0A1F3D), Color(0xFF083D2D)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                      Text(d.cat,
                          style: const TextStyle(
                              color: AppColors.gold, fontSize: 11.5)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    fav ? _favs.remove(d.id) : _favs.add(d.id);
                  }),
                  icon: Icon(
                      fav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: fav ? Colors.redAccent : Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(d.ar,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: UC.ink,
                    fontSize: 20 * scale,
                    height: 2.0,
                    fontWeight: FontWeight.w700)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.softGold,
                borderRadius: BorderRadius.circular(12)),
            child: Text(d.source,
                style: const TextStyle(
                    color: UC.ink, fontSize: 12.5, height: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _btn(
                    playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                    playing ? 'إيقاف' : 'اسمعه',
                    () => playing ? _stop() : _play(d),
                    filled: true),
                const SizedBox(width: 8),
                _btn(Icons.copy_rounded, 'نسخ', () {
                  Clipboard.setData(ClipboardData(text: d.ar));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الدعاء')));
                }),
                const Spacer(),
                if (d.reps > 1 || n > 0)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _counts[d.id] = done ? 0 : n + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: done ? AppColors.gold : AppColors.softGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(done ? '✓ تم' : 'عدّاد $n / ${d.reps}',
                          style: const TextStyle(
                              color: UC.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData i, String t, VoidCallback on, {bool filled = false}) =>
      GestureDetector(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    colors: [AppColors.green, AppColors.greenDark])
                : null,
            color: filled ? null : AppColors.softGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i,
                  size: 18, color: filled ? Colors.white : AppColors.greenDark),
              const SizedBox(width: 5),
              Text(t,
                  style: TextStyle(
                      color: filled ? Colors.white : UC.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5)),
            ],
          ),
        ),
      );
}
