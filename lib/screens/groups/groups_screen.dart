import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../services/groups/group_service.dart';
import 'chat_media.dart';
import 'rifqa_chat_theme.dart';
import 'friends_screen.dart';
import 'group_friend_invites_screen.dart';
import 'group_map_screen.dart';
import 'group_members_screen.dart';

// =========================================================== shared helpers
String friendlyError(Object e) {
  if (e is StateError) return e.message;
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') return 'غير مسموح لك بتنفيذ هذا الإجراء';
    if (e.code == 'unavailable') return 'لا يوجد اتصال بالإنترنت';
    return e.message ?? e.code;
  }
  return 'حدث خطأ غير متوقع';
}

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String ago(Timestamp? t) {
  if (t == null) return 'الآن';
  final diff = DateTime.now().difference(t.toDate());
  if (diff.inSeconds < 60) return 'منذ لحظات';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  return 'منذ ${diff.inHours} ساعة';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayLabel(DateTime d) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'اليوم';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'أمس';
  return '${d.day}/${d.month}/${d.year}';
}

/// وقت مختصر لقائمة المحادثات: الآن / 9:32 / أمس / 12‏/4
String listTimeLabel(Timestamp? t) {
  if (t == null) return '';
  final d = t.toDate();
  final now = DateTime.now();
  if (now.difference(d).inMinutes < 1) return 'الآن';
  if (sameDay(d, now)) return hhmm(d);
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'أمس';
  return '${d.day}/${d.month}';
}

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color surfaceOf(BuildContext c) =>
    isDark(c) ? const Color(0xFF17211D) : Colors.white;
Color lineOf(BuildContext c) =>
    isDark(c) ? const Color(0xFF26332D) : AppColors.line;
Color inkOf(BuildContext c) => isDark(c) ? Colors.white : AppColors.ink;
Color mutedOf(BuildContext c) => isDark(c) ? Colors.white60 : AppColors.muted;
Color softOf(BuildContext c, Color base, Color light) =>
    isDark(c) ? base.withValues(alpha: .18) : light;
Color scaffoldOf(BuildContext c) =>
    isDark(c) ? const Color(0xFF0F1512) : RifqaChat.ivory;

Future<void> openInMaps(Object lat, Object lng) => launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );

mixin BusyMixin<T extends StatefulWidget> on State<T> {
  bool busy = false;

  Future<void> run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await fn();
    } catch (e) {
      debugPrint('GroupError: $e');
      toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
  }
}

Future<void> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw StateError('فعّلي خدمة الموقع (GPS) من الجهاز');
  }
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
  if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
    throw StateError('اسمحي للتطبيق باستخدام الموقع من إعدادات الجهاز');
  }
}

// =============================================================== animations
class FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration base;
  const FadeSlideIn(
      {super.key,
      required this.index,
      required this.child,
      this.base = const Duration(milliseconds: 260)});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: base + Duration(milliseconds: (index.clamp(0, 10)) * 45),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: child,
    );
  }
}

class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 8});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .55 * c.value),
              blurRadius: 8 * c.value + 2,
              spreadRadius: 3 * c.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// فقاعة "جاري الكتابة" بثلاث نقاط نابضة — جاهزة للاستخدام متى ما
/// وفّر الـ backend حالة الكتابة الحيّة لكل مجموعة (غير متوفرة حاليًا).
class TypingDots extends StatefulWidget {
  final Color color;
  const TypingDots({super.key, this.color = AppColors.green});
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 16,
      child: AnimatedBuilder(
        animation: c,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = ((c.value + i * .25) % 1);
            final y = -4 * (t < .5 ? t * 2 : (1 - t) * 2);
            return Transform.translate(
              offset: Offset(0, y),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: .8)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ============================================================ small widgets
class StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const StateView(
      {super.key,
      required this.icon,
      required this.title,
      this.message,
      this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    softOf(context, AppColors.green, AppColors.softGreen),
                    softOf(context, AppColors.green, AppColors.softGreen)
                        .withValues(alpha: .6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.green),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: inkOf(context))),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.6, color: mutedOf(context))),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final IconData? icon;
  const Pill(this.text,
      {super.key, required this.color, required this.bg, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4)
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

/// شارة عدد دائرية صغيرة (مثل شارة "غير مقروء" في التصميم المرجعي).
/// هنا تُستخدم بصدق لعرض عدد الرسائل الكلي للمجموعة (أقرب بيانات حقيقية متاحة لدينا).
class CountBubble extends StatelessWidget {
  final int count;
  final Color color;
  const CountBubble(
      {super.key, required this.count, this.color = AppColors.green});
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: .4),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

/// عرض كود (دعوة/صداقة) بشكل "تذكرة" أنيق بخط متقطع، بدل صندوق عادي.
class DottedTicket extends StatelessWidget {
  final String code;
  final List<Color> colors;
  const DottedTicket(
      {super.key,
      required this.code,
      this.colors = const [AppColors.gold, Color(0xFF9A7A2E)]});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colors.first.withValues(alpha: .3),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        SelectableText(code,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                letterSpacing: 7,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter:
              _DashedLinePainter(color: Colors.white.withValues(alpha: .45)),
        ),
      ]),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const gap = 5.0;
    double x = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class GroupAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;
  const GroupAvatar(this.name, {super.key, this.size = 52, this.ring = false});

  static const _palette = [
    AppColors.green,
    Color(0xFFB08A2E),
    Color(0xFF2F6F9F),
    Color(0xFF8A5A9E),
    Color(0xFFB5651D),
  ];

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final letter = t.isEmpty ? '؟' : String.fromCharCode(t.runes.first);
    final color =
        _palette[t.runes.fold<int>(0, (a, b) => a + b) % _palette.length];
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: .72)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(size * .32),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: .35),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Text(letter,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * .45,
              fontWeight: FontWeight.w800)),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            const LinearGradient(colors: [AppColors.gold, AppColors.green]),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: scaffoldOf(context)),
        child: avatar,
      ),
    );
  }
}

