import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// RIFQA — LOST HELP / SOS
// شاشة مستقلة بالكامل: لا تغيّر Firebase ولا الشات ولا الـ Home.
// IMPORTANT: This screen does NOT dispatch emergency requests to a server.
// It launches the user's dialer / share sheet / SMS composer explicitly.
// Never say an alert was sent until an actual verified delivery API exists.

const _sGreen = Color(0xFF084D3E);
const _sDeep = Color(0xFF042F29);
const _sGold = Color(0xFFE4BC70);
const _sCream = Color(0xFFFBF7EE);
const _sMint = Color(0xFFE7F2EC);
const _sInk = Color(0xFF18372E);
const _sGrey = Color(0xFF718078);
const _sRed = Color(0xFFCE2630);
const _sBorder = Color(0xFFECE5D9);

class _EmergencyNumber {
  const _EmergencyNumber(this.name, this.number, this.icon, this.description);
  final String name;
  final String number;
  final IconData icon;
  final String description;
}

const _officialNumbers = <_EmergencyNumber>[
  _EmergencyNumber('الطوارئ الموحدة', '911', Icons.emergency_rounded,
      'مركز العمليات الأمنية الموحد في المناطق التي يغطيها'),
  _EmergencyNumber('الإسعاف', '997', Icons.medical_services_rounded,
      'الحالات الطبية الطارئة'),
  _EmergencyNumber(
      'الدفاع المدني', '998', Icons.fire_truck_rounded, 'الحرائق والإنقاذ'),
  _EmergencyNumber('الشرطة', '999', Icons.local_police_rounded,
      'البلاغات والاحتياجات الأمنية'),
  _EmergencyNumber('وزارة الصحة', '937', Icons.health_and_safety_rounded,
      'الاستفسارات والخدمات الصحية'),
];

String _v(Map<String, dynamic> m, String key) => '${m[key] ?? ''}'.trim();

class _TripSOS {
  const _TripSOS(this.data);
  final Map<String, dynamic> data;
  String get hotel => _v(data, 'hotelName');
  String get room => _v(data, 'roomNumber');
  String get floor => _v(data, 'floor');
  String get building => _v(data, 'building');
  String get address => _v(data, 'hotelAddress');
  String get hotelPhone => _v(data, 'hotelPhone');
  String get guidePhone => _v(data, 'guidePhone');
  String get guideName => _v(data, 'guideName');
  String get leaderPhone => _v(data, 'groupLeaderPhone');
  String get emergencyPhone => _v(data, 'emergencyPhone');
  String get emergencyName => _v(data, 'emergencyName');
  String get embassyPhone => _v(data, 'embassyPhone');
  String get embassyName => _v(data, 'embassyName');
  bool get hasHotel => hotel.isNotEmpty || address.isNotEmpty;
  bool get hasRoom => room.isNotEmpty;
}

class _SOSContact {
  const _SOSContact(
      {required this.name, required this.phone, this.subtitle = ''});
  final String name;
  final String phone;
  final String subtitle;
}

class _SOSStorage {
  static const tripKey = 'rifqa_profile_trip_v1';
  static const contactsKey = 'rifqa_profile_contacts_v1';
  static const largeTextKey = 'rifqa_profile_large_text_v1';

  static Future<(_TripSOS, List<_SOSContact>, bool)> load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> trip = {};
    try {
      final raw = prefs.getString(tripKey);
      if (raw != null) trip = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {}
    final contacts = <_SOSContact>[];
    void add(String name, String phone, [String note = '']) {
      if (phone.isNotEmpty && !contacts.any((c) => c.phone == phone)) {
        contacts.add(_SOSContact(name: name, phone: phone, subtitle: note));
      }
    }

    final t = _TripSOS(trip);
    add('استقبال الفندق', t.hotelPhone, t.hotel);
    add('مرشد الرحلة', t.guidePhone, t.guideName);
    add('مشرف الرحلة', t.leaderPhone);
    add('شخص من العائلة', t.emergencyPhone, t.emergencyName);
    add('السفارة / القنصلية', t.embassyPhone, t.embassyName);
    try {
      final raw = prefs.getString(contactsKey);
      if (raw != null) {
        for (final e in (jsonDecode(raw) as List)) {
          final m = Map<String, dynamic>.from(e as Map);
          add(_v(m, 'title'), _v(m, 'phone'), _v(m, 'subtitle'));
        }
      }
    } catch (_) {}
    return (t, contacts, prefs.getBool(largeTextKey) ?? false);
  }

  static Future<void> saveTripFields(Map<String, String> edits) async {
    final prefs = await SharedPreferences.getInstance();
    final old = (await load()).$1.data;
    // Merge: preserve the existing profile fields that aren't edited here.
    await prefs.setString(tripKey, jsonEncode({...old, ...edits}));
  }

  static Future<void> setLargeText(bool on) async {
    await (await SharedPreferences.getInstance()).setBool(largeTextKey, on);
  }
}

