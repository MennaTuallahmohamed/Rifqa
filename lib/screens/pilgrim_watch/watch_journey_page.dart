import 'package:flutter/material.dart';
import '../../services/pilgrim_watch/watch_store.dart';
import 'watch_ui.dart';

class WatchRite {
  const WatchRite(this.name, this.summary, this.icon, this.guidance);
  final String name, summary, guidance;
  final IconData icon;
}

const _umrah = <WatchRite>[
  WatchRite('الميقات والتلبية', 'الاستعداد والإحرام', Icons.volunteer_activism,
      'استعد للإحرام من الميقات المناسب لمسارك، وانْوِ النسك وابدأ التلبية. تذكير تعليمي، وليس بديلًا عن الإرشاد الشرعي.'),
  WatchRite('دخول المسجد الحرام', 'الدخول والآداب', Icons.mosque,
      'ادخل بسكينة، واتبع الإرشادات الرسمية ومسارات الحشود، وادعُ بدعاء دخول المسجد.'),
  WatchRite('مشاهدة الكعبة', 'التعرّف على المعالم', Icons.crop_square_rounded,
      'تعرّف على الركن الذي فيه الحجر الأسود، والركن اليماني، والحِجر ومقام إبراهيم.'),
  WatchRite('الطواف', 'سبعة أشواط', Icons.autorenew_rounded,
      'ابدأ من محاذاة الحجر الأسود، واجعل الكعبة على يسارك، وأتم سبعة أشواط خارج الحِجر. العداد يدوي للتذكير فقط.'),
  WatchRite('مقام إبراهيم', 'ركعتا الطواف', Icons.account_balance_rounded,
      'صلِّ ركعتين بعد الطواف حيث يتيسر، ولا تُعطّل الطائفين أو تؤذِ الزحام.'),
  WatchRite('ماء زمزم', 'اشرب وتزود', Icons.water_drop,
      'يمكنك شرب ماء زمزم من نقاط الشرب المتاحة وفق تنظيم الحرم. البئر نفسه ليس موقع زيارة مفتوحًا.'),
  WatchRite('السعي بين الصفا والمروة', 'سبعة أشواط', Icons.directions_walk,
      'ابدأ من الصفا نحو المروة؛ الذهاب شوط والعودة شوط. الشوط السابع ينتهي عند المروة.'),
  WatchRite('الحلق أو التقصير', 'ختام خطوات العمرة', Icons.content_cut,
      'تعرف على كيفية التحلل للرجال والنساء. إكمال القائمة هنا لا يعني أداء العمرة حقيقةً.'),
];

const _hajj = <WatchRite>[
  WatchRite('الإحرام للحج', 'النية والتلبية', Icons.volunteer_activism,
      'تختلف التفاصيل حسب التمتع والقران والإفراد؛ اتبع خطة النسك المعتمدة.'),
  WatchRite('منى — يوم التروية', 'الاستعداد والتنقل', Icons.holiday_village,
      'راجع التصريح وخطة النقل والوقت المحدد لفوجك، واتبع تعليمات التنظيم.'),
  WatchRite('الوقوف بعرفة', 'أعظم مناسك الحج', Icons.landscape,
      'انتبه للوقت المحدد شرعًا وخطة الوصول، وأكثر من الدعاء والذكر.'),
  WatchRite('مزدلفة', 'بعد الإفاضة من عرفة', Icons.nightlight_round,
      'اتبع تنظيم المبيت والخروج وفق حالتك وتعليمات السلطات.'),
  WatchRite('منى والجمرات', 'الرمي وتنظيم الحشود', Icons.location_city,
      'التزم المواعيد والمسارات الرسمية، وراعِ أحكام النسك المختلفة.'),
  WatchRite('الهدي والتحلل', 'بحسب نوع النسك', Icons.content_cut,
      'يختلف حكم الهدي بين الأنساك؛ ارجع إلى دليل نسك معتمد.'),
  WatchRite('طواف الإفاضة والسعي', 'بحسب النسك والحالة', Icons.autorenew,
      'تأكد من واجبات السعي في نوع نسكك واتبِع إرشادات الحرم.'),
  WatchRite('أيام التشريق', 'المبيت والرمي', Icons.calendar_month,
      'التزم بالمواقيت والإرشادات الرسمية وحافظ على سلامتك.'),
  WatchRite('طواف الوداع', 'ختام المناسك عند وجوبه', Icons.mosque,
      'تعرف على أحكام الوداع والاستثناءات، فليست الحالات جميعها سواء.'),
];

class RifqaWatchJourneyPage extends StatefulWidget {
  const RifqaWatchJourneyPage({super.key});
  @override State<RifqaWatchJourneyPage> createState() => _RifqaWatchJourneyPageState();
}

class _RifqaWatchJourneyPageState extends State<RifqaWatchJourneyPage> {
  final store = RifqaWatchStore.instance;
  int? inspecting;
  @override void initState() { super.initState(); store.addListener(_changed); store.load(); }
  @override void dispose() { store.removeListener(_changed); super.dispose(); }
  void _changed() { if (mounted) setState(() {}); }