/// نص/كود بسيط داخل Bottom Sheet (بديل أنيق عن AlertDialog).
class InputSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String hint;
  final String action;
  final IconData icon;
  final bool isCode;
  final int maxLength;
  final String? initialValue;
  const InputSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.action,
    required this.icon,
    this.isCode = false,
    this.maxLength = 70,
    this.initialValue,
  });
  @override
  State<InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<InputSheet> {
  late final controller =
      TextEditingController(text: widget.initialValue ?? '');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.green, AppColors.greenDark]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.green.withValues(alpha: .35),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Icon(widget.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 10),
            Text(widget.subtitle,
                style: TextStyle(height: 1.6, color: mutedOf(context))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: widget.maxLength,
              textCapitalization: widget.isCode
                  ? TextCapitalization.characters
                  : TextCapitalization.sentences,
              textAlign: widget.isCode ? TextAlign.center : TextAlign.start,
              style: widget.isCode
                  ? const TextStyle(
                      fontSize: 22,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800)
                  : null,
              decoration: InputDecoration(
                hintText: widget.hint,
                counterText: '',
                filled: true,
                fillColor: scaffoldOf(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: lineOf(context))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.green, width: 1.6)),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [AppColors.green, AppColors.greenDark]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.green.withValues(alpha: .35),
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, controller.text),
                    child: Center(
                      child: Text(widget.action,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ]),
    );
  }
}

// ============================================================ groups screen
// شاشة "الرسائل": بحث + شريط مجموعات سريع + تبويبات فلترة + قائمة محادثات
// بمعاينة آخر رسالة والوقت وعدد الرسائل — بنفس روح تصميم المرجع.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

enum _GroupFilter { all, admin }

