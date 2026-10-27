import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/profile/rifqa_profile_store.dart';
import 'rifqa_profile_ui.dart';
import 'rifqa_trip_details_screen.dart';
import 'rifqa_emergency_numbers_screen.dart';
import 'rifqa_saved_contacts_screen.dart';

/// مدخل مستقل تمامًا. في الـHome لاحقًا:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const RifqaProfileScreen()));
///
/// للربط مع أقسام أخرى: onDuas / onZiyarat / onMarkets.
class RifqaProfileScreen extends StatefulWidget {
  const RifqaProfileScreen({super.key, this.onDuas, this.onZiyarat, this.onMarkets});
  final VoidCallback? onDuas;
  final VoidCallback? onZiyarat;
  final VoidCallback? onMarkets;

  @override
  State<RifqaProfileScreen> createState() => _RifqaProfileScreenState();
}

class _RifqaProfileScreenState extends State<RifqaProfileScreen> {
  final store = RifqaProfileStore.instance;
  final _imagePicker = ImagePicker();
  @override
  void initState() { super.initState(); store.addListener(_refresh); store.load(); }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { store.removeListener(_refresh); super.dispose(); }

  User? get currentUser {
    try { return FirebaseAuth.instance.currentUser; } catch (_) { return null; }
  }

  void go(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  String get displayName {
    final local = store.personal.name.trim();
    if (local.isNotEmpty) return local;
    final firebaseName = currentUser?.displayName?.trim() ?? '';
    return firebaseName.isEmpty ? 'ضيف رِفقة' : firebaseName;
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 240000) {
        _showMessage('الصورة كبيرة؛ اختاري صورة أصغر من فضلك.');
        return;
      }

      final directory = await getApplicationSupportDirectory();
      final extension = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final safeExtension =
          RegExp(r'^[a-z0-9]{1,5}$').hasMatch(extension) ? extension : 'jpg';
      final imageFile = File(
        '${directory.path}${Platform.pathSeparator}rifqa_profile_avatar.$safeExtension',
      );
      await imageFile.writeAsBytes(bytes, flush: true);
      await store.saveProfileImagePath(imageFile.path);
      if (mounted) _showMessage('تم حفظ صورتك الشخصية على الجهاز 💚');
    } catch (error) {
      if (mounted) _showMessage('تعذّر حفظ الصورة. حاولي مرة أخرى.');
      debugPrint('Rifqa profile image save error: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _profileAvatar() {
    final localPath = store.profileImagePath;
    final photo = currentUser?.photoURL;
    return Container(
      width: 89, height: 89, padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Rp.cream,
        border: Border.all(color: Rp.gold, width: 2)),
      child: ClipOval(
        child: localPath.isNotEmpty
            ? Image.file(
                File(localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarPlaceholder(),
              )
            : photo != null && photo.isNotEmpty
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() => const ColoredBox(
        color: Rp.mint,
        child: Icon(Icons.person_rounded, size: 49, color: Rp.green),
      );

  Widget _hero(BuildContext context) => Container(
    height: 335, decoration: const BoxDecoration(borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(39), bottomRight: Radius.circular(39))),
    clipBehavior: Clip.antiAlias,
    child: Stack(fit: StackFit.expand, children: [
      Image.asset('assets/rifqa_profile/makkah.jpg', fit: BoxFit.cover),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xE004382D), Color(0x87073C33), Color(0xF0033A2D)],
      ))),
      SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(19, 9, 19, 18),
        child: Column(children: [
          Row(children: [
            IconButton.filledTonal(
              onPressed: Navigator.of(context).canPop() ? () => Navigator.pop(context) : null,
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .18), foregroundColor: Colors.white),
              icon: const Icon(Icons.arrow_forward_rounded)),
            const Spacer(),
            Text('حسابي', style: Rp.style(23, color: Colors.white, weight: FontWeight.w900)),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: () => go(const RifqaAccountSettingsScreen()),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .18), foregroundColor: Colors.white),
              icon: const Icon(Icons.settings_outlined)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _profileAvatar(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: Rp.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Rp.deep, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(displayName, style: Rp.style(20, color: Colors.white, weight: FontWeight.w900),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(currentUser?.email?.isNotEmpty == true ? currentUser!.email! : 'رحلتك الإيمانية في مكان واحد',
            style: Rp.style(11.5, color: const Color(0xFFE6E5D9)), maxLines: 1),
          const SizedBox(height: 11),
          OutlinedButton.icon(
            onPressed: () => go(const RifqaEditPersonalScreen()),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: Text('تعديل بياناتي', style: Rp.style(12, color: Colors.white, weight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Rp.gold),
              backgroundColor: Rp.deep.withValues(alpha: .74),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
          ),
        ]))),
    ]),
  );

  Widget _tripCard() {
    final t = store.trip;
    return RpCard(padding: EdgeInsets.zero, child: Column(children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
        child: Container(height: 86, decoration: const BoxDecoration(color: Rp.mint),
          child: Stack(children: [
            Positioned(left: 0, top: -8, bottom: -35, width: 150,
              child: Opacity(opacity: .3, child: Image.asset('assets/rifqa_profile/madinah.jpg', fit: BoxFit.cover))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              const Icon(Icons.mosque_rounded, color: Rp.green, size: 32), const SizedBox(width: 10),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('رحلتي مع رِفقة', style: Rp.style(17, weight: FontWeight.w900)),
                  Text(t.tripName.isNotEmpty ? t.tripName : 'كل معلومات إقامتك في مكان واحد',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Rp.style(10.5, color: Rp.muted)),
                ])),
              const Icon(Icons.hotel_outlined, color: Rp.gold, size: 32),
            ])),
          ]))),
      Padding(padding: const EdgeInsets.all(15), child: Column(children: [
        Row(children: [
          Expanded(child: _infoTile(icon: Icons.apartment_rounded, label: 'الفندق الأساسي',
            value: t.hotelName.isEmpty ? 'أضيفي فندقك' : t.hotelName)),
          const SizedBox(width: 8),
          Expanded(child: _infoTile(icon: Icons.meeting_room_outlined, label: 'الغرفة',
            value: t.roomNumber.isEmpty ? 'لم تُحدّد بعد' : t.roomNumber)),
          const SizedBox(width: 8),
          Expanded(child: _infoTile(icon: Icons.layers_outlined, label: 'الدور',
            value: t.floor.isEmpty ? '—' : t.floor)),
        ]),
        if (t.hotelAddress.trim().isNotEmpty ||
            t.madinahHotelName.trim().isNotEmpty ||
            t.madinahHotelAddress.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Rp.cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.hotelAddress.trim().isNotEmpty)
                  _hotelDetail('عنوان الفندق الأساسي', t.hotelAddress),
                if (t.madinahHotelName.trim().isNotEmpty)
                  _hotelDetail('فندق المدينة', t.madinahHotelName),
                if (t.madinahHotelAddress.trim().isNotEmpty)
                  _hotelDetail('عنوان فندق المدينة', t.madinahHotelAddress),
              ],
            ),
          ),
        ],
        const SizedBox(height: 13),
        RpPrimaryButton(label: t.hasTrip ? 'عرض وتعديل تفاصيل الرحلة' : 'أضيفي بيانات رحلتك',
          icon: Icons.arrow_back_rounded, onPressed: () => go(const RifqaTripDetailsScreen())),
      ])),
    ]));
  }

  Widget _hotelDetail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: Rp.style(11, color: Rp.muted)),
            Expanded(child: Text(value, style: Rp.style(11.5, weight: FontWeight.w800))),
          ],
        ),
      );

  Widget _infoTile({required IconData icon, required String label, required String value}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      decoration: BoxDecoration(color: Rp.cream, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Icon(icon, size: 21, color: Rp.green), const SizedBox(height: 4),
        Text(label, style: Rp.style(10, color: Rp.muted)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: Rp.style(11.5, weight: FontWeight.w900)),
      ]));

  Widget _shortcuts() {
    final options = <({String title, IconData icon, VoidCallback? tap})>[
      (title: 'أدعيتي', icon: Icons.menu_book_rounded, tap: widget.onDuas),
      (title: 'المزارات', icon: Icons.location_on_outlined, tap: widget.onZiyarat),
      (title: 'الأسواق', icon: Icons.storefront_outlined, tap: widget.onMarkets),
    ];
    return Row(children: [for (var i = 0; i < options.length; i++) ...[
      Expanded(child: Material(color: Colors.white, borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: options[i].tap ?? () => rpToast(context, 'دي هتتربط بقسم ${options[i].title} من الـHome لاحقًا.'),
          borderRadius: BorderRadius.circular(17),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 14),
            child: Column(children: [
              Icon(options[i].icon, color: Rp.green, size: 27), const SizedBox(height: 8),
              Text(options[i].title, style: Rp.style(11.5, weight: FontWeight.w800)),
              if (options[i].tap == null) Text('ربط لاحقًا', style: Rp.style(8.5, color: Rp.muted)),
            ])),
        ))),
      if (i < options.length - 1) const SizedBox(width: 8),
    ]]);
  }

  @override
  Widget build(BuildContext context) => rpTextScale(context, Scaffold(
    backgroundColor: Rp.cream,
    body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _hero(context)),
      SliverPadding(padding: const EdgeInsets.fromLTRB(17, 20, 17, 35),
        sliver: SliverList(delegate: SliverChildListDelegate([
          _tripCard(),
          const SizedBox(height: 22),
          const RpSectionTitle('مختصر رحلتك', icon: Icons.favorite_border_rounded),
          _shortcuts(),
          const SizedBox(height: 22),
          const RpSectionTitle('إدارة الحساب والرحلة', icon: Icons.settings_outlined),
          RpCard(padding: const EdgeInsets.all(7), child: Column(children: [
            RpMenuRow(icon: Icons.person_outline_rounded, title: 'بياناتي الشخصية',
              subtitle: 'اسمك ومعلومات حسابك', onTap: () => go(const RifqaEditPersonalScreen())),
            const Divider(height: 5, color: Rp.edge),
            RpMenuRow(icon: Icons.luggage_outlined, title: 'بيانات رحلتي ورقم غرفتي',
              subtitle: 'اسم الفندق، الغرفة، الدور، المشرف', onTap: () => go(const RifqaTripDetailsScreen())),
            const Divider(height: 5, color: Rp.edge),
            RpMenuRow(icon: Icons.contact_phone_outlined, title: 'أرقامي المحفوظة',
              subtitle: 'العائلة والفندق والشركة والمرشد', onTap: () => go(const RifqaSavedContactsScreen())),
            const Divider(height: 5, color: Rp.edge),
            RpMenuRow(icon: Icons.translate_rounded, title: 'العرض وإمكانية الوصول',
              subtitle: 'حجم الخط والخصوصية', onTap: () => go(const RifqaAccountSettingsScreen())),
          ])),
          const SizedBox(height: 15),
          RpMenuRow(danger: true, icon: Icons.emergency_share_outlined,
            title: 'الأرقام المهمة والطوارئ', subtitle: 'اتصال سريع بالإسعاف والشرطة والدفاع المدني',
            onTap: () => go(const RifqaEmergencyNumbersScreen())),
          const SizedBox(height: 18),
          Text('بيانات إقامتك المحفوظة تخص جهازك الحالي. لا ترفعي تفاصيل الغرفة أو أرقام المرافقين للعلن.',
            textAlign: TextAlign.center, style: Rp.style(10, color: Rp.muted)),
        ]))),
    ]),
  ));
}

