import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'cinematic_theme.dart';

class _SalawatText {
  const _SalawatText(this.title, this.text, this.source, this.note);
  final String title, text, source, note;
}

const _salawat = <_SalawatText>[
  _SalawatText('أمر القرآن بالصلاة على النبي ﷺ',
    'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
    'سورة الأحزاب، الآية 56', 'آية قرآنية وليست صيغة صلاة يبتدعها التطبيق.'),
  _SalawatText('الصلاة الإبراهيمية',
    'اللهم صل على محمد وعلى آل محمد، كما صليت على إبراهيم وعلى آل إبراهيم، إنك حميد مجيد. اللهم بارك على محمد وعلى آل محمد، كما باركت على إبراهيم وعلى آل إبراهيم، إنك حميد مجيد.',
    'صحيح البخاري، كتاب أحاديث الأنبياء، حديث 3370 (توجد صيغ صحيحة أخرى)',
    'هذه صيغة مشهورة من الصلوات المأثورة؛ قارني الضبط بلفظ الرواية المعتمدة قبل النشر.'),
  _SalawatText('صيغة مختصرة',
    'اللهم صل وسلم على نبينا محمد.',
    'صيغة دعاء جائزة، لا تُنسب بهذا اللفظ إلى حديث بعينه',
    'صياغة دعائية مختصرة دون نسبة مصدر حديثي مخصوص.'),
];

class CinematicSalawatScreen extends StatefulWidget {
  const CinematicSalawatScreen({super.key});
  @override
  State<CinematicSalawatScreen> createState() => _CinematicSalawatScreenState();
}

class _CinematicSalawatScreenState extends State<CinematicSalawatScreen> {
  final FlutterTts _tts = FlutterTts();
  int _active = -1;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ar-SA');
    _tts.setSpeechRate(.42);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _active = -1); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _active = -1); });
  }

  Future<void> _play(int index) async {
    await _tts.stop();
    if (_active == index) {
      if (mounted) setState(() => _active = -1);
      return;
    }
    if (!mounted) return;
    setState(() => _active = index);
    try {
      await _tts.speak(_salawat[index].text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _active = -1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد صوت عربي متاح على الجهاز')));
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFFCF8EF),
      appBar: AppBar(backgroundColor: const Color(0xFFFCF8EF),
        foregroundColor: cinematicGreen,
        leading: IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios_rounded)),
        title: const Text('الصلاة والسلام ﷺ')),
      body: ListView(padding: const EdgeInsets.fromLTRB(17, 10, 17, 35), children: [
        ClipRRect(borderRadius: BorderRadius.circular(28),
          child: SizedBox(height: 245, child: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/minarets_sunset.jpg'),
            const ColoredBox(color: Color(0xBB032C20)),
            const Padding(padding: EdgeInsets.all(20), child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.favorite_border_rounded, color: cinematicGold, size: 40),
                SizedBox(height: 12),
                CinematicHeading('اللهم صلِّ وسلِّم على نبينا محمد ﷺ',
                  subtitle: 'صيغ موثقة ودعاء وقلب مطمئن', size: 23),
              ])),
          ]))),
        const SizedBox(height: 18),
        for (int i = 0; i < _salawat.length; i++) ...[
          _PrayerCard(item: _salawat[i], active: _active == i,
            onPlay: () => _play(i)),
          const SizedBox(height: 13),
        ],
        const Text('الصوت قراءة آلية للنص بواسطة الجهاز، وليس تسجيلًا منسوبًا للنبي ﷺ.\nتُراجع الألفاظ والمراجع دينيًا قبل النشر.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7D8178), fontSize: 12, height: 1.5)),
      ]),
    ),
  );
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({required this.item, required this.active, required this.onPlay});
  final _SalawatText item;
  final bool active;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(23),
    child: Container(padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE4D8C1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: const TextStyle(color: cinematicGreen,
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Text(item.text, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, height: 2.1,
            fontWeight: FontWeight.w600, color: Color(0xFF243B32))),
        const SizedBox(height: 10),
        Text(item.source, style: const TextStyle(color: Color(0xFF8A6D37),
          fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(item.note, style: const TextStyle(color: Color(0xFF868A84),
          fontSize: 11, height: 1.5)),
        const SizedBox(height: 13),
        Align(alignment: Alignment.centerLeft, child: CinematicButton(
          label: active ? 'إيقاف الاستماع' : 'استمعي للنص',
          icon: active ? Icons.pause_rounded : Icons.volume_up_rounded,
          onPressed: onPlay)),
      ]),
    ),
  );
}