void _sToast(BuildContext context, String text) {
  if (!context.mounted) return;
  final s = ScaffoldMessenger.of(context);
  s.hideCurrentSnackBar();
  s.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

Future<bool> _sLaunch(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {}
  if (context.mounted)
    _sToast(context, 'تعذّر فتح التطبيق المطلوب على هذا الجهاز.');
  return false;
}

Future<void> _sCall(BuildContext context, String number) async {
  final cleaned = number.replaceAll(RegExp(r'[^+0-9]'), '');
  if (cleaned.isEmpty) {
    _sToast(context, 'لا يوجد رقم محفوظ للاتصال.');
    return;
  }
  // Opens the dialer. It does not place an unattended call.
  await _sLaunch(context, Uri(scheme: 'tel', path: cleaned));
}

Future<void> _sSms(BuildContext context, String number, String message) async {
  final cleaned = number.replaceAll(RegExp(r'[^+0-9]'), '');
  if (cleaned.isEmpty) return;
  await _sLaunch(context,
      Uri(scheme: 'sms', path: cleaned, queryParameters: {'body': message}));
}

Future<void> _sShare(BuildContext context, String message) async {
  try {
    // Opens the native share sheet; no delivery/sending is claimed.
    await Share.share(message, subject: 'مشاركة موقعي من رِفقة');
  } catch (_) {
    if (context.mounted) _sToast(context, 'تعذّر فتح نافذة المشاركة.');
  }
}

Future<void> _sCopy(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) _sToast(context, 'تم النسخ.');
}