class _GroupsScreenState extends State<GroupsScreen>
    with BusyMixin<GroupsScreen> {
  final service = GroupService.instance;
  final _search = TextEditingController();
  String _query = '';
  _GroupFilter _filter = _GroupFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<String?> askSheet({
    required String title,
    required String subtitle,
    required String hint,
    required String action,
    required IconData icon,
    bool isCode = false,
    int maxLength = 70,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => InputSheet(
          title: title,
          subtitle: subtitle,
          hint: hint,
          action: action,
          icon: icon,
          isCode: isCode,
          maxLength: maxLength,
        ),
      );

  Future<void> createGroup() => run(() async {
        final name = await askSheet(
          title: 'مجموعة جديدة',
          subtitle:
              'اختر اسمًا يعرفه أفراد الفوج أو العائلة. ستكون مشرف المجموعة.',
          hint: 'مثال: فوج عمرة رمضان',
          action: 'إنشاء المجموعة',
          icon: Icons.group_add_outlined,
        );
        if (name == null || name.trim().isEmpty) return;
        final newGroupId = await service.createGroup(name);
        toast('تم إنشاء المجموعة وأنتِ مشرفها الأساسي');
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => GroupInviteFriendScreen(
            groupId: newGroupId,
            groupName: name.trim(),
          ),
        ));
      });

  Future<void> joinGroup() => run(() async {
        final code = await askSheet(
          title: 'الانضمام بكود دعوة',
          subtitle:
              'اطلب الكود من مشرف المجموعة. بعد الإرسال ينتظر طلبك موافقته.',
          hint: 'كود الدعوة',
          action: 'إرسال الطلب',
          icon: Icons.key_outlined,
          isCode: true,
          maxLength: 16,
        );
        if (code == null || code.trim().isEmpty) return;
        await service.requestJoin(code);
        toast('اترسل الطلب، مستني موافقة المشرف');
      });

  void _openComposeMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: softOf(ctx, AppColors.green, AppColors.softGreen),
                  borderRadius: BorderRadius.circular(14)),
              child:
                  const Icon(Icons.group_add_outlined, color: AppColors.green),
            ),
            title: const Text('إنشاء مجموعة',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('لفوجك أو عائلتك، وتكون مشرفها'),
            onTap: () {
              Navigator.pop(ctx);
              createGroup();
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: softOf(ctx, AppColors.gold, AppColors.softGold),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.key_outlined, color: Color(0xFF8A6B1E)),
            ),
            title: const Text('الانضمام بكود دعوة',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('اطلبيه من مشرف المجموعة'),
            onTap: () {
              Navigator.pop(ctx);
              joinGroup();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _topBar() => Container(
        height: 153 + MediaQuery.paddingOf(context).top,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: RifqaChat.deep),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/rifqa_group_cover.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: RifqaChat.deep)),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                Color(0xFA053B31),
                Color(0xEF053B31),
                Color(0x44053B31)
              ],
                      stops: [
                0,
                .57,
                1
              ]))),
          Padding(
              padding: EdgeInsets.fromLTRB(
                  17, MediaQuery.paddingOf(context).top + 12, 17, 9),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('المحادثات',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900)),
                            Text('خليك قريب من رفاق رحلتك',
                                style: TextStyle(
                                    color: Color(0xFFEBDAB7), fontSize: 12)),
                          ])),
                      IconButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FriendsScreen())),
                          icon: const Icon(Icons.person_add_alt_1_rounded,
                              color: RifqaChat.gold),
                          tooltip: 'الأصدقاء'),
                      IconButton(
                           onPressed: () => Navigator.push(
                               context,
                               MaterialPageRoute(
                                   builder: (_) => const GroupFriendInvitesScreen())),
                           icon: const Icon(Icons.mail_outline_rounded,
                               color: RifqaChat.gold),
                           tooltip: 'دعوات الجروبات'),
                      IconButton(
                          onPressed: _openComposeMenu,
                          icon: const Icon(Icons.add_circle_rounded,
                              color: RifqaChat.gold, size: 28),
                          tooltip: 'مجموعة جديدة'),
                    ]),
                    const Spacer(),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                          color: const Color(0xEFFFFCF7),
                          borderRadius: BorderRadius.circular(17)),
                      child: TextField(
                          controller: _search,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (v) => setState(() => _query = v.trim()),
                          decoration: InputDecoration(
                              hintText: 'ابحثي في مجموعاتك...',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: RifqaChat.muted),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: RifqaChat.deep),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      }),
                              border: InputBorder.none,
                              isDense: true)),
                    ),
                  ])),
        ]),
      );

  Widget _welcomeBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
        child: Column(children: [
          const RifqaCinematicBanner(
              height: 133,
              title: 'معًا في رحلة مباركة',
              subtitle: 'تواصلي مع رفاق رحلتك وشاركي اللحظات الجميلة'),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(
                child: SizedBox(
                    height: 43,
                    child: FilledButton.icon(
                        onPressed: createGroup,
                        style: FilledButton.styleFrom(
                            backgroundColor: RifqaChat.deep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        icon: const Icon(Icons.group_add_rounded, size: 17),
                        label: const Text('إنشاء مجموعة',
                            style: TextStyle(fontSize: 12))))),
            const SizedBox(width: 8),
            Expanded(
                child: SizedBox(
                    height: 43,
                    child: OutlinedButton.icon(
                        onPressed: joinGroup,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: RifqaChat.deep,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            side: const BorderSide(color: RifqaChat.gold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('انضمام برمز',
                            style: TextStyle(fontSize: 12))))),
          ]),
        ]),
      );

  Widget _quickRow(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();
    final top = docs.take(8).toList();
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: top.length,
        itemBuilder: (context, i) {
          final d = top[i];
          final name = d.data()['name']?.toString() ?? 'مجموعة';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    groupId: d.id,
                    groupName: name,
                    isAdmin: List.from(d.data()['adminIds'] ?? [])
                        .contains(FirebaseAuth.instance.currentUser?.uid),
                  ),
                ),
              ),
              child: SizedBox(
                width: 62,
                child: Column(children: [
                  RifqaPhotoAvatar(
                      size: 54,
                      variant: name.runes.fold<int>(0, (a, b) => a + b) % 5),
                  const SizedBox(height: 6),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: inkOf(context))),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterTabs() {
    Widget tab(String label, _GroupFilter target) {
      final active = _filter == target;
      return Expanded(
          child: InkWell(
              onTap: () => setState(() => _filter = target),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  height: 36,
                  decoration: BoxDecoration(
                      color: active ? RifqaChat.deep : RifqaChat.cream,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(label,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : RifqaChat.deep)))));
    }

    return Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
        child: Row(children: [
          tab('الكل', _GroupFilter.all),
          const SizedBox(width: 6),
          tab('أنا مشرف', _GroupFilter.admin),
          const SizedBox(width: 6),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen())),
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: RifqaChat.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  icon: const Icon(Icons.people_alt_outlined, size: 15),
                  label:
                      const Text('الأصدقاء', style: TextStyle(fontSize: 11)))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous || !u.emailVerified) {
      return const Scaffold(
        body: StateView(
          icon: Icons.mark_email_unread_outlined,
          title: 'سجّل دخولك أولًا',
          message: 'للدخول إلى المجموعات، أنشئ حسابًا وأكّد بريدك الإلكتروني.',
        ),
      );
    }
    return Scaffold(
      backgroundColor: scaffoldOf(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.myGroups(),
        builder: (context, snap) {
          final allDocs = (snap.data?.docs ?? const [])
              .where((d) => d.id != '_schema_template')
              .toList();
          var docs = allDocs;
          if (_filter == _GroupFilter.admin) {
            docs = docs
                .where((d) =>
                    List.from(d.data()['adminIds'] ?? []).contains(u.uid))
                .toList();
          }
          if (_query.isNotEmpty) {
            docs = docs
                .where((d) => (d.data()['name']?.toString() ?? '')
                    .toLowerCase()
                    .contains(_query.toLowerCase()))
                .toList();
          }
          return Column(children: [
            _topBar(),
            _welcomeBanner(),
            _filterTabs(),
            const PendingJoins(),
            const SizedBox(height: 4),
            Expanded(
              child: Builder(builder: (context) {
                if (snap.hasError) {
                  return StateView(
                    icon: Icons.cloud_off_rounded,
                    title: 'تعذر تحميل المجموعات',
                    message: friendlyError(snap.error!),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.green));
                }
                if (allDocs.isEmpty) {
                  return const StateView(
                    icon: Icons.diversity_3_rounded,
                    title: 'لسه مفيش مجموعات',
                    message:
                        'ابدأ بإنشاء مجموعة لفوجك أو عائلتك، أو انضم بكود دعوة من المشرف.',
                  );
                }
                if (docs.isEmpty) {
                  return const StateView(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج',
                    message: 'جربي كلمة بحث مختلفة أو امسحي الفلترة.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final name = data['name']?.toString() ?? 'مجموعة';
                    final isAdmin =
                        List.from(data['adminIds'] ?? []).contains(u.uid);
                    final members = (data['memberIds'] as List?)?.length ?? 0;
                    return FadeSlideIn(
                      index: i,
                      child: _GroupListTile(
                        groupId: doc.id,
                        name: name,
                        isAdmin: isAdmin,
                        members: members,
                      ),
                    );
                  },
                );
              }),
            ),
          ]);
        },
      ),
    );
  }
}

