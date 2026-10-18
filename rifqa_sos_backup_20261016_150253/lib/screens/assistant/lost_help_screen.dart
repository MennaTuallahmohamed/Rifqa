// lib/features/ask_rifqa/lost_help_screen.dart
//
// شاشة «أنا تائهة»: تحدد موقعك بالـ GPS (بيشتغل حتى من غير إنترنت)،
// وتديكي كل أدوات المساعدة في مكان واحد وبأزرار كبيرة.
//
// pubspec.yaml: geolocator, url_launcher, share_plus
//
// Android (AndroidManifest.xml):
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//   <queries>
//     <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
//   </queries>
//
// iOS (Info.plist):
//   NSLocationWhenInUseUsageDescription = "نحتاج موقعك لنساعدك لو كنتي تائهة"
//   LSApplicationQueriesSchemes → tel

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _cream = Color(0xFFFAF7F0);
const _ink = Color(0xFF1F2A24);
const _danger = Color(0xFFB3261E);
const _deep = Color(0xFF8C1D18);

/// بيانات تحفظها المستخدمة في ملفها الشخصي وقت التسجيل (كلها اختيارية).
class LostProfile {
  const LostProfile({
    this.name,
    this.hotelName,
    this.hotelAddress,
    this.companionName,
    this.companionPhone,
    this.groupLeaderPhone,
  });
  final String? name;
  final String? hotelName;
  final String? hotelAddress;
  final String? companionName;
  final String? companionPhone;
  final String? groupLeaderPhone;
}

/// اربطيها بمجموعات رفقة: ابعتي الموقع كرسالة في الجروب.
typedef ShareLocationCallback = Future<bool> Function(
    double lat, double lng, double accuracyMeters);

class LostHelpScreen extends StatefulWidget {
  const LostHelpScreen({
    super.key,
    this.profile = const LostProfile(),
    this.onShareToGroup,
  });

  final LostProfile profile;
  final ShareLocationCallback? onShareToGroup;

  @override
  State<LostHelpScreen> createState() => _LostHelpScreenState();
}

enum _LocState { loading, ready, serviceOff, denied, deniedForever, failed }