String _sMessage(_TripSOS trip, Position? p,
    {bool includeHotelDetails = false}) {
  final b = StringBuffer(
      'أحتاج مساعدة للوصول إلى مجموعتي أو الفندق.\nهذه رسالة جهزتها من تطبيق رِفقة.\n');
  if (p == null) {
    b.writeln('الموقع الحالي غير متاح من الهاتف.');
  } else {
    b.writeln('موقعي الحالي (وقت إنشاء الرسالة):');
    b.writeln(
        'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    b.writeln('دقة GPS التقريبية: ±${p.accuracy.round()} متر');
    b.writeln(
        'وقت القياس: ${p.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${p.timestamp.toLocal().minute.toString().padLeft(2, '0')}');
  }
  if (includeHotelDetails) {
    if (trip.hotel.isNotEmpty) b.writeln('الفندق: ${trip.hotel}');
    if (trip.building.isNotEmpty) b.writeln('المبنى: ${trip.building}');
    if (trip.floor.isNotEmpty) b.writeln('الدور: ${trip.floor}');
    if (trip.room.isNotEmpty) b.writeln('الغرفة: ${trip.room}');
  }
  return b.toString();
}

class LostHelpScreen extends StatefulWidget {
  const LostHelpScreen({super.key});

  @override
  State<LostHelpScreen> createState() => _LostHelpScreenState();
}

class _LostHelpScreenState extends State<LostHelpScreen> {
  _TripSOS _trip = const _TripSOS({});
  List<_SOSContact> _contacts = [];
  bool _loaded = false;
  bool _largeText = false;
  bool _locating = false;
  Position? _position;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final values = await _SOSStorage.load();
      if (!mounted) return;
      setState(() {
        _trip = values.$1;
        _contacts = values.$2;
        _largeText = values.$3;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _locate({bool showError = true}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationStatus = null;
      _position = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
            'خدمة تحديد الموقع مقفولة. شغّلي GPS من إعدادات الهاتف.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw StateError(
            'إذن الموقع مرفوض نهائيًا. افتحي إعدادات الهاتف لمنحه.');
      }
      if (permission == LocationPermission.denied) {
        throw StateError(
            'الموقع لم يحصل على إذن. يمكنك الاتصال بالطوارئ بدون إذن.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = p;
        _locationStatus = null;
      });
    } catch (e) {
      if (!mounted) return;
      final String message = e is StateError
          ? '${e.message}'
          : 'تعذّر تحديد موقعك الآن. جرّبي مرة أخرى أو اتصلي بالطوارئ.';
      setState(() => _locationStatus = message);
      if (showError) _sToast(context, message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _navigate(Widget child) {
    Navigator.of(context).push(MaterialPageRoute(builder: (routeContext) {
      final m = MediaQuery.of(routeContext);
      return MediaQuery(
        data: m.copyWith(
            textScaler:
                _largeText ? const TextScaler.linear(1.17) : m.textScaler),
        child: child,
      );
    })).then((_) => _reload());
  }

  void _shareLocationPage() => _navigate(_SOSLocationScreen(
        trip: _trip,
        contacts: _contacts,
        initial: _position,
        refresh: () => _locate(),
        getPosition: () => _position,
      ));

  void _contactsPage() =>
      _navigate(_SOSContactsScreen(contacts: _contacts, trip: _trip));

  void _hotelPage() =>
      _navigate(_SOSHotelScreen(trip: _trip, onEdit: _editTrip));

  void _editTrip() => _navigate(_SOSTripEditor(trip: _trip));

  Future<void> _emergencySheet() async {
    HapticFeedback.heavyImpact();
    if (_position == null && !_locating) {
      // Best-effort location only; emergency numbers remain accessible immediately.
      _locate(showError: false);
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: _sCream,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheet) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                  child: Icon(Icons.sos_rounded, size: 60, color: _sRed)),
              const SizedBox(height: 4),
              const Text('محتاج مساعدة دلوقتي؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: _sInk)),
              const SizedBox(height: 8),
              const Text(
                  'اختاري إجراء من اللي تحت. لسه ما اتبعتش استغاثة؛ الإرسال أو الاتصال بيتم من التطبيق اللي هيفتح.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _sGrey, height: 1.6, fontSize: 13)),
              const SizedBox(height: 18),
              _SosAction(
                  icon: Icons.call_rounded,
                  title: 'اتصال بالطوارئ 911',
                  subtitle: 'يفتح شاشة الاتصال فورًا',
                  background: _sRed,
                  foreground: Colors.white,
                  onTap: () {
                    Navigator.pop(sheet);
                    _sCall(context, '911');
                  }),
              const SizedBox(height: 9),
              _SosAction(
                  icon: Icons.share_location_rounded,
                  title: 'مشاركة موقعي',
                  subtitle: 'افتحي المشاركة أو جهّزي رسالة لمرافقك',
                  onTap: () {
                    Navigator.pop(sheet);
                    _shareLocationPage();
                  }),
              const SizedBox(height: 9),
              _SosAction(
                  icon: Icons.groups_rounded,
                  title: 'الاتصال بمرافق أو مشرف',
                  subtitle: 'الأرقام المحفوظة من بيانات رحلتك',
                  onTap: () {
                    Navigator.pop(sheet);
                    _contactsPage();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _easyMode() async {
    final next = !_largeText;
    setState(() => _largeText = next);
    await _SOSStorage.setLargeText(next);
    if (mounted)
      _sToast(
          context,
          next
              ? 'تم تفعيل وضع القراءة الكبيرة.'
              : 'تم إيقاف وضع القراءة الكبيرة.');
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
          textScaler:
              _largeText ? const TextScaler.linear(1.17) : mq.textScaler),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _sCream,
          body: _loaded
              ? ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _hero(mq.padding.top),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 38),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _placeCard(),
                          const SizedBox(height: 15),
                          _SosPrimaryButton(
                              label: 'مشاركة موقعي الآن',
                              icon: Icons.near_me_rounded,
                              onPressed: _shareLocationPage),
                          const SizedBox(height: 20),
                          const _SectionHeading(
                              title: 'مساعدة سريعة',
                              subtitle: 'اختاري اللي محتاجاه بضغطة واحدة'),
                          const SizedBox(height: 13),
                          GridView.count(
                            crossAxisCount: _largeText ? 2 : 3,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            mainAxisSpacing: 9,
                            crossAxisSpacing: 9,
                            childAspectRatio: _largeText ? 1.18 : .82,
                            children: [
                              _QuickTile(
                                  icon: Icons.elderly_rounded,
                                  text: 'مساعدة كبار السن',
                                  note: _largeText
                                      ? 'الخط الكبير مفعل'
                                      : 'خط أوضح وأسهل',
                                  onTap: _easyMode,
                                  iconColor: _sGold),
                              _QuickTile(
                                  icon: Icons.groups_rounded,
                                  text: 'الاتصال بالمرافق',
                                  note: 'العائلة والمشرف',
                                  onTap: _contactsPage),
                              _QuickTile(
                                  icon: Icons.hotel_rounded,
                                  text: 'العودة للفندق',
                                  note: 'غرفتك وفندقك',
                                  onTap: _hotelPage),
                              _QuickTile(
                                  icon: Icons.mosque_rounded,
                                  text: 'موقع الحرم',
                                  note: 'ابحثي في الخرائط',
                                  onTap: () => _sLaunch(
                                      context,
                                      Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('المسجد الحرام مكة')}'))),
                              _QuickTile(
                                  icon: Icons.medical_services_rounded,
                                  text: 'الإسعاف',
                                  note: '997',
                                  onTap: () => _sCall(context, '997'),
                                  iconColor: _sRed),
                              _QuickTile(
                                  icon: Icons.local_police_rounded,
                                  text: 'الطوارئ',
                                  note: 'الأرقام المهمة',
                                  onTap: _contactsPage),
                            ],
                          ),
                          const SizedBox(height: 17),
                          _statusBanner(),
                          const SizedBox(height: 17),
                          const _SectionHeading(
                              title: 'لو أنتِ تايهة',
                              subtitle: 'خطوات بسيطة لسلامتك'),
                          const SizedBox(height: 10),
                          _SosGuideStep(
                              number: '١',
                              text:
                                  'قفي في مكان آمن وواضح، وابتعدي عن الزحام.'),
                          _SosGuideStep(
                              number: '٢',
                              text:
                                  'اتصلي بمرافقك أو مشرف رحلتك، وشاركي موقعك الحالي.'),
                          _SosGuideStep(
                              number: '٣',
                              text:
                                  'اطلبي المساعدة من موظفي الأمن أو الجهات الرسمية. لو في خطر اتصلي بالطوارئ.'),
                          const SizedBox(height: 12),
                          Text(
                              'تنبيه: الاتصال وSMS ممكن يشتغلوا بدون إنترنت مع وجود تغطية شبكة. عرض الخريطة والمشاركة عبر التطبيقات غالبًا يحتاجان إنترنت.',
                              style: TextStyle(
                                  color: _sGrey,
                                  fontSize: _largeText ? 13 : 11.5,
                                  height: 1.5),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator(color: _sGreen)),
        ),
      ),
    );
  }

  Widget _hero(double statusTop) {
    return SizedBox(
      height: statusTop + 350,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusTop + 270,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(35)),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/lost_help/hero_makkah.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _sDeep)),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9052A25),
                    Color(0xB8062C25),
                    Color(0x78062F25)
                  ],
                ))),
              ]),
            ),
          ),
          Positioned(
            top: statusTop + 12,
            left: 16,
            right: 16,
            child: Row(children: [
              _RoundHeaderButton(
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => Navigator.maybePop(context)),
              const Expanded(
                  child: Column(children: [
                Text('طلب المساعدة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('لست وحدك.. رِفقة معك',
                    style: TextStyle(color: Color(0xFFF3E6C7), fontSize: 13)),
              ])),
              const _RoundHeaderButton(icon: Icons.shield_outlined),
            ]),
          ),
          Positioned(
            top: statusTop + 111,
            left: 0,
            right: 0,
            child: Center(
                child: Semantics(
              button: true,
              label: 'طلب مساعدة طارئة. اضغطي لعرض خيارات الاتصال والمشاركة.',
              child: GestureDetector(
                onTap: _emergencySheet,
                onLongPress: _emergencySheet,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFC4241), Color(0xFFB60818)]),
                    border:
                        Border.all(color: const Color(0xFFFFDBC1), width: 5),
                    boxShadow: [
                      BoxShadow(
                          color: _sRed.withValues(alpha: .38),
                          blurRadius: 27,
                          spreadRadius: 3,
                          offset: const Offset(0, 9)),
                      const BoxShadow(
                          color: Color(0x50FFFFFF),
                          blurRadius: 4,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call_rounded, color: Colors.white, size: 45),
                        SizedBox(height: 2),
                        Text('SOS',
                            style: TextStyle(
                                fontSize: 43,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.4)),
                        Text('اضغطي لطلب المساعدة',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('اتصال • مشاركة الموقع',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFFFE5DD))),
                      ]),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _placeCard() {
    final p = _position;
    return _SosSurface(
        child: Row(children: [
      Container(
          width: 53,
          height: 53,
          decoration:
              const BoxDecoration(color: _sMint, shape: BoxShape.circle),
          child:
              const Icon(Icons.location_on_rounded, color: _sGreen, size: 28)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('موقعك الحالي',
            style: TextStyle(
                color: _sInk, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 3),
        Text(
            p == null
                ? (_locationStatus ?? 'اضغطي «تحديد» للحصول على موقعك الحقيقي')
                : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _sGrey, fontSize: 12, height: 1.5)),
        if (p != null)
          Text('دقة GPS تقريبًا ±${p.accuracy.round()} متر • موقع لحظة القياس',
              style: const TextStyle(
                  color: _sGreen, fontSize: 11, fontWeight: FontWeight.w800)),
      ])),
      TextButton(
          onPressed: _locating ? null : () => _locate(),
          child: _locating
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _sGreen))
              : const Text('تحديد',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, color: _sGreen))),
    ]));
  }

  Widget _statusBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFFFEAE4),
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.sos_rounded, color: _sRed, size: 37),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                Text('الطوارئ والمساعدة',
                    style: TextStyle(
                        fontSize: 16,
                        color: _sRed,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text(
                    'التطبيق لا يرسل بلاغًا تلقائيًا. استخدمي زر SOS للاتصال أو مشاركة موقعك مع شخص تثقين به.',
                    style:
                        TextStyle(fontSize: 11.5, height: 1.5, color: _sInk)),
              ])),
        ]),
      );
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0x99043830),
        shape: const CircleBorder(),
        child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
                height: 44,
                width: 44,
                child: Icon(icon, color: Colors.white, size: 24))),
      );
}

