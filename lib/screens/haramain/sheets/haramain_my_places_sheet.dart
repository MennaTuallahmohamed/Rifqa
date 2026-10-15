import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import '../haramain_geo.dart';
import '../haramain_live_models.dart';
import '../theme/haramain_design.dart';
import '../widgets/haramain_trust.dart';
import 'haramain_poi_sheet.dart';

/// Personal places: My Gate, hotel, bus, meeting point, custom pins.
///
/// Everything here is stored locally through `HaramainUserDataRepository`.
/// The sheet is written against that interface so a future Firebase
/// implementation can back the same contract without any UI change.
class HmMyPlacesSheet extends StatelessWidget {
  const HmMyPlacesSheet({
    super.key,
    required this.site,
    required this.pins,
    required this.myLocation,
    required this.navigationPossible,
    required this.onSaveAtMyLocation,
    required this.onOpenPin,
    required this.onDeletePin,
    required this.onSharePin,
    required this.highContrast,
  });

  final HaramainSite site;
  final List<HlPin> pins;
  final ({double lat, double lng})? myLocation;
  final bool navigationPossible;
  final void Function(HlPinKind kind) onSaveAtMyLocation;
  final void Function(HlPin pin) onOpenPin;
  final void Function(HlPin pin) onDeletePin;
  final void Function(HlPin pin) onSharePin;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final primaryKinds = [
      HlPinKind.myGate,
      HlPinKind.hotel,
      HlPinKind.bus,
      HlPinKind.meeting,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(
          'أماكني المحفوظة',
          subtitle: 'تُحفظ على جهازك. يمكن ربطها بحسابك لاحقًا للمزامنة.',
        ),
        const SizedBox(height: 12),
        Text('احفظ موقعك الحالي كـ', style: HmTheme.sectionLabel),
        const SizedBox(height: 8),
        if (myLocation == null)
          HmNotice(
            message:
                'لم يُحدَّد موقعك بعد. فعّل خدمة الموقع، أو اضغط مطولًا على الخريطة '
                'لحفظ أي مكان.',
            icon: Icons.my_location_rounded,
            color: HmTheme.warn,
            background: HmTheme.warnSoft,
            highContrast: highContrast,
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in primaryKinds)
              ActionChip(
                avatar: Icon(kind.icon, size: 18, color: HmTheme.emerald),
                label: Text(kind.label),
                onPressed: myLocation == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onSaveAtMyLocation(kind);
                      },
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (pins.isEmpty)
          HmNotice(
            message:
                'لم تحفظ أي مكان بعد. احفظ باب دخولك أو فندقك أو نقطة تجمع '
                'لتصل إليها بسرعة وقت الحاجة.',
            icon: Icons.bookmark_border_rounded,
            color: HmTheme.muted,
            background: HmTheme.ivory,
            highContrast: highContrast,
          )
        else
          for (final pin in pins) _pinTile(context, pin),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.check_rounded),
          label: const Text('تم'),
        ),
      ],
    );
  }

  Widget _pinTile(BuildContext context, HlPin pin) {
    final distance = myLocation == null
        ? null
        : HmGeo.distance(
            LatLng(myLocation!.lat, myLocation!.lng),
            pin.position,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onOpenPin(pin),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highContrast ? Colors.black : HmTheme.line,
                width: highContrast ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: HmTheme.emeraldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(pin.kind.icon, color: HmTheme.emerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.label, style: HmTheme.h3),
                      const SizedBox(height: 2),
                      Text(
                        [
                          pin.kind.label,
                          if (distance != null)
                            '${HmGeo.meters(distance)} (بخط مستقيم)',
                        ].join(' · '),
                        style: HmTheme.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onSharePin(pin),
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: HmTheme.muted,
                  tooltip: 'مشاركة',
                ),
                IconButton(
                  onPressed: () => onDeletePin(pin),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: HmTheme.danger,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Saving a new pin: pick a kind, optionally name it.
class HmSavePinSheet extends StatelessWidget {
  const HmSavePinSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.highContrast,
    required this.onSave,
  });

  final double latitude;
  final double longitude;
  final bool highContrast;
  final void Function(HlPinKind kind, String label) onSave;

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        HlPinKind? selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle(
              'ثبّت هذا المكان',
              subtitle:
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 12),
            for (final kind in HlPinKind.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => selected = kind),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == kind
                              ? HmTheme.emerald
                              : HmTheme.line,
                          width: selected == kind ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(kind.icon, color: HmTheme.emerald),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(kind.label,
                                style: HmTheme.h3),
                          ),
                          if (selected == kind)
                            const Icon(Icons.check_circle_rounded,
                                color: HmTheme.emerald),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'اسم المكان (اختياري)',
                filled: true,
                fillColor: HmTheme.ivory,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: HmTheme.primaryButton(highContrast: highContrast),
              onPressed: selected == null
                  ? null
                  : () => onSave(selected!, nameController.text.trim()),
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text('احفظ المكان'),
            ),
          ],
        );
      },
    );
  }
}