  Future<void> _switch(String type) async {
    if (type == store.journey.type) return;
    final okay = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('بدء دليل جديد؟'),
      content: const Text('سيُعاد ضبط تقدم المحاكاة التعليمية فقط. لا يؤثر هذا على بيانات المناسك الأخرى.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('متابعة'))]));
    if (okay == true) {
      await store.change(() => store.journey = WatchJourney(type: type));
      if (mounted) setState(() => inspecting = null);
    }
  }

  Future<void> _complete(int current, List<WatchRite> stages) async {
    if (store.journey.step != current) return;
    if (store.journey.type == 'umrah' && current == 3 && store.journey.tawafLaps != 7) {
      _toast('كمّلي تسجيل الأشواط السبعة أولًا'); return;
    }
    if (store.journey.type == 'umrah' && current == 6 && store.journey.saiLaps != 7) {
      _toast('كمّلي تسجيل أشواط السعي السبعة أولًا'); return;
    }
    await store.change(() => store.journey = store.journey.copyWith(step: current + 1));
    if (mounted) setState(() => inspecting = null);
    if (current == stages.length - 1) _toast('اكتملت مراجعة المناسك التعليمية، تقبّل الله منكِ');
  }

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _laps(bool tawaf, int delta) => store.change(() {
    final j = store.journey;
    store.journey = tawaf
        ? j.copyWith(tawafLaps: (j.tawafLaps + delta).clamp(0, 7).toInt())
        : j.copyWith(saiLaps: (j.saiLaps + delta).clamp(0, 7).toInt());
  });

  Widget _counter(bool tawaf) {
    final count = tawaf ? store.journey.tawafLaps : store.journey.saiLaps;
    return WatchPanel(glow: true, child: Column(children: [
      Text(tawaf ? 'عدّاد أشواط الطواف' : 'عدّاد أشواط السعي',
        style: RW.style(16, weight: FontWeight.w800)),
      Text('$count / 7', style: RW.style(38, color: RW.gold, weight: FontWeight.w900)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton.filledTonal(onPressed: count == 0 ? null : () => _laps(tawaf, -1),
          icon: const Icon(Icons.remove)),
        Text('تسجيل يدوي فقط', style: RW.style(11, color: RW.muted)),
        IconButton.filled(onPressed: count == 7 ? null : () => _laps(tawaf, 1),
          icon: const Icon(Icons.add), style: IconButton.styleFrom(
            backgroundColor: RW.gold, foregroundColor: RW.black)),
      ]),
      Text('لا يعتمد على GPS ولا يثبت إتمام النسك الحقيقي.',
        style: RW.style(10, color: RW.muted), textAlign: TextAlign.center),
    ]));
  }

  @override Widget build(BuildContext context) {
    final j = store.journey;
    final umrah = j.type == 'umrah';
    final stages = umrah ? _umrah : _hajj;
    final selected = (inspecting ?? j.step).clamp(0, stages.length - 1).toInt();
    final current = stages[selected];
    return WatchGradientScaffold(topPhoto: true, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('مراحل ${umrah ? 'العمرة' : 'الحج'}',
          style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.route_rounded, color: RW.gold, size: 29),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 17), children: [
        const SizedBox(height: 15),
        WatchPanel(glow: true, child: Column(children: [
          SegmentedButton<String>(segments: const [
            ButtonSegment(value: 'umrah', label: Text('العمرة'), icon: Icon(Icons.mosque)),
            ButtonSegment(value: 'hajj', label: Text('الحج'), icon: Icon(Icons.landscape)),
          ], selected: {j.type}, onSelectionChanged: (s) => _switch(s.first),
            style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? RW.gold : RW.green),
              foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? RW.black : RW.ivory))),
          const SizedBox(height: 13),
          LinearProgressIndicator(value: j.step / stages.length,
            backgroundColor: Colors.white12, color: RW.gold, minHeight: 8,
            borderRadius: BorderRadius.circular(5)),
          const SizedBox(height: 8),
          Text('${j.step} من ${stages.length} خطوات للمراجعة التعليمية',
            style: RW.style(12, color: RW.muted)),
        ])),
        const SizedBox(height: 18),
        WatchSectionTitle('رحلتك خطوة بخطوة'),
        const SizedBox(height: 10),
        for (var i=0; i<stages.length; i++) ...[
          Material(color: selected == i ? RW.green2 : RW.black.withOpacity( .7),
            borderRadius: BorderRadius.circular(18), child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => inspecting = i),
              child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: i < j.step ? RW.jade : RW.gold,
                  child: i < j.step ? const Icon(Icons.check, color: RW.black, size: 20)
                      : Text('${i+1}', style: RW.style(13, color: RW.black, weight: FontWeight.w900))),
                const SizedBox(width: 10),
                Icon(stages[i].icon, color: RW.gold), const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stages[i].name, style: RW.style(14, weight: FontWeight.w800)),
                  Text(stages[i].summary, style: RW.style(10, color: RW.muted)),
                ])),
                Icon(selected == i ? Icons.keyboard_arrow_down : Icons.chevron_left,
                  color: RW.gold),
              ])))),
          const SizedBox(height: 7),
        ],
        const SizedBox(height: 18),
        WatchPanel(glow: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(current.name, style: RW.style(20, weight: FontWeight.w900, color: RW.gold)),
          const SizedBox(height: 9),
          Text(current.guidance, style: RW.style(13)),
          const SizedBox(height: 13),
          if (umrah && selected == 3) _counter(true),
          if (umrah && selected == 6) _counter(false),
          const SizedBox(height: 12),
          WatchPrimaryButton(
            label: selected < j.step ? 'هذه الخطوة مسجلة' :
               selected == j.step ? 'سجّلي إتمام مراجعة الخطوة' : 'اختاري الخطوة الحالية أولًا',
            icon: Icons.check_circle, onTap: () => _complete(selected, stages),
          ),
        ])),
        const SizedBox(height: 14),
        Text('هذه قائمة تعلم وتذكير؛ لا تُعد إثباتًا لأداء العمرة أو الحج فعليًا. المرجع الشرعي الرسمي مقدّم عند الاختلاف.',
          textAlign: TextAlign.center, style: RW.style(11, color: RW.muted)),
        const SizedBox(height: 30),
      ])),
    ]));
  }
}