/// صف واحد في قائمة المحادثات: أفاتار + اسم + معاينة آخر رسالة + وقت + شارة عدد.
class _GroupListTile extends StatelessWidget {
  final String groupId;
  final String name;
  final bool isAdmin;
  final int members;
  const _GroupListTile({
    required this.groupId,
    required this.name,
    required this.isAdmin,
    required this.members,
  });

  String _preview(Map<String, dynamic> m) {
    final sender = m['senderName']?.toString();
    String body;
    switch (m['type']) {
      case 'image':
        body = '📷 صورة';
        break;
      case 'voice':
        body = '🎙 رسالة صوتية';
        break;
      case 'location':
        body = '📍 موقع مشارك';
        break;
      default:
        body = (m['text'] ?? '').toString();
    }
    if (sender != null && sender.isNotEmpty) return '$sender: $body';
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: RifqaChat.paper,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: RifqaChat.border),
        boxShadow: [
          BoxShadow(
            color: isDark(context)
                ? Colors.black.withValues(alpha: .22)
                : Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(
                  groupId: groupId, groupName: name, isAdmin: isAdmin),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              RifqaPhotoAvatar(
                  size: 54,
                  variant: name.runes.fold<int>(0, (a, b) => a + b) % 5),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: GroupService.instance.messages(groupId),
                  builder: (context, msgSnap) {
                    final docs = (msgSnap.data?.docs ?? const [])
                        .where((d) => d.id != '_schema_template')
                        .toList();
                    final latest = docs.isNotEmpty ? docs.first.data() : null;
                    final count = docs.length;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: inkOf(context))),
                            ),
                            if (latest != null)
                              Text(
                                  listTimeLabel(
                                      latest['createdAt'] as Timestamp?),
                                  style: TextStyle(
                                      fontSize: 11.5, color: mutedOf(context))),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                              child: Text(
                                latest != null
                                    ? _preview(latest)
                                    : 'لا توجد رسائل بعد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: mutedOf(context),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (count > 0)
                              Text('$count رسالة',
                                  style: const TextStyle(
                                      color: RifqaChat.muted, fontSize: 10)),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            Pill('$members عضو',
                                icon: Icons.people_alt_outlined,
                                color: mutedOf(context),
                                bg: isDark(context)
                                    ? Colors.white10
                                    : RifqaChat.cream),
                            if (isAdmin)
                              Pill('مشرف',
                                  icon: Icons.shield_outlined,
                                  color: const Color(0xFF8A6B1E),
                                  bg: softOf(context, AppColors.gold,
                                      AppColors.softGold)),
                          ]),
                        ]);
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ================================================================ SOS button
class _ChatQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ChatQuickAction({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: RifqaChat.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
              height: 43,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RifqaChat.border)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: RifqaChat.deep, size: 16),
                const SizedBox(width: 3),
                Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RifqaChat.deep))),
              ]))));
}