class _SosSurface extends StatelessWidget {
  const _SosSurface(
      {required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: _sBorder),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C352716),
                  blurRadius: 15,
                  offset: Offset(0, 5))
            ]),
        child: child,
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle = ''});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _sInk)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _sGrey)),
        ],
      ]);
}

class _SosPrimaryButton extends StatelessWidget {
  const _SosPrimaryButton(
      {required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 61,
        child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: _sGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19))),
            icon: Icon(icon, size: 25),
            label: Text(label,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900))),
      );
}

class _SosAction extends StatelessWidget {
  const _SosAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.background = Colors.white,
      this.foreground = _sInk});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            color: foreground,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: foreground.withValues(alpha: .8),
                            height: 1.4)),
                  ])),
              Icon(Icons.chevron_left_rounded, color: foreground),
            ]),
          ),
        ),
      );
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(
      {required this.icon,
      required this.text,
      required this.note,
      required this.onTap,
      this.iconColor = _sGreen});
  final IconData icon;
  final String text;
  final String note;
  final VoidCallback onTap;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => _SosSurface(
        padding: EdgeInsets.zero,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: iconColor, size: 29),
                      const SizedBox(height: 7),
                      Text(text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                              color: _sInk)),
                      const SizedBox(height: 4),
                      Text(note,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: 9.5, height: 1.3, color: _sGrey)),
                    ]),
              ),
            )),
      );
}