class RifqaEditPersonalScreen extends StatefulWidget {
  const RifqaEditPersonalScreen({super.key});
  @override
  State<RifqaEditPersonalScreen> createState() => _RifqaEditPersonalScreenState();
}

class _RifqaEditPersonalScreenState extends State<RifqaEditPersonalScreen> {
  final store = RifqaProfileStore.instance;
  final name = TextEditingController();
  final phone = TextEditingController();
  bool busy = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    await store.load(); if (!mounted) return;
    String initialName = '';
    String initialPhone = '';
    try { initialName = FirebaseAuth.instance.currentUser?.displayName ?? '';
      initialPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? ''; } catch (_) {}
    name.text = store.personal.name.isEmpty ? initialName : store.personal.name;
    phone.text = store.personal.phone.isEmpty ? initialPhone : store.personal.phone;
    setState(() {});
  }
  @override
  void dispose() { name.dispose(); phone.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (phone.text.trim().isNotEmpty && !rpValidPhone(phone.text)) {
      rpToast(context, 'راجعي رقم الهاتف'); return;
    }
    setState(() => busy = true);
    try {
      await store.savePersonal(RifqaPersonalInfo(name: name.text.trim(), phone: phone.text.trim()));
      if (mounted) { rpToast(context, 'تم الحفظ محليًا'); Navigator.pop(context); }
    } catch (_) { if (mounted) rpToast(context, 'تعذر الحفظ'); }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => rpTextScale(context, Scaffold(backgroundColor: Rp.cream,
    body: Column(children: [Expanded(child: ListView(children: [
      const RpPhotoHeader(title: 'بياناتي الشخصية', subtitle: 'تعديل طريقة عرض اسمك في رِفقة', height: 218),
      Padding(padding: const EdgeInsets.all(17), child: RpCard(child: Column(children: [
        RpFormField(controller: name, label: 'الاسم المعروض', hint: 'اسمك', icon: Icons.person_outline_rounded),
        RpFormField(controller: phone, label: 'رقم التواصل (اختياري)', hint: 'رقمك', icon: Icons.call_outlined, phone: true),
        Text('التغييرات هنا محلية داخل قسم حسابي؛ لا تعدّل اسم أو رقم حساب Firebase ولا إعدادات تسجيل الدخول.',
          style: Rp.style(11, color: Rp.muted)),
      ]))),
    ])), SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(17),
      child: RpPrimaryButton(label: busy ? 'جارٍ الحفظ' : 'حفظ', onPressed: busy ? null : _save))),
    ]),
  ));
}