class _SosHoldButton extends StatefulWidget {
  final VoidCallback onTriggered;
  final bool enabled;
  const _SosHoldButton({required this.onTriggered, required this.enabled});
  @override
  State<_SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<_SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          HapticFeedback.heavyImpact();
          widget.onTriggered();
          c.reset();
        }
      });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => c.forward() : null,
      onTapUp: (_) => c.reverse(),
      onTapCancel: () => c.reverse(),
      child: AnimatedBuilder(
        animation: c,
        builder: (_, __) => Container(
          height: 46,
          constraints: const BoxConstraints(minWidth: 0),
          decoration: BoxDecoration(
            color: softOf(context, AppColors.red, AppColors.softRed),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
                color:
                    AppColors.red.withValues(alpha: widget.enabled ? 1 : .4)),
            boxShadow: c.value > 0
                ? [
                    BoxShadow(
                        color: AppColors.red.withValues(alpha: .25),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor: c.value == 0 ? 0.0001 : c.value,
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(color: AppColors.red),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sos_rounded,
                      size: 20,
                      color: c.value > .45 ? Colors.white : AppColors.red),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(
                          c.value > 0 ? 'استمر...' : 'SOS · اضغطي مطولًا',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: c.value > .45
                                  ? Colors.white
                                  : AppColors.red))),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================== group chat
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with BusyMixin<GroupChatScreen> {
  final textController = TextEditingController();
  final service = GroupService.instance;
  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  StreamSubscription<Position>? _posSub;
  DateTime? _shareUntil;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    service.ensureMemberDoc(widget.groupId).catchError((_) {});
  }

  @override
  void dispose() {
    textController.dispose();
    _posSub?.cancel();
    if (_shareUntil != null) {
      service.stopSharing(widget.groupId).catchError((_) {});
    }
    super.dispose();
  }

  Future<bool> confirm(String title, String body, {String ok = 'موافق'}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ok)),
        ],
      ),
    );
    return r == true;
  }

  // ---- static location / SOS
  Future<void> shareLocation(
      {bool emergency = false, bool skipConfirm = false}) async {
    await run(() async {
      if (!skipConfirm) {
        final ok = await confirm('مشاركة موقعك؟',
            'سيتم إرسال موقع ثابت مرة واحدة للمجموعة، وليس تتبعًا مباشرًا.');
        if (!ok) return;
      }
      await ensureLocationPermission();
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await service.sendLocation(widget.groupId, p.latitude, p.longitude,
          emergency: emergency);
      toast(emergency
          ? 'تم إرسال استغاثتك للمجموعة. وإن كان الخطر حقيقيًا فاتصل بالجهات الرسمية.'
          : 'تم إرسال الموقع');
    });
  }

  // ---- live sharing
  Future<Duration?> pickDuration() => showModalBottomSheet<Duration>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          Widget tile(String label, String sub, Duration d) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: softOf(ctx, AppColors.green, AppColors.softGreen),
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      const Icon(Icons.timer_outlined, color: AppColors.green),
                ),
                title: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(sub),
                onTap: () => Navigator.pop(ctx, d),
              );
          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('مدة مشاركة موقعك مباشرة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              tile('15 دقيقة', 'مناسبة للتجمّع السريع',
                  const Duration(minutes: 15)),
              tile('ساعة', 'للتنقل أو الطواف', const Duration(hours: 1)),
              tile('8 ساعات', 'يوم كامل، ويمكنك الإيقاف في أي وقت',
                  const Duration(hours: 8)),
              const SizedBox(height: 8),
            ]),
          );
        },
      );

  Future<void> startLiveShare() async {
    final d = await pickDuration();
    if (d == null) return;
    await run(() async {
      await ensureLocationPermission();
      final expires = DateTime.now().toUtc().add(d);
      final first = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await service.publishLocation(
          widget.groupId, first.latitude, first.longitude, expires);
      _lastSent = DateTime.now();
      await _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 30),
      ).listen((p) async {
        if (DateTime.now().toUtc().isAfter(expires)) {
          await stopLiveShare();
          return;
        }
        if (DateTime.now().difference(_lastSent) < const Duration(seconds: 30))
          return;
        _lastSent = DateTime.now();
        try {
          await service.publishLocation(
              widget.groupId, p.latitude, p.longitude, expires);
        } catch (_) {}
      }, onError: (_) {});
      if (mounted) setState(() => _shareUntil = expires);
      toast('بدأت المشاركة، وتتوقف عند الخروج من هذه الشاشة.');
    });
  }

  Future<void> stopLiveShare() async {
    await _posSub?.cancel();
    _posSub = null;
    try {
      await service.stopSharing(widget.groupId);
    } catch (_) {}
    if (mounted) setState(() => _shareUntil = null);
  }

  // ---- invite / requests / announcements (admin)
  Future<void> invite() async {
    await run(() async {
      final code = await service.createInvite(widget.groupId);
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.gold, Color(0xFF9A7A2E)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: .35),
                        blurRadius: 14,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              Text('كود دعوة ${widget.groupName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 14, color: mutedOf(ctx)),
                const SizedBox(width: 4),
                Text('صالح 24 ساعة · تم نسخه تلقائيًا',
                    style: TextStyle(color: mutedOf(ctx), fontSize: 12.5)),
              ]),
              const SizedBox(height: 20),
              DottedTicket(code: code),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(
                              color: AppColors.green, width: 1.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        toast('تم نسخ الكود');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 19),
                      label: const Text('نسخ'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                            colors: [AppColors.green, AppColors.greenDark]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.green.withValues(alpha: .32),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Share.share(
                                'انضم لمجموعتنا "${widget.groupName}" في رفقتي 🕋\nكود الدعوة: $code');
                            Navigator.pop(ctx);
                          },
                          child: const Center(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.ios_share_rounded,
                                      color: Colors.white, size: 19),
                                  SizedBox(width: 8),
                                  Text('مشاركة',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      );
    });
  }

  void showRequests() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .6,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('طلبات الانضمام',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.pendingRequests(widget.groupId),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return StateView(
                        icon: Icons.error_outline,
                        title: 'تعذر التحميل',
                        message: friendlyError(snap.error!));
                  }
                  if (!snap.hasData) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.green));
                  }
                  if (snap.data!.docs.isEmpty) {
                    return const StateView(
                        icon: Icons.inbox_outlined,
                        title: 'لا توجد طلبات معلقة');
                  }
                  return ListView(
                    children: snap.data!.docs.map((d) {
                      final name = d.data()['userName']?.toString() ?? d.id;
                      return ListTile(
                        leading: GroupAvatar(name, size: 42),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('يطلب الانضمام'),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: 'رفض',
                            color: AppColors.red,
                            onPressed: () =>
                                run(() => service.reject(widget.groupId, d.id)),
                            icon: const Icon(Icons.close_rounded),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.green),
                            onPressed: () => run(
                                () => service.approve(widget.groupId, d.id)),
                            child: const Text('قبول'),
                          ),
                        ]),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> postAnnouncement() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const InputSheet(
        title: 'إعلان رسمي',
        subtitle: 'يظهر مثبّتًا أعلى المحادثة لكل أعضاء المجموعة.',
        hint: 'مثال: التجمع الساعة 5 عند بوابة 1',
        action: 'نشر الإعلان',
        icon: Icons.campaign_outlined,
        maxLength: 500,
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    await run(() => service.postAnnouncement(widget.groupId, text));
  }

  // ---- banners
  Widget banner({
    required Color bg,
    required Color border,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
                color: border.withValues(alpha: .12),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget alertsBanner() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.alerts(widget.groupId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final open =
            snap.data!.docs.where((d) => d.data()['status'] == 'open').toList();
        if (open.isEmpty) return const SizedBox.shrink();
        return Column(
          children: open.map((d) {
            final a = d.data();
            final canResolve = widget.isAdmin || a['senderId'] == myUid;
            return banner(
              bg: softOf(context, AppColors.red, AppColors.softRed),
              border: AppColors.red,
              child: Column(children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: AppColors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.sos_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const PulseDot(color: AppColors.red, size: 7),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                  '${a['senderName'] ?? 'عضو'} يطلب المساعدة',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: inkOf(context))),
                            ),
                          ]),
                          Text(ago(a['createdAt'] as Timestamp?),
                              style: TextStyle(
                                  fontSize: 12, color: mutedOf(context))),
                        ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red)),
                      onPressed: () => openInMaps(a['lat'] ?? 0, a['lng'] ?? 0),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('افتح الموقع'),
                    ),
                  ),
                  if (canResolve) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green),
                        onPressed: busy
                            ? null
                            : () => run(() =>
                                service.resolveAlert(widget.groupId, d.id)),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('تمت المساعدة'),
                      ),
                    ),
                  ],
                ]),
              ]),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> editAnnouncement(String id, String currentText) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InputSheet(
        title: 'تعديل الإعلان',
        subtitle: 'عدّلي نص الإعلان المثبّت لكل أعضاء المجموعة.',
        hint: 'مثال: التجمع الساعة 5 عند بوابة 1',
        action: 'حفظ التعديل',
        icon: Icons.edit_outlined,
        maxLength: 500,
        initialValue: currentText,
      ),
    );
    if (text == null ||
        text.trim().isEmpty ||
        text.trim() == currentText.trim()) return;
    await run(() async {
      await service.deleteAnnouncement(widget.groupId, id);
      await service.postAnnouncement(widget.groupId, text);
    });
  }

  Widget announcementBanner() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.announcements(widget.groupId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const SizedBox.shrink();
        final d = snap.data!.docs.first;
        return PinnedAnnouncement(
          key: ValueKey(d.id),
          id: d.id,
          data: d.data(),
          isAdmin: widget.isAdmin,
          myUid: myUid,
          onDelete: busy
              ? null
              : () =>
                  run(() => service.deleteAnnouncement(widget.groupId, d.id)),
          onEdit: busy
              ? null
              : () =>
                  editAnnouncement(d.id, d.data()['text']?.toString() ?? ''),
        );
      },
    );
  }

  Widget sharingBar() {
    final until = _shareUntil;
    if (until == null) return const SizedBox.shrink();
    return banner(
      bg: softOf(context, AppColors.green, AppColors.softGreen),
      border: AppColors.green,
      child: Row(children: [
        const PulseDot(color: AppColors.green, size: 9),
        const SizedBox(width: 10),
        const Icon(Icons.share_location_rounded, color: AppColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text('موقعك مشارك حتى ${hhmm(until.toLocal())}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: inkOf(context))),
        ),
        TextButton(
          onPressed: stopLiveShare,
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('إيقاف'),
        ),
      ]),
    );
  }

  // ---- messages
  Widget dateChip(DateTime d) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: RifqaChat.cream, borderRadius: BorderRadius.circular(14)),
          child: Text(dayLabel(d),
              style: TextStyle(fontSize: 12, color: mutedOf(context))),
        ),
      );

  Widget bubble({
    required Map<String, dynamic> m,
    required bool mine,
    required bool showName,
  }) {
    final isLocation = m['type'] == 'location';
    final t = (m['createdAt'] as Timestamp?)?.toDate();
    final fg = mine ? Colors.white : inkOf(context);
    final sub = mine ? Colors.white70 : mutedOf(context);

    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(mine ? 4 : 18),
      bottomEnd: Radius.circular(mine ? 18 : 4),
    );

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? RifqaChat.emerald : RifqaChat.paper,
          borderRadius: radius,
          border: mine ? null : Border.all(color: lineOf(context)),
          boxShadow: [
            BoxShadow(
              color: (mine ? AppColors.green : Colors.black)
                  .withValues(alpha: mine ? .22 : .05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!mine && showName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(m['senderName']?.toString() ?? 'عضو',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold)),
                ),
              if (isLocation) ...[
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded,
                      color: mine ? Colors.white : AppColors.red, size: 20),
                  const SizedBox(width: 6),
                  Text('موقع مشارك',
                      style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
                ]),
                const SizedBox(height: 4),
                Text('${m['lat']}, ${m['lng']}',
                    style: TextStyle(fontSize: 12, color: sub)),
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _MiniButton(
                    label: 'فتح',
                    icon: Icons.map_outlined,
                    light: mine,
                    onTap: () => openInMaps(m['lat'] ?? 0, m['lng'] ?? 0),
                  ),
                  const SizedBox(width: 6),
                  _MiniButton(
                    label: 'نسخ',
                    icon: Icons.copy_rounded,
                    light: mine,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: '${m['lat']},${m['lng']}'));
                      toast('تم نسخ الإحداثيات');
                    },
                  ),
                ]),
              ] else if (m['type'] == 'image') ...[
                ImageMessage(
                    groupId: widget.groupId,
                    mediaId: m['mediaId']?.toString() ?? ''),
                if ((m['text'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(m['text'].toString(),
                        style:
                            TextStyle(fontSize: 15.5, height: 1.5, color: fg)),
                  ),
              ] else if (m['type'] == 'voice')
                VoiceMessage(
                  groupId: widget.groupId,
                  mediaId: m['mediaId']?.toString() ?? '',
                  durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
                  mine: mine,
                )
              else
                Text(m['text']?.toString() ?? '',
                    style: TextStyle(fontSize: 15.5, height: 1.5, color: fg)),
              if (t != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(hhmm(t),
                      style: TextStyle(fontSize: 10.5, color: sub)),
                ),
            ]),
      ),
    );
  }

  void messageActions(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final canDelete = m['senderId'] == myUid || widget.isAdmin;
    final text = (m['text'] ?? '').toString();
    final isLocation = m['type'] == 'location';
    if (text.isEmpty && !canDelete && !isLocation) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (text.isNotEmpty && !isLocation)
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('نسخ النص'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                toast('تم النسخ');
              },
            ),
          if (isLocation)
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('نسخ الإحداثيات'),
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: '${m['lat']},${m['lng']}'));
                Navigator.pop(ctx);
                toast('تم نسخ الإحداثيات');
              },
            ),
          if (canDelete)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red),
              title: const Text('حذف الرسالة',
                  style: TextStyle(color: AppColors.red)),
              onTap: () {
                Navigator.pop(ctx);
                run(() => service.deleteMessage(widget.groupId, doc.id,
                    mediaId: m['mediaId']?.toString()));
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget messagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.messages(widget.groupId),
      builder: (context, snap) {
        if (snap.hasError) {
          return StateView(
            icon: Icons.cloud_off_rounded,
            title: 'تعذر تحميل الرسائل',
            message: friendlyError(snap.error!),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.green));
        }
        final docs =
            snap.data!.docs.where((d) => d.id != '_schema_template').toList();
        if (docs.isEmpty) {
          return const StateView(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'ابدأ المحادثة',
            message:
                'أرسل أول رسالة لمجموعتك، أو شارك موقعك ليعرف الجميع مكانك.',
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final m = docs[i].data();
            final t = (m['createdAt'] as Timestamp?)?.toDate();
            final older = i + 1 < docs.length ? docs[i + 1].data() : null;
            final olderT = (older?['createdAt'] as Timestamp?)?.toDate();
            final showDate =
                t != null && (olderT == null || !sameDay(t, olderT));
            final showName =
                showDate || older == null || older['senderId'] != m['senderId'];
            final mine = m['senderId'] == myUid;
            return Column(children: [
              if (showDate) dateChip(t),
              Padding(
                padding: EdgeInsets.only(top: showName ? 6 : 0),
                child: GestureDetector(
                  onLongPress: () => messageActions(docs[i]),
                  child: bubble(m: m, mine: mine, showName: showName),
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget composer() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceOf(context),
        border: Border(top: BorderSide(color: lineOf(context))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 14,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 9, 8, 2),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: _SosHoldButton(
                        enabled: !busy,
                        onTriggered: () =>
                            shareLocation(emergency: true, skipConfirm: true))),
                const SizedBox(width: 5),
                Expanded(
                    flex: 2,
                    child: _ChatQuickAction(
                        icon: Icons.location_on_outlined,
                        label: 'موقعي',
                        onTap: busy ? null : () => shareLocation())),
                const SizedBox(width: 5),
                Expanded(
                    flex: 2,
                    child: _ChatQuickAction(
                        icon: Icons.share_location_rounded,
                        label: _shareUntil == null ? 'مباشر' : 'إيقاف',
                        onTap: busy
                            ? null
                            : (_shareUntil == null
                                ? startLiveShare
                                : stopLiveShare))),
              ])),
          ChatInputBar(
            controller: textController,
            busy: busy,
            onSendText: (t) => service.sendMessage(widget.groupId, t),
            onSendImage: (bytes, caption) =>
                service.sendImage(widget.groupId, bytes, caption: caption),
            onSendVoice: (bytes, ms) =>
                service.sendVoice(widget.groupId, bytes, ms),
            onError: toast,
          ),
        ]),
      ),
    );
  }

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback? onTap, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.white.withValues(alpha: .16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: RifqaChat.deep,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 8,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.group(widget.groupId),
          builder: (context, s) {
            final n = (s.data?.data()?['memberIds'] as List?)?.length;
            return Row(children: [
              RifqaPhotoAvatar(
                  size: 38,
                  variant:
                      widget.groupName.runes.fold<int>(0, (a, b) => a + b) % 5),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (n != null) ...[
                          const Icon(Icons.people_alt_outlined,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text('$n عضو',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                          const SizedBox(width: 8),
                          const Text('•',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white54)),
                          const SizedBox(width: 8),
                        ],
                      ]),
                    ]),
              ),
            ]);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'المجموعة',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'map')
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GroupMapScreen(
                            groupId: widget.groupId,
                            groupName: widget.groupName)));
              if (v == 'members')
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GroupMembersScreen(
                            groupId: widget.groupId,
                            groupName: widget.groupName)));
              if (v == 'invite') invite();
              if (v == 'invite_by_friend_code') {
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => GroupInviteFriendScreen(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                  ),
                ));
              }
              if (v == 'requests') showRequests();
              if (v == 'announce') postAnnouncement();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'map',
                  child: ListTile(
                      leading: Icon(Icons.map_outlined),
                      title: Text('خريطة المجموعة'),
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'members',
                  child: ListTile(
                      leading: Icon(Icons.people_outline_rounded),
                      title: Text('الأعضاء'),
                      contentPadding: EdgeInsets.zero)),
              if (widget.isAdmin) ...[
                const PopupMenuItem(
                    value: 'invite',
                    child: ListTile(
                        leading: Icon(Icons.link_rounded),
                        title: Text('إنشاء دعوة'),
                        contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(
                    value: 'invite_by_friend_code',
                    child: ListTile(
                        leading: Icon(Icons.person_add_alt_1_rounded),
                        title: Text('دعوة صديق بالكود'),
                        subtitle: Text('كود الصداقة: 8 خانات'),
                        contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(
                    value: 'requests',
                    child: ListTile(
                        leading: Icon(Icons.person_add_alt_1_rounded),
                        title: Text('طلبات الانضمام'),
                        contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(
                    value: 'announce',
                    child: ListTile(
                        leading: Icon(Icons.campaign_rounded),
                        title: Text('إعلان للمجموعة'),
                        contentPadding: EdgeInsets.zero)),
              ],
            ],
          ),
        ],
      ),
      body: Column(children: [
        alertsBanner(),
        announcementBanner(),
        sharingBar(),
        Expanded(child: RifqaChatBackdrop(child: messagesList())),
        composer(),
      ]),
    );
  }
}