class _SosGuideStep extends StatelessWidget {
  const _SosGuideStep({required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _SosSurface(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              CircleAvatar(
                  radius: 18,
                  backgroundColor: _sGreen,
                  child: Text(number,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: _sInk,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5))),
            ])),
      );
}

class _SOSPageHeader extends StatelessWidget {
  const _SOSPageHeader(
      {required this.title,
      required this.subtitle,
      this.madinah = false,
      this.icon = Icons.shield_outlined});
  final String title;
  final String subtitle;
  final bool madinah;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
        height: 235 + top,
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(
                    madinah
                        ? 'assets/lost_help/hero_madinah.jpg'
                        : 'assets/lost_help/hero_makkah.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _sDeep)),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Color(0xDA032B27),
                      Color(0x96032B27),
                      Color(0xD4043028)
                    ]))),
              ])),
          Positioned(
              top: top + 12,
              left: 17,
              right: 17,
              child: Row(children: [
                _RoundHeaderButton(
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.maybePop(context)),
                const Spacer(),
                Icon(icon, color: _sGold, size: 27),
              ])),
          Positioned(
              right: 22,
              left: 22,
              bottom: 25,
              child: Column(children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFF2DFBE))),
              ])),
        ]));
  }
}

// -----------------------------------------------------------------------------
// Location sharing — snapshot only. Never claims live tracking or delivery.
// -----------------------------------------------------------------------------
class _SOSLocationScreen extends StatefulWidget {
  const _SOSLocationScreen(
      {required this.trip,
      required this.contacts,
      required this.initial,
      required this.refresh,
      required this.getPosition});
  final _TripSOS trip;
  final List<_SOSContact> contacts;
  final Position? initial;
  final Future<void> Function() refresh;
  final Position? Function() getPosition;

  @override
  State<_SOSLocationScreen> createState() => _SOSLocationScreenState();
}

class _SOSLocationScreenState extends State<_SOSLocationScreen> {
  Position? _pos;
  bool _busy = false;
  bool _includeStay = false;
  String get _message =>
      _sMessage(widget.trip, _pos, includeHotelDetails: _includeStay);
  @override
  void initState() {
    super.initState();
    _pos = widget.initial;
    if (_pos == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.refresh();
    if (!mounted) return;
    setState(() {
      _pos = widget.getPosition();
      _busy = false;
    });
  }

  void _chooseSms() {
    if (widget.contacts.isEmpty) {
      _sToast(context,
          'أضيفي رقم مرافقك أو الفندق من «بيانات الرحلة» أولًا، أو استخدمي مشاركة.');
      return;
    }
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: _sCream,
        builder: (sheet) => Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('اختاري المستلم',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: _sInk)),
                      const SizedBox(height: 5),
                      const Text(
                          'هيفتح تطبيق الرسائل برسالة مجهزة. اضغطي «إرسال» من تطبيق الرسائل لإتمام الإرسال.',
                          style: TextStyle(
                              fontSize: 12, height: 1.5, color: _sGrey)),
                      const SizedBox(height: 13),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(sheet).size.height * .45),
                        child: ListView(
                            shrinkWrap: true,
                            children: widget.contacts
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 7),
                                      child: _SosSurface(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const Icon(
                                                Icons.sms_rounded,
                                                color: _sGreen),
                                            title: Text(c.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            subtitle: Text(c.phone,
                                                textDirection:
                                                    TextDirection.ltr,
                                                textAlign: TextAlign.right),
                                            trailing: const Icon(
                                                Icons.chevron_left_rounded,
                                                color: _sGreen),
                                            onTap: () {
                                              Navigator.pop(sheet);
                                              _sSms(context, c.phone, _message);
                                            },
                                          )),
                                    ))
                                .toList()),
                      ),
                    ],
                  )),
            ));
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: _sCream,
            body: ListView(padding: EdgeInsets.zero, children: [
              const _SOSPageHeader(
                  title: 'مشاركة موقعي',
                  subtitle: 'مساعدة المرافقين للوصول إليك',
                  icon: Icons.near_me_outlined),
              Padding(
                  padding: const EdgeInsets.fromLTRB(17, 20, 17, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SosSurface(
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              height: 305,
                              child: Stack(children: [
                                Positioned.fill(
                                    child: _pos == null
                                        ? const ColoredBox(
                                            color: _sMint,
                                            child: Center(
                                                child: Icon(
                                                    Icons
                                                        .location_searching_rounded,
                                                    size: 74,
                                                    color: _sGreen)))
                                        : FlutterMap(
                                            key: ValueKey(
                                                '${_pos!.latitude},${_pos!.longitude}'),
                                            options: MapOptions(
                                                initialCenter: LatLng(
                                                    _pos!.latitude,
                                                    _pos!.longitude),
                                                initialZoom: 15.5),
                                            children: [
                                              TileLayer(
                                                  urlTemplate:
                                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                  userAgentPackageName:
                                                      'com.example.rafeek'),
                                              MarkerLayer(markers: [
                                                Marker(
                                                    point: LatLng(
                                                        _pos!.latitude,
                                                        _pos!.longitude),
                                                    width: 76,
                                                    height: 76,
                                                    child: const Icon(
                                                        Icons
                                                            .location_on_rounded,
                                                        size: 54,
                                                        color: _sRed))
                                              ]),
                                            ],
                                          )),
                                Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: _sGreen,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(
                                          _pos == null
                                              ? 'الموقع غير محدد'
                                              : 'نقطة GPS الحالية',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900)),
                                    )),
                                Positioned(
                                    bottom: 10,
                                    right: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: .94),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(
                                          _pos == null
                                              ? 'يمكن الاتصال بالطوارئ حتى بدون تحديد الموقع'
                                              : 'الدقة التقريبية: ±${_pos!.accuracy.round()} متر • تحتاج صور الخريطة إنترنت',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _sInk,
                                              fontSize: 11)),
                                    )),
                              ]),
                            ),
                          )),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: _busy ? null : _refresh,
                          icon: _busy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location_rounded),
                          label: Text(_pos == null
                              ? 'تحديد موقعي الآن'
                              : 'تحديث الموقع الآن'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: _sGreen,
                              minimumSize: const Size.fromHeight(53),
                              side: const BorderSide(color: _sGreen))),
                      const SizedBox(height: 13),
                      _SosSurface(
                          child: CheckboxListTile(
                        value: _includeStay,
                        onChanged: (value) =>
                            setState(() => _includeStay = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        activeColor: _sGreen,
                        title: const Text('تضمين بيانات الفندق ورقم الغرفة',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _sInk)),
                        subtitle: const Text(
                            'اختياري — اتركيه غير محدد لو هتشاركي موقعك فقط',
                            style: TextStyle(fontSize: 11, color: _sGrey)),
                      )),
                      const SizedBox(height: 18),
                      const _SectionHeading(
                          title: 'شاركِي مع شخص تثقين به',
                          subtitle:
                              'هذه مشاركة لموقع لحظة الإرسال وليست تتبعًا مباشرًا'),
                      const SizedBox(height: 10),
                      _SosPrimaryButton(
                          label: 'افتحي مشاركة الموقع',
                          icon: Icons.share_rounded,
                          onPressed: () => _sShare(context, _message)),
                      const SizedBox(height: 10),
                      _SosAction(
                          icon: Icons.sms_rounded,
                          title: 'إرسال رسالة SMS لمرافق',
                          subtitle:
                              'اختاري رقمًا وسيُفتح تطبيق الرسائل لتأكيد الإرسال',
                          onTap: _chooseSms),
                      const SizedBox(height: 10),
                      _SosAction(
                          icon: Icons.content_copy_rounded,
                          title: 'نسخ رابط الموقع والرسالة',
                          subtitle: _pos == null
                              ? 'لا توجد إحداثيات بعد، سيتم نسخ النص فقط'
                              : 'الرابط يحتوي على موقع GPS الحالي',
                          onTap: () => _sCopy(context, _message)),
                      const SizedBox(height: 18),
                      _SosSurface(
                          child: const Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 28, color: _sGreen),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'الضغط على «مشاركة» يفتح اختيار التطبيق فقط. لم يتم إرسال بلاغ تلقائيًا، ولا يوجد بث مباشر للخلفية في هذه النسخة.',
                                style: TextStyle(
                                    color: _sInk, fontSize: 12, height: 1.6))),
                      ])),
                    ],
                  )),
            ])),
      );
}

