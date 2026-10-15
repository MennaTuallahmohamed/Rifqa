import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_data.dart';
import 'rawdah_data.dart';

/// واجهة الإشعارات: التطبيق يعمل بدونها (مؤقّت داخلي فقط).
/// لتفعيل إشعارات الهاتف الحقيقية أضف الحزم الموضحة في
/// optional/rawdah_notify_impl.dart ثم استدعِ في main():
///   RawdahNotifier.I = LocalRawdahNotifier();
abstract class RawdahNotifier {
  static RawdahNotifier I = const _NoopNotifier();

  /// هل التنفيذ الحقيقي مفعّل؟
  bool get supported;

  /// يجدول إشعارًا قبل كل محاولة بـ [leadMinutes] دقيقة وإشعارًا عند وقتها.
  Future<bool> schedule(List<RAttempt> items, {int leadMinutes = 10});

  Future<void> cancelAll();
}

class _NoopNotifier implements RawdahNotifier {
  const _NoopNotifier();
  @override
  bool get supported => false;
  @override
  Future<bool> schedule(List<RAttempt> items, {int leadMinutes = 10}) async => false;
  @override
  Future<void> cancelAll() async {}
}

/// «ذكّرني»: يختار المستخدم يوم الزيارة والنوع، فيُنشأ جدول محاولات بتوقيته المحلي.
class RawdahPlannerPage extends StatefulWidget {
  const RawdahPlannerPage({super.key});
  @override
  State<RawdahPlannerPage> createState() => _PlannerState();
}

class _PlannerState extends State<RawdahPlannerPage> {
  final store = RawdahStore.I;
  late bool woman = store.woman;
  late DateTime? day;
  int lead = 10;

  @override
  void initState() {
    super.initState();
    day = store.visitDay;
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: day ?? now.add(const Duration(days: 10)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'اختر يوم زيارة الروضة',
    );
    if (d != null) {
      setState(() => day = d);
      store.setPlan(d, woman);
    }
  }

  String _localLabel(DateTime l) {
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    return '${l.day}/${l.month}  $h:${l.minute.toString().padLeft(2, '0')} ${l.hour >= 12 ? 'م' : 'ص'}';
  }

  Future<void> _remind(List<RAttempt> plan) async {
    final n = RawdahNotifier.I;
    if (!n.supported) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('إشعارات الهاتف غير مفعّلة بعد'),
          content: const Text(
            'جدول المحاولات جاهز. لتصلك إشعارات حقيقية حتى والتطبيق مغلق، فعّل الملف الاختياري rawdah_notify_impl.dart بحسب التعليمات داخله.\n\nفي الأثناء انسخ الجدول وضعه في منبّه هاتفك.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا')),
          ],
        ),
      );
      return;
    }
    final ok = await n.schedule(plan, leadMinutes: lead);
    store.setReminders(ok);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'تم ضبط التذكيرات ✅' : 'تعذّر ضبط التذكيرات، تحقق من إذن الإشعارات')));
  }

  String _asText(List<RAttempt> plan) {
    final b = StringBuffer('جدول محاولات حجز الروضة\n');
    for (final a in plan) {
      b.writeln(
          '• ${a.title}: ${dateAr(a.wall)} ${hm12(a.wall)} (توقيت السعودية) = ${_localLabel(a.local)} بتوقيتك');
    }
    b.writeln('تنبيه: الأوقات إرشادية وقد تتغير بحسب تحديثات نسك.');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final plan = day == null ? <RAttempt>[] : buildAttempts(day!, woman);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('ذكّرني بحجز الروضة'),
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('١. من سيزور؟',
              style: TextStyle(color: UC.ink, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final w in const [false, true])
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => woman = w);
                      if (day != null) store.setPlan(day!, w);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: woman == w ? AppColors.greenDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: woman == w ? AppColors.gold : UC.border),
                      ),
                      child: Text(w ? '🧕 سيدات (5:44 م)' : '🧔 رجال (5:40 م)',
                          style: TextStyle(
                              color: woman == w ? Colors.white : UC.ink,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('٢. يوم الزيارة المطلوب',
              style: TextStyle(color: UC.ink, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: UC.border)),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: AppColors.greenDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      day == null ? 'اضغط لاختيار اليوم' : dateAr(saudiDay(day!)),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: UC.ink),
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('٣. التذكير قبل المحاولة بـ ',
                  style: TextStyle(color: UC.ink, fontWeight: FontWeight.w900, fontSize: 15)),
              DropdownButton<int>(
                value: lead,
                items: [for (final m in const [5, 10, 15, 30]) DropdownMenuItem(value: m, child: Text('$m دقيقة'))],
                onChanged: (v) => setState(() => lead = v ?? 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.softGold, borderRadius: BorderRadius.circular(16)),
              child: const Text(
                  'اختر يوم الزيارة لأعرض لك كل مواعيد المحاولة بتوقيتك المحلي وتوقيت السعودية.',
                  style: TextStyle(color: UC.ink, height: 1.6)),
            )
          else ...[
            for (final a in plan) _row(a),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _remind(plan),
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('فعّل التذكيرات'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _asText(plan)));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('تم نسخ الجدول')));
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'الأوقات من أدلة «صحبة ترانزيت» وهي إرشادية، فنظام فتح الحجز قد يتغير بحسب تحديثات نسك. لا تعتمد على ساعة ثابتة وتابع تطبيق نسك دائمًا.',
            style: TextStyle(color: UC.muted, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _row(RAttempt a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UC.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: const TextStyle(
                        color: AppColors.greenDark, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('🇸🇦 ${dateAr(a.wall)} · ${hm12(a.wall)}',
                    style: const TextStyle(color: UC.ink, fontWeight: FontWeight.w700)),
                Text('📱 بتوقيتك: ${_localLabel(a.local)}',
                    style: const TextStyle(color: UC.muted, fontSize: 12.5)),
                const SizedBox(height: 3),
                Text(a.note, style: const TextStyle(color: UC.muted, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