/// إعلان مثبّت في أعلى الشات: المشرف يضيف/يعدّل/يمسح، وكل الأعضاء
/// يقدروا "يريأكتوا" عليه بإيموجي سريع.
///
/// ملاحظة مهمة: التفاعلات هنا محفوظة محليًا في الجلسة الحالية فقط
/// (عشان GroupService المرفق معايا مفيهوش دالة لحفظ تفاعلات الإعلان في
/// Firestore). لو حابة تتزامن التفاعلات بين كل أعضاء المجموعة، سهلة:
/// نضيف collection زي `groups/{id}/announcements/{aid}/reactions/{uid}`
/// ونستبدل التخزين المحلي تحت بـ StreamBuilder عليها.
class PinnedAnnouncement extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isAdmin;
  final String myUid;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  const PinnedAnnouncement({
    super.key,
    required this.id,
    required this.data,
    required this.isAdmin,
    required this.myUid,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<PinnedAnnouncement> createState() => _PinnedAnnouncementState();
}

class _PinnedAnnouncementState extends State<PinnedAnnouncement>
    with SingleTickerProviderStateMixin {
  static final Map<String, Map<String, String>> _store = {};
  static const _options = ['👍', '❤️', '🙏', '🤲'];
  late final _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));

  Map<String, String> get _reactions => _store.putIfAbsent(widget.id, () => {});

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle(String emoji) {
    setState(() {
      if (_reactions[widget.myUid] == emoji) {
        _reactions.remove(widget.myUid);
      } else {
        _reactions[widget.myUid] = emoji;
      }
    });
    _pop.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.data;
    final counts = <String, int>{};
    for (final e in _reactions.values) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final myReaction = _reactions[widget.myUid];
    final goldDark = isDark(context) ? AppColors.gold : const Color(0xFF8A6B1E);

    return FadeSlideIn(
      index: 0,
      base: const Duration(milliseconds: 220),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              softOf(context, AppColors.gold, AppColors.softGold),
              softOf(context, AppColors.gold, AppColors.softGold)
                  .withValues(alpha: .55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
                color: AppColors.gold.withValues(alpha: .14),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                  color: AppColors.gold, shape: BoxShape.circle),
              child: const Icon(Icons.push_pin_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('إعلان مثبّت',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: goldDark)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('· من ${a['senderName'] ?? 'المشرف'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, color: mutedOf(context))),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(a['text']?.toString() ?? '',
                        style: TextStyle(
                            height: 1.55,
                            fontSize: 14.5,
                            color: inkOf(context))),
                  ]),
            ),
            if (widget.isAdmin)
              PopupMenuButton<String>(
                tooltip: 'أدوات المشرف للإعلان',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz_rounded, color: mutedOf(context)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  if (v == 'edit') widget.onEdit?.call();
                  if (v == 'delete') widget.onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('تعديل'),
                          contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded,
                              color: AppColors.red),
                          title: Text('مسح الإعلان',
                              style: TextStyle(color: AppColors.red)),
                          contentPadding: EdgeInsets.zero)),
                ],
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in _options)
              _ReactionChip(
                emoji: e,
                count: counts[e] ?? 0,
                selected: myReaction == e,
                onTap: () => _toggle(e),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: .24)
              : (isDark(context) ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: selected ? AppColors.gold : lineOf(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14.5)),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Text('$count',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color:
                        selected ? const Color(0xFF8A6B1E) : mutedOf(context))),
          ],
        ]),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool light;
  final VoidCallback onTap;
  const _MiniButton(
      {required this.label,
      required this.icon,
      required this.light,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.green;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

// ===================================================== pending join requests
class PendingJoins extends StatelessWidget {
  const PendingJoins({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GroupService.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.myJoinRefs(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: docs
                .map((d) => _PendingJoinTile(
                    gid: d.id,
                    name: d.data()['groupName']?.toString() ?? 'مجموعة'))
                .toList(),
          ),
        );
      },
    );
  }
}