// -----------------------------------------------------------------------------
// Hotel/room wayfinding and verified-by-user trip card
// -----------------------------------------------------------------------------
class _SOSHotelScreen extends StatelessWidget {
  const _SOSHotelScreen({required this.trip, required this.onEdit});
  final _TripSOS trip;
  final VoidCallback onEdit;

  Future<void> _searchHotel(BuildContext context) async {
    if (!trip.hasHotel) {
      onEdit();
      return;
    }
    final q = [trip.hotel, trip.address].where((s) => s.isNotEmpty).join(' ');
    await _sLaunch(
        context,
        Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}'));
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _sCream,
          body: ListView(padding: EdgeInsets.zero, children: [
            const _SOSPageHeader(
                title: 'العودة للفندق',
                subtitle: 'بيانات إقامتك في مكان واحد',
                icon: Icons.hotel_rounded),
            Padding(
                padding: const EdgeInsets.fromLTRB(17, 20, 17, 35),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SosSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Row(children: [
                              const Icon(Icons.apartment_rounded,
                                  color: _sGreen, size: 33),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      trip.hotel.isNotEmpty
                                          ? trip.hotel
                                          : 'اسم الفندق لم يُضف بعد',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          color: _sInk,
                                          fontWeight: FontWeight.w900))),
                            ]),
                            if (trip.address.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(trip.address,
                                  style: const TextStyle(
                                      fontSize: 13, color: _sGrey)),
                            ],
                            const SizedBox(height: 18),
                            Row(children: [
                              Expanded(
                                  child: _HotelDataBox(
                                      title: 'رقم الغرفة',
                                      value: trip.room.isNotEmpty
                                          ? trip.room
                                          : '—',
                                      icon: Icons.meeting_room_rounded)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _HotelDataBox(
                                      title: 'الدور',
                                      value: trip.floor.isNotEmpty
                                          ? trip.floor
                                          : '—',
                                      icon: Icons.layers_rounded)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _HotelDataBox(
                                      title: 'البرج/المبنى',
                                      value: trip.building.isNotEmpty
                                          ? trip.building
                                          : '—',
                                      icon: Icons.location_city_rounded)),
                            ]),
                          ])),
                      const SizedBox(height: 15),
                      _SosPrimaryButton(
                          label: trip.hasHotel
                              ? 'ابحثي عن الفندق على الخريطة'
                              : 'أضيفي بيانات الفندق أولًا',
                          icon: Icons.map_rounded,
                          onPressed: () => _searchHotel(context)),
                      const SizedBox(height: 9),
                      _SosAction(
                          icon: Icons.edit_note_rounded,
                          title: 'تعديل بيانات الفندق والغرفة',
                          subtitle: 'خزّني اسم الفندق والغرفة وأرقام التواصل',
                          onTap: onEdit),
                      if (trip.hotelPhone.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        _SosAction(
                            icon: Icons.call_rounded,
                            title: 'اتصلي باستقبال الفندق',
                            subtitle: trip.hotelPhone,
                            onTap: () => _sCall(context, trip.hotelPhone)),
                      ],
                      const SizedBox(height: 12),
                      _SosSurface(
                          child: const Row(children: [
                        Icon(Icons.info_rounded, color: _sGreen),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'البحث عن الفندق يفتح نتائج خرائط Google بالاسم أو العنوان الذي حفظتِه. تأكدي من اختيار الفرع الصحيح قبل بدء الاتجاهات.',
                                style: TextStyle(
                                    fontSize: 12, color: _sInk, height: 1.6))),
                      ])),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                          onPressed: () => _sCopy(context,
                              'فندقي: ${trip.hotel}\nالعنوان: ${trip.address}\nالبرج: ${trip.building}\nالدور: ${trip.floor}\nالغرفة: ${trip.room}'),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('نسخ بيانات الإقامة'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(51),
                              foregroundColor: _sGreen)),
                    ])),
          ]),
        ),
      );
}

