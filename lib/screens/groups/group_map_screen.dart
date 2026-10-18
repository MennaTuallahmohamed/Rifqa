import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/groups/group_service.dart';
import 'groups_screen.dart' show friendlyError, ago;
import 'rifqa_chat_theme.dart';

class _Pin {
  final String id;
  final String title;
  final String subtitle;
  final LatLng point;
  final bool alert;
  final bool mine;
  const _Pin({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.point,
    required this.alert,
    required this.mine,
  });
}

class GroupMapScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupMapScreen(
      {super.key, required this.groupId, required this.groupName});
  @override
  State<GroupMapScreen> createState() => _GroupMapScreenState();
}

class _GroupMapScreenState extends State<GroupMapScreen> {
  final service = GroupService.instance;
  final controller = MapController();
  _Pin? selected;
  List<LatLng> _lastPoints = const [];

  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<_Pin> buildPins(QuerySnapshot<Map<String, dynamic>> locs,
      QuerySnapshot<Map<String, dynamic>> alerts) {
    final now = DateTime.now();
    final pins = <_Pin>[];
    for (final d in locs.docs) {
      final m = d.data();
      final exp = m['expiresAt'] as Timestamp?;
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      if (exp == null ||
          !exp.toDate().isAfter(now) ||
          lat == null ||
          lng == null) {
        continue;
      }
      pins.add(_Pin(
        id: 'l_${d.id}',
        title: m['userName']?.toString() ?? 'عضو',
        subtitle: 'آخر تحديث: ${ago(m['updatedAt'] as Timestamp?)}',
        point: LatLng(lat, lng),
        alert: false,
        mine: d.id == myUid,
      ));
    }
    for (final d in alerts.docs) {
      final m = d.data();
      if (m['status'] != 'open') continue;
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      pins.add(_Pin(
        id: 'a_${d.id}',
        title: '${m['senderName'] ?? 'عضو'} يطلب المساعدة',
        subtitle: ago(m['createdAt'] as Timestamp?),
        point: LatLng(lat, lng),
        alert: true,
        mine: m['senderId'] == myUid,
      ));
    }
    return pins;
  }

  void fitAll() {
    if (_lastPoints.isEmpty) return;
    if (_lastPoints.length == 1) {
      controller.move(_lastPoints.first, 16);
    } else {
      controller.fitCamera(CameraFit.coordinates(
        coordinates: _lastPoints,
        padding: const EdgeInsets.all(60),
        maxZoom: 17,
      ));
    }
  }

  Future<void> directions(_Pin p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${p.point.latitude},${p.point.longitude}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الخرائط')));
    }
  }

  Marker markerFor(_Pin p) {
    final color = p.alert
        ? const Color(0xFFC8352F)
        : (p.mine ? const Color(0xFF2777C9) : RifqaChat.emerald);
    return Marker(
        point: p.point,
        width: 57,
        height: 62,
        child: GestureDetector(
            onTap: () => setState(() => selected = p),
            child: Stack(alignment: Alignment.topCenter, children: [
              Icon(Icons.location_on_rounded,
                  size: 58,
                  color: color,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 5)
                  ]),
              Positioned(
                  top: 8,
                  child: CircleAvatar(
                      radius: 17,
                      backgroundColor: RifqaChat.paper,
                      child: Icon(
                          p.alert
                              ? Icons.sos_rounded
                              : (p.mine
                                  ? Icons.person_rounded
                                  : Icons.people_alt_rounded),
                          size: 19,
                          color: color))),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: RifqaChat.deep,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text('خريطة ${widget.groupName}',
              maxLines: 1, overflow: TextOverflow.ellipsis)),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'عرض الكل',
        onPressed: fitAll,
        child: const Icon(Icons.zoom_out_map),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.locations(widget.groupId),
        builder: (context, ls) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.alerts(widget.groupId),
          builder: (context, als) {
            if (ls.hasError)
              return Center(child: Text(friendlyError(ls.error!)));
            if (als.hasError)
              return Center(child: Text(friendlyError(als.error!)));
            if (!ls.hasData || !als.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final pins = buildPins(ls.data!, als.data!);
            final pts = pins.map((p) => p.point).toList();
            _lastPoints = pts;
            final sel = selected;
            return Stack(children: [
              FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCenter: pts.length == 1
                      ? pts.first
                      : const LatLng(21.4225, 39.8262),
                  initialZoom: pts.length == 1 ? 16 : 13,
                  initialCameraFit: pts.length >= 2
                      ? CameraFit.coordinates(
                          coordinates: pts,
                          padding: const EdgeInsets.all(60),
                          maxZoom: 17)
                      : null,
                  onTap: (_, __) => setState(() => selected = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // غيّريه لـ applicationId بتاع تطبيقك
                    userAgentPackageName: 'com.example.rafeek',
                  ),
                  MarkerLayer(markers: pins.map(markerFor).toList()),
                  const SimpleAttributionWidget(
                      source: Text('© OpenStreetMap')),
                ],
              ),
              Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                      color: RifqaChat.paper,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: RifqaChat.lightGreen,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.groups_rounded,
                                    color: RifqaChat.deep)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      '${pins.where((p) => !p.alert).length} يشاركون موقعهم الآن',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: RifqaChat.deep)),
                                  const Text(
                                      'مواقع حقيقية يتم تحديثها من المجموعة',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: RifqaChat.muted)),
                                ])),
                            if (pins.any((p) => p.alert))
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.red),
                          ])))),
              if (pins.isEmpty)
                const Align(
                  alignment: Alignment.center,
                  child: Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'لا أحد يشارك موقعه الآن ولا توجد استغاثات مفتوحة'),
                    ),
                  ),
                ),
              if (sel != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(
                          leading: Icon(
                              sel.alert ? Icons.sos : Icons.person_pin_circle,
                              color: sel.alert ? Colors.red : null),
                          title: Text(sel.title),
                          subtitle: Text(sel.subtitle),
                          trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => selected = null)),
                        ),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text:
                                        '${sel.point.latitude},${sel.point.longitude}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم نسخ الإحداثيات')));
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('نسخ'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => directions(sel),
                              icon: const Icon(Icons.directions),
                              label: const Text('اتجاهات'),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