class _LostHelpScreenState extends State<LostHelpScreen> {
  _LocState _state = _LocState.loading;
  Position? _pos;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _locate();
  }

  // ───────────── الموقع ─────────────

  Future<void> _locate() async {
    setState(() => _state = _LocState.loading);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _state = _LocState.serviceOff);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        setState(() => _state = _LocState.denied);
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _state = _LocState.deniedForever);
        return;
      }

      Position? p;
      try {
        p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        p = await Geolocator.getLastKnownPosition();
      }
      if (!mounted) return;
      if (p == null) {
        setState(() => _state = _LocState.failed);
        return;
      }
      setState(() {
        _pos = p;
        _state = _LocState.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _state = _LocState.failed);
    }
  }

  String get _mapsLink {
    final p = _pos!;
    return 'https://maps.google.com/?q=${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';
  }

  String get _shareText {
    final name = widget.profile.name;
    final who = (name == null || name.isEmpty) ? 'أنا' : 'أنا $name';
    return '🆘 $who تائهة وأحتاج مساعدة.\nموقعي الحالي:\n$_mapsLink';
  }

  // ───────────── الأفعال ─────────────

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _call(String phone) async {
    HapticFeedback.mediumImpact();
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) _toast('تعذّر فتح الاتصال. اطلبي الرقم $phone يدويًا.');
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(body, style: const TextStyle(fontSize: 16, height: 1.6)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                minimumSize: const Size(130, 48),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  Future<void> _shareLocation() async {
    final p = _pos;
    if (p == null) return;
    final ok = await _confirm(
      'إرسال موقعك؟',
      widget.onShareToGroup != null
          ? 'هنبعت موقعك الحالي لمجموعتك في رفقة.'
          : 'هتختاري التطبيق اللي تبعتي منه موقعك (واتساب، رسائل…).',
      'ابعتي موقعي',
    );
    if (!ok) return;
    try {
      if (widget.onShareToGroup != null) {
        final sent = await widget.onShareToGroup!(p.latitude, p.longitude, p.accuracy);
        if (sent && mounted) _toast('تم إرسال موقعك للمجموعة ✓');
      } else {
        await Share.share(_shareText);
      }
    } catch (_) {
      if (mounted) {
        _toast('تعذّر الإرسال. تأكدي من الإنترنت، أو اعرضي الشاشة لأي موظف.');
      }
    }
  }

  // ───────────── الواجهة ─────────────

  @override
  Widget build(BuildContext context) {
    final pr = widget.profile;
    final canCallCompanion = (pr.companionPhone ?? '').isNotEmpty;
    final canCallLeader = (pr.groupLeaderPhone ?? '').isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _deep,
          foregroundColor: Colors.white,
          title: const Text('مساعدة التائهين',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // طمأنة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اهدي، إنتي مش لوحدك 🤍',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: _deep)),
                  SizedBox(height: 8),
                  Text(
                    'خدي نفس عميق. لو تقدري، قفي في مكان واضح بعيد عن الزحام، '
                    'واستخدمي الأزرار تحت.',
                    style: TextStyle(fontSize: 16, height: 1.75, color: _ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            _locationCard(),
            const SizedBox(height: 14),

            // الأزرار
            _BigAction(
              icon: Icons.share_location_rounded,
              label: 'ابعتي موقعي',
              sub: widget.onShareToGroup != null ? 'لمجموعتك في رفقة' : 'واتساب أو رسالة',
              color: _danger,
              enabled: _state == _LocState.ready,
              onTap: _shareLocation,
            ),
            if (canCallCompanion) ...[
              const SizedBox(height: 10),
              _BigAction(
                icon: Icons.phone_in_talk_rounded,
                label: 'اتصلي بـ${pr.companionName ?? 'المرافق'}',
                sub: pr.companionPhone!,
                color: const Color(0xFF1F6B45),
                onTap: () => _call(pr.companionPhone!),
              ),
            ],
            if (canCallLeader) ...[
              const SizedBox(height: 10),
              _BigAction(
                icon: Icons.groups_rounded,
                label: 'اتصلي بقائد الحملة',
                sub: pr.groupLeaderPhone!,
                color: const Color(0xFF1F6B45),
                onTap: () => _call(pr.groupLeaderPhone!),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SmallAction(
                    icon: Icons.local_hospital_rounded,
                    label: 'الإسعاف 997',
                    onTap: () => _call('997'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallAction(
                    icon: Icons.local_police_rounded,
                    label: 'الأمن 911',
                    onTap: () => _call('911'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _staffCard(pr),
            const SizedBox(height: 16),

            const _Tips(),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    late final Widget content;
    switch (_state) {
      case _LocState.loading:
        content = const Row(
          children: [
            SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 12),
            Expanded(
              child: Text('بحدد موقعك… خليكي في مكانك ثواني',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      case _LocState.ready:
        final p = _pos!;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.my_location_rounded, color: Color(0xFF1F6B45)),
              SizedBox(width: 8),
              Text('تم تحديد موقعك',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الدقة التقريبية: ${p.accuracy.round()} متر'
              '${p.accuracy > 60 ? ' (ضعيفة — اخرجي لمكان مكشوف لو تقدري)' : ''}',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B756F)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _mapsLink));
                    _toast('تم نسخ رابط موقعك');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('انسخي الرابط'),
                ),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(_mapsLink),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('افتحي الخريطة'),
                ),
                TextButton.icon(
                  onPressed: _locate,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('حدّثي'),
                ),
              ],
            ),
          ],
        );
      case _LocState.serviceOff:
        content = _locProblem(
          'خدمة الموقع مقفولة. افتحيها عشان نحدد مكانك.',
          'افتحي إعدادات الموقع',
          () async {
            await Geolocator.openLocationSettings();
            _locate();
          },
        );
      case _LocState.denied:
        content = _locProblem(
          'محتاجين إذن الموقع عشان نساعدك.',
          'اسمحي بالموقع',
          _locate,
        );
      case _LocState.deniedForever:
        content = _locProblem(
          'إذن الموقع مرفوض. فعّليه من إعدادات التطبيق.',
          'افتحي إعدادات التطبيق',
          () => Geolocator.openAppSettings(),
        );
      case _LocState.failed:
        content = _locProblem(
          'مقدرناش نحدد موقعك. جرّبي تقفي في مكان مكشوف، أو استخدمي بطاقة العرض تحت.',
          'جرّبي تاني',
          _locate,
        );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(.07)),
      ),
      child: content,
    );
  }

  Widget _locProblem(String text, String action, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(fontSize: 16, height: 1.7, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _danger,
            minimumSize: const Size(0, 48),
          ),
          onPressed: onTap,
          child: Text(action, style: const TextStyle(fontSize: 15.5)),
        ),
      ],
    );
  }

  /// بطاقة تتعرض لأي موظف أو متطوع أو رجل أمن (عربي + إنجليزي).
  Widget _staffCard(LostProfile pr) {
    final p = _pos;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _danger, width: 2.5),
      ),
      child: Column(
        children: [
          const Text('اعرضي هذه الشاشة لأي موظف أو رجل أمن',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B756F))),
          const SizedBox(height: 10),
          const Text('أنا تائهة وأحتاج مساعدة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _danger)),
          const SizedBox(height: 4),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('I am lost and need help',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink)),
          ),
          const SizedBox(height: 14),
          if ((pr.name ?? '').isNotEmpty) _line('الاسم', pr.name!),
          if ((pr.hotelName ?? '').isNotEmpty) _line('السكن', pr.hotelName!),
          if ((pr.hotelAddress ?? '').isNotEmpty) _line('العنوان', pr.hotelAddress!),
          if ((pr.companionPhone ?? '').isNotEmpty)
            _line('تليفون المرافق', pr.companionPhone!, ltr: true),
          if ((pr.groupLeaderPhone ?? '').isNotEmpty)
            _line('تليفون قائد الحملة', pr.groupLeaderPhone!, ltr: true),
          if (p != null)
            _line('الموقع',
                '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                ltr: true),
        ],
      ),
    );
  }

  Widget _line(String k, String v, {bool ltr = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 14.5, color: Color(0xFF6B756F), fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Directionality(
                textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(v,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                ),
              ),
            ),
          ],
        ),
      );
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(sub,
                            style: TextStyle(
                                color: Colors.white.withOpacity(.85), fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: _danger,
        side: const BorderSide(color: _danger, width: 1.6),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'ابقي في مكان واضح وآمن، ولا تمشي في اتجاه الزحام.',
      'توجّهي لأقرب رجل أمن أو متطوع أو موظف بزي رسمي.',
      'لا تذهبي مع أي شخص غير مسؤول رسمي.',
      'احتفظي بالجوال مشحونًا، وفعّلي وضع توفير الطاقة لو البطارية قليلة.',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نصائح سريعة',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_rounded,
                        size: 18, color: Color(0xFF1F6B45)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t, style: const TextStyle(fontSize: 15, height: 1.7)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}