class _HotelDataBox extends StatelessWidget {
  const _HotelDataBox(
      {required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
        decoration: BoxDecoration(
            color: _sCream, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: _sGreen, size: 24),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 10.5, color: _sGrey)),
          const SizedBox(height: 5),
          SelectableText(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: _sInk, fontWeight: FontWeight.w900)),
        ]),
      );
}

// -----------------------------------------------------------------------------
// Critical numbers + user-entered hotel / supervisor / family numbers.
// -----------------------------------------------------------------------------
class _SOSContactsScreen extends StatefulWidget {
  const _SOSContactsScreen({required this.contacts, required this.trip});
  final List<_SOSContact> contacts;
  final _TripSOS trip;
  @override
  State<_SOSContactsScreen> createState() => _SOSContactsScreenState();
}

class _SOSContactsScreenState extends State<_SOSContactsScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = _search.text.trim();
    final personal = widget.contacts
        .where((c) =>
            term.isEmpty || '${c.name} ${c.phone} ${c.subtitle}'.contains(term))
        .toList();
    final official = _officialNumbers
        .where((c) => term.isEmpty || '${c.name} ${c.number}'.contains(term))
        .toList();
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _sCream,
          body: ListView(padding: EdgeInsets.zero, children: [
            const _SOSPageHeader(
                title: 'الأرقام المهمة',
                subtitle: 'أرقام رسمية وجهات رحلتك في مكان واحد',
                icon: Icons.contact_phone_rounded),
            Padding(
                padding: const EdgeInsets.fromLTRB(17, 18, 17, 35),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SosSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'ابحثي عن جهة أو رقم...',
                                prefixIcon:
                                    Icon(Icons.search_rounded, color: _sGreen)),
                          )),
                      const SizedBox(height: 17),
                      const _SectionHeading(title: 'الطوارئ السعودية'),
                      const SizedBox(height: 12),
                      for (final n in official) ...[
                        _EmergencyPhoneCard(n: n),
                        const SizedBox(height: 9),
                      ],
                      const SizedBox(height: 11),
                      const _SectionHeading(
                          title: 'أرقامك المحفوظة',
                          subtitle:
                              'بيانات الرحلة والأرقام الشخصية الموجودة على جهازك'),
                      const SizedBox(height: 11),
                      if (personal.isEmpty)
                        _SosSurface(
                            child: const Text(
                                'مفيش أرقام محفوظة مطابقة حاليًا. أضيفي أرقام الفندق والمشرف من «حسابي» أو «بيانات الرحلة».',
                                style: TextStyle(height: 1.6, color: _sGrey)))
                      else
                        for (final c in personal) ...[
                          _SosSurface(
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                const CircleAvatar(
                                    backgroundColor: _sMint,
                                    child: Icon(Icons.person_rounded,
                                        color: _sGreen)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(c.name,
                                          style: const TextStyle(
                                              color: _sInk,
                                              fontWeight: FontWeight.w900)),
                                      Text(c.phone,
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              color: _sGrey, fontSize: 12)),
                                    ])),
                                IconButton(
                                    tooltip: 'نسخ',
                                    onPressed: () => _sCopy(context, c.phone),
                                    icon: const Icon(Icons.copy_outlined,
                                        color: _sGreen)),
                                IconButton.filled(
                                    onPressed: () => _sCall(context, c.phone),
                                    style: IconButton.styleFrom(
                                        backgroundColor: _sGreen),
                                    icon: const Icon(Icons.call_rounded)),
                              ])),
                          const SizedBox(height: 9),
                        ],
                      const SizedBox(height: 12),
                      const Text(
                          'تأكدي من تغطية شبكة الهاتف. رقم 911 متاح في المناطق التي يغطيها مركز العمليات الأمنية الموحد؛ يمكنك كذلك استخدام أرقام الجهات المختصة الأخرى.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _sGrey, fontSize: 11.5, height: 1.5)),
                    ])),
          ]),
        ));
  }
}