class RifqaAccountSettingsScreen extends StatefulWidget {
  const RifqaAccountSettingsScreen({super.key});
  @override
  State<RifqaAccountSettingsScreen> createState() => _RifqaAccountSettingsScreenState();
}

class _RifqaAccountSettingsScreenState extends State<RifqaAccountSettingsScreen> {
  final store = RifqaProfileStore.instance;
  @override
  void initState() { super.initState(); store.addListener(_refresh); store.load(); }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { store.removeListener(_refresh); super.dispose(); }
  @override
  Widget build(BuildContext context) => rpTextScale(context, Scaffold(backgroundColor: Rp.cream,
    body: ListView(children: [
      const RpPhotoHeader(title: 'الإعدادات', subtitle: 'تجربة مريحة وآمنة داخل رِفقة', height: 205,
        image: 'assets/rifqa_profile/madinah.jpg'),
      Padding(padding: const EdgeInsets.all(17), child: Column(children: [
        const RpSectionTitle('إمكانية الوصول', icon: Icons.accessibility_new_outlined),
        RpCard(child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero, activeTrackColor: Rp.green,
          title: Text('تكبير حجم النص', style: Rp.style(13.5, weight: FontWeight.w900)),
          subtitle: Text('داخل صفحات حسابي والأرقام المهمة', style: Rp.style(11, color: Rp.muted)),
          value: store.largeText,
          onChanged: (v) async {
            try { await store.setLargeText(v); }
            catch (_) { if (context.mounted) rpToast(context, 'تعذر حفظ الإعداد'); }
          },
        )),
        const SizedBox(height: 20),
        const RpSectionTitle('خصوصية البيانات', icon: Icons.shield_outlined),
        RpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('البيانات الخاصة برحلتك محفوظة محليًا على هذا الجهاز، ويمكن الوصول إليها أثناء السفر حتى دون إنترنت.',
            style: Rp.style(12)),
          const SizedBox(height: 8),
          Text('هذه النسخة لا تزامن بيانات الرحلة أو أرقامك المحفوظة مع Firebase. SharedPreferences ليست مخزنًا مشفرًا للمعلومات الحساسة.',
            style: Rp.style(11, color: Rp.muted)),
        ])),
      ])),
    ]),
  ));
}