class _PendingJoinTile extends StatelessWidget {
  final String gid;
  final String name;
  const _PendingJoinTile({required this.gid, required this.name});

  @override
  Widget build(BuildContext context) {
    final service = GroupService.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.myRequest(gid),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final doc = snap.data!;
        final status = doc.data()?['status'];
        if (!doc.exists || status == 'approved') {
          // انتهى الطلب: ننظف السجل المحلي، وستظهر المجموعة في القائمة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            service.clearJoinRef(gid).catchError((_) {});
          });
          return const SizedBox.shrink();
        }
        final rejected = status == 'rejected';
        final color = rejected ? AppColors.red : AppColors.gold;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: softOf(context, color,
                rejected ? AppColors.softRed : AppColors.softGold),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: .5)),
          ),
          child: Row(children: [
            Icon(rejected ? Icons.block_rounded : Icons.hourglass_top_rounded,
                color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: inkOf(context))),
                    Text(
                      rejected
                          ? 'تم رفض طلب انضمامك'
                          : 'طلبك بانتظار موافقة المشرف',
                      style: TextStyle(fontSize: 12.5, color: mutedOf(context)),
                    ),
                  ]),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await service.cancelJoin(gid);
                } catch (_) {}
              },
              child: Text(rejected ? 'إخفاء' : 'إلغاء الطلب'),
            ),
          ]),
        );
      },
    );
  }
}