class _EmergencyPhoneCard extends StatelessWidget {
  const _EmergencyPhoneCard({required this.n});
  final _EmergencyNumber n;
  @override
  Widget build(BuildContext context) => _SosSurface(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFFFECE8),
            child: Icon(n.icon, color: _sRed, size: 27)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n.name,
              style: const TextStyle(
                  color: _sInk, fontWeight: FontWeight.w900, fontSize: 14)),
          Text(n.description,
              maxLines: 2,
              style:
                  const TextStyle(fontSize: 10.5, color: _sGrey, height: 1.4)),
          Text(n.number,
              style: const TextStyle(
                  fontSize: 23, color: _sRed, fontWeight: FontWeight.w900)),
        ])),
        IconButton(
            tooltip: 'نسخ الرقم',
            onPressed: () => _sCopy(context, n.number),
            icon: const Icon(Icons.content_copy_rounded, color: _sGreen)),
        IconButton.filled(
            tooltip: 'فتح الاتصال',
            onPressed: () => _sCall(context, n.number),
            style: IconButton.styleFrom(backgroundColor: _sGreen),
            icon: const Icon(Icons.call_rounded)),
      ]));
}

// -----------------------------------------------------------------------------
// Lightweight trip editor, using the same keys as Rifqa Profile.
// Does not overwrite other trip fields or Firebase data.
// -----------------------------------------------------------------------------
class _SOSTripEditor extends StatefulWidget {
  const _SOSTripEditor({required this.trip});
  final _TripSOS trip;
  @override
  State<_SOSTripEditor> createState() => _SOSTripEditorState();
}

class _SOSTripEditorState extends State<_SOSTripEditor> {
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  TextEditingController _c(String name) => _controllers.putIfAbsent(
      name, () => TextEditingController(text: _v(widget.trip.data, name)));
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String title, String hint, {bool phone = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: _c(key),
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.next,
          keyboardType: phone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
              labelText: title,
              hintText: hint,
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _sBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _sBorder))),
        ),
      );

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final edits = <String, String>{};
      for (final e in _controllers.entries) {
        edits[e.key] = e.value.text.trim();
      }
      await _SOSStorage.saveTripFields(edits);
      if (mounted) {
        _sToast(context, 'تم حفظ بيانات الرحلة على الجهاز.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _sToast(context, 'تعذّر الحفظ. جرّبي مرة أخرى.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            backgroundColor: _sCream,
            body: Column(children: [
              Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: [
                const _SOSPageHeader(
                    title: 'بيانات رحلتي',
                    subtitle: 'حتى تكون معلوماتك معك وقت الحاجة',
                    icon: Icons.edit_note_rounded),
                Padding(
                    padding: const EdgeInsets.fromLTRB(17, 20, 17, 10),
                    child: Column(children: [
                      _field('hotelName', 'اسم الفندق', 'مثال: فندق في أجياد'),
                      _field(
                          'hotelAddress', 'عنوان الفندق', 'عنوان أو معلم قريب'),
                      _field('building', 'البرج / المبنى', 'مثال: برج A'),
                      Row(children: [
                        Expanded(
                            child: _field('roomNumber', 'رقم الغرفة', '1205')),
                        const SizedBox(width: 9),
                        Expanded(child: _field('floor', 'الدور', '12')),
                      ]),
                      _field('hotelPhone', 'رقم استقبال الفندق', 'رقم الهاتف',
                          phone: true),
                      _field('guideName', 'اسم مرشد الرحلة', 'اسم المرشد'),
                      _field('guidePhone', 'رقم مرشد الرحلة', 'رقم الهاتف',
                          phone: true),
                      _field(
                          'groupLeaderPhone', 'رقم مشرف الرحلة', 'رقم الهاتف',
                          phone: true),
                      _field('emergencyName', 'اسم شخص من العائلة',
                          'اسم جهة الطوارئ'),
                      _field(
                          'emergencyPhone', 'رقم شخص من العائلة', 'رقم الهاتف',
                          phone: true),
                      const Text(
                          'هذه البيانات تُحفظ على هذا الجهاز فقط باستخدام SharedPreferences. تجنبي وضع أرقام وثائق أو تفاصيل صحية حساسة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11.5, height: 1.5, color: _sGrey)),
                      const SizedBox(height: 22),
                    ])),
              ])),
              SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(17, 8, 17, 14),
                      child: _SosPrimaryButton(
                          label:
                              _saving ? 'جارٍ الحفظ...' : 'حفظ بيانات الرحلة',
                          icon: Icons.save_rounded,
                          onPressed: _saving ? null : _save))),
            ])),
      );
}
