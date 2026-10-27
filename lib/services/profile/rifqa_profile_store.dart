import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بيانات خاصة برحلة واحدة، تحفظ على جهاز المستخدم فقط.
/// لا تحفظ أرقام جواز أو وثائق أو تفاصيل طبية في SharedPreferences.
class RifqaTripInfo {
  const RifqaTripInfo({
    this.tripName = '',
    this.hotelName = '',
    this.roomNumber = '',
    this.floor = '',
    this.building = '',
    this.hotelAddress = '',
    this.madinahHotelName = '',
    this.madinahHotelAddress = '',
    this.hotelPhone = '',
    this.guideName = '',
    this.guidePhone = '',
    this.groupLeaderPhone = '',
    this.emergencyName = '',
    this.emergencyPhone = '',
    this.embassyName = '',
    this.embassyPhone = '',
  });

  final String tripName;
  final String hotelName;
  final String roomNumber;
  final String floor;
  final String building;
  final String hotelAddress;
  final String madinahHotelName;
  final String madinahHotelAddress;
  final String hotelPhone;
  final String guideName;
  final String guidePhone;
  final String groupLeaderPhone;
  final String emergencyName;
  final String emergencyPhone;
  final String embassyName;
  final String embassyPhone;

  bool get hasTrip => [tripName, hotelName, madinahHotelName, roomNumber, floor, building,
    hotelPhone, guideName, guidePhone, groupLeaderPhone].any((s) => s.trim().isNotEmpty);

  Map<String, String> toJson() => {
    'tripName': tripName, 'hotelName': hotelName, 'roomNumber': roomNumber,
    'floor': floor, 'building': building, 'hotelAddress': hotelAddress,
    'madinahHotelName': madinahHotelName,
    'madinahHotelAddress': madinahHotelAddress,
    'hotelPhone': hotelPhone, 'guideName': guideName,
    'guidePhone': guidePhone, 'groupLeaderPhone': groupLeaderPhone,
    'emergencyName': emergencyName, 'emergencyPhone': emergencyPhone,
    'embassyName': embassyName, 'embassyPhone': embassyPhone,
  };

  factory RifqaTripInfo.fromJson(Map<String, dynamic> j) => RifqaTripInfo(
    tripName: '${j['tripName'] ?? ''}',
    hotelName: '${j['hotelName'] ?? ''}',
    roomNumber: '${j['roomNumber'] ?? ''}',
    floor: '${j['floor'] ?? ''}',
    building: '${j['building'] ?? ''}',
    hotelAddress: '${j['hotelAddress'] ?? ''}',
    madinahHotelName: '${j['madinahHotelName'] ?? ''}',
    madinahHotelAddress: '${j['madinahHotelAddress'] ?? ''}',
    hotelPhone: '${j['hotelPhone'] ?? ''}',
    guideName: '${j['guideName'] ?? ''}',
    guidePhone: '${j['guidePhone'] ?? ''}',
    groupLeaderPhone: '${j['groupLeaderPhone'] ?? ''}',
    emergencyName: '${j['emergencyName'] ?? ''}',
    emergencyPhone: '${j['emergencyPhone'] ?? ''}',
    embassyName: '${j['embassyName'] ?? ''}',
    embassyPhone: '${j['embassyPhone'] ?? ''}',
  );
}

class RifqaPersonalInfo {
  const RifqaPersonalInfo({this.name = '', this.phone = ''});
  final String name;
  final String phone;
  Map<String, String> toJson() => {'name': name, 'phone': phone};
  factory RifqaPersonalInfo.fromJson(Map<String, dynamic> j) =>
      RifqaPersonalInfo(name: '${j['name'] ?? ''}', phone: '${j['phone'] ?? ''}');
}

class RifqaSavedContact {
  const RifqaSavedContact({
    required this.id,
    required this.title,
    required this.phone,
    this.subtitle = '',
  });
  final String id;
  final String title;
  final String phone;
  final String subtitle;
  Map<String, String> toJson() => {
    'id': id, 'title': title, 'phone': phone, 'subtitle': subtitle,
  };
  factory RifqaSavedContact.fromJson(Map<String, dynamic> j) => RifqaSavedContact(
    id: '${j['id'] ?? ''}', title: '${j['title'] ?? ''}',
    phone: '${j['phone'] ?? ''}', subtitle: '${j['subtitle'] ?? ''}',
  );
}

