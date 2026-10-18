import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'watch_ui.dart';

/// Astronomical estimated times: verify against the official local timetable.
/// Does not set up prayer alarms automatically.
class RifqaWatchPrayerPage extends StatefulWidget {
  const RifqaWatchPrayerPage({super.key});
  @override State<RifqaWatchPrayerPage> createState() => _RifqaWatchPrayerPageState();
}

class _RifqaWatchPrayerPageState extends State<RifqaWatchPrayerPage> {
  List<(String, DateTime, IconData)> times = [];
  bool busy = false;
  String status = 'اسمحي بالموقع لحساب الأوقات في مكانك الحالي.';

  Future<void> _calculate() async {
    setState(() { busy = true; status = 'جارٍ حساب مواقيت الصلاة...'; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('فعّلي خدمة الموقع GPS أولًا.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('لم يُمنح إذن الموقع.');
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 18)));
      // The package defines returned prayer instants in UTC. Local conversion
      // uses the device time zone. There are no fabricated default times.
      final params = CalculationMethodParameters.ummAlQura();
      final pt = PrayerTimes(
        coordinates: Coordinates(pos.latitude, pos.longitude),
        date: DateTime.now(), calculationParameters: params);
      if (!mounted) return;
      setState(() {
        times = [
          ('الفجر', pt.fajr.toLocal(), Icons.nightlight_round),
          ('الشروق', pt.sunrise.toLocal(), Icons.wb_twilight_rounded),
          ('الظهر', pt.dhuhr.toLocal(), Icons.sunny),
          ('العصر', pt.asr.toLocal(), Icons.wb_sunny_outlined),
          ('المغرب', pt.maghrib.toLocal(), Icons.wb_twilight),
          ('العشاء', pt.isha.toLocal(), Icons.nights_stay_rounded),
        ];
        status = 'حسب GPS • طريقة حساب أم القرى • الأوقات بتوقيت الجهاز';
      });
    } catch (e) { if (mounted) setState(() { times = []; status = '$e'; }); }
    finally { if (mounted) setState(() => busy = false); }
  }

  String _fmt(DateTime at) {
    final h = (at.hour + 11) % 12 + 1;
    return '${h.toString().padLeft(2,'0')}:${at.minute.toString().padLeft(2,'0')} ${at.hour < 12 ? 'ص' : 'م'}';
  }

  @override Widget build(BuildContext context) => WatchGradientScaffold(topPhoto: true,
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('مواقيت الصلاة', style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.mosque_rounded, color: RW.gold, size: 29),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [
        const SizedBox(height: 18),
        WatchPanel(glow: true, child: Column(children: [
          const Icon(Icons.mosque_rounded, color: RW.gold, size: 44),
          Text('صلاتك في وقتها', style: RW.style(21, color: RW.lightGold,
            weight: FontWeight.w900)),
          Text(status, style: RW.style(12, color: RW.muted), textAlign: TextAlign.center),
        ])),
        const SizedBox(height: 17),
        for (final t in times) ...[
          WatchPanel(child: Row(children: [
            Icon(t.$3, color: RW.gold, size: 28), const SizedBox(width: 15),
            Expanded(child: Text(t.$1, style: RW.style(17))),
            Text(_fmt(t.$2), style: RW.style(19, color: RW.lightGold,
              weight: FontWeight.w800)),
          ])),
          const SizedBox(height: 7),
        ],
        const SizedBox(height: 15),
        WatchPrimaryButton(label: busy ? 'جارٍ الحساب...' : 'احسبي المواقيت من موقعي',
          icon: Icons.my_location, onTap: busy ? () {} : _calculate),
        const SizedBox(height: 18),
        WatchPanel(child: Text(
          'الأوقات حسابات فلكية بطريقة أم القرى، وقد تختلف عن مواقيت الجهات الرسمية أو المساجد. راجعي الجدول المعتمد في المكان، خصوصًا أثناء السفر. تذكير الصلاة لا يُفعّل تلقائيًا.',
          style: RW.style(12, color: RW.muted))),
      ])),
    ]));
}