/// Singleton بسيط بدون ربط إضافي مع Firebase أو الـHome.
/// المفاتيح محلية؛ بيانات المستخدم لا تُرفع تلقائيًا إلى Firestore.
class RifqaProfileStore extends ChangeNotifier {
  RifqaProfileStore._();
  static final RifqaProfileStore instance = RifqaProfileStore._();

  static const _tripKey = 'rifqa_profile_trip_v1';
  static const _personalKey = 'rifqa_profile_personal_v1';
  static const _contactsKey = 'rifqa_profile_contacts_v1';
  static const _largeTextKey = 'rifqa_profile_large_text_v1';
  static const _profileImageKey = 'rifqa_profile_image_path_v1';

  RifqaTripInfo trip = const RifqaTripInfo();
  RifqaPersonalInfo personal = const RifqaPersonalInfo();
  List<RifqaSavedContact> contacts = [];
  String profileImagePath = '';
  bool largeText = false;
  bool loaded = false;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripString = prefs.getString(_tripKey);
      final personalString = prefs.getString(_personalKey);
      final contactsString = prefs.getString(_contactsKey);
      profileImagePath = prefs.getString(_profileImageKey) ?? '';
      if (tripString != null) {
        trip = RifqaTripInfo.fromJson(Map<String, dynamic>.from(jsonDecode(tripString) as Map));
      }
      if (personalString != null) {
        personal = RifqaPersonalInfo.fromJson(Map<String, dynamic>.from(jsonDecode(personalString) as Map));
      }
      if (contactsString != null) {
        contacts = (jsonDecode(contactsString) as List)
            .map((e) => RifqaSavedContact.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((c) => c.title.trim().isNotEmpty && c.phone.trim().isNotEmpty)
            .toList();
      }
      largeText = prefs.getBool(_largeTextKey) ?? false;
    } catch (e) {
      debugPrint('Rifqa profile local data load error: $e');
    } finally {
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> saveTrip(RifqaTripInfo value) async {
    await load();
    final p = await SharedPreferences.getInstance();
    await p.setString(_tripKey, jsonEncode(value.toJson()));
    trip = value;
    notifyListeners();
  }

  Future<void> savePersonal(RifqaPersonalInfo value) async {
    await load();
    final p = await SharedPreferences.getInstance();
    await p.setString(_personalKey, jsonEncode(value.toJson()));
    personal = value;
    notifyListeners();
  }

  Future<void> saveProfileImagePath(String value) async {
    await load();
    final p = await SharedPreferences.getInstance();
    await p.setString(_profileImageKey, value);
    profileImagePath = value;
    notifyListeners();
  }

  Future<void> upsertContact(RifqaSavedContact value) async {
    await load();
    final next = List<RifqaSavedContact>.of(contacts);
    final index = next.indexWhere((c) => c.id == value.id);
    if (index == -1) {
      next.add(value);
    } else {
      next[index] = value;
    }
    await _saveContacts(next);
  }

  Future<void> removeContact(String id) async {
    await load();
    final next = contacts.where((c) => c.id != id).toList();
    await _saveContacts(next);
  }

  Future<void> _saveContacts(List<RifqaSavedContact> value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_contactsKey, jsonEncode(value.map((c) => c.toJson()).toList()));
    contacts = value;
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    await load();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_largeTextKey, value);
    largeText = value;
    notifyListeners();
  }

  List<RifqaSavedContact> get tripContacts {
    final t = trip;
    return [
      if (t.hotelPhone.trim().isNotEmpty)
        RifqaSavedContact(id: 'trip_hotel', title: 'استقبال الفندق', phone: t.hotelPhone, subtitle: t.hotelName),
      if (t.guidePhone.trim().isNotEmpty)
        RifqaSavedContact(id: 'trip_guide', title: 'مرشد الرحلة', phone: t.guidePhone, subtitle: t.guideName),
      if (t.groupLeaderPhone.trim().isNotEmpty)
        RifqaSavedContact(id: 'trip_leader', title: 'مشرف الرحلة', phone: t.groupLeaderPhone, subtitle: t.tripName),
      if (t.emergencyPhone.trim().isNotEmpty)
        RifqaSavedContact(id: 'trip_emergency', title: 'جهة الاتصال الشخصية للطوارئ', phone: t.emergencyPhone, subtitle: t.emergencyName),
      if (t.embassyPhone.trim().isNotEmpty)
        RifqaSavedContact(id: 'trip_embassy', title: 'السفارة أو القنصلية', phone: t.embassyPhone, subtitle: t.embassyName),
    ];
  }
}
