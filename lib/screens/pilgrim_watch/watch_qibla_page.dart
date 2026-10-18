import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'watch_ui.dart';

class RifqaWatchQiblaPage extends StatefulWidget {
  const RifqaWatchQiblaPage({super.key});
  @override State<RifqaWatchQiblaPage> createState() => _RifqaWatchQiblaPageState();
}

class _RifqaWatchQiblaPageState extends State<RifqaWatchQiblaPage> {
  double? bearing;
  String status = 'اضغطي على تحديد موقعي لحساب اتجاه القبلة.';
  bool busy = false;
  static const kaabaLat = 21.4225, kaabaLon = 39.8262;

  double _calculate(double lat, double lon) {
    const rad = math.pi / 180;
    final p1 = lat * rad, p2 = kaabaLat * rad;
    final dLon = (kaabaLon - lon) * rad;
    final y = math.sin(dLon) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Future<void> _locate() async {
    setState(() { busy = true; status = 'جارٍ الحصول على الموقع بإذنك...'; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('خدمة الموقع مقفولة. فعّلي GPS أولًا.');
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        throw Exception('يلزم السماح بالموقع لحساب القبلة.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 18)));
      if (!mounted) return;
      setState(() {
        bearing = _calculate(pos.latitude, pos.longitude);
        status = 'اتجاه الكعبة محسوب من موقعك. حرّكي الجهاز في شكل 8 لو البوصلة غير دقيقة.';
      });
    } catch (e) {
      if (mounted) setState(() => status = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override Widget build(BuildContext context) => WatchGradientScaffold(
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('القبلة الحقيقية', style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.explore, color: RW.gold, size: 29),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
        WatchPanel(glow: true, child: Column(children: [
          Text('اتجاه الكعبة من موقعك', style: RW.style(17)),
          const SizedBox(height: 18),
          SizedBox(height: 280, child: StreamBuilder<CompassEvent>(
            stream: FlutterCompass.events,
            builder: (context, snapshot) {
              final heading = snapshot.data?.heading;
              final ready = bearing != null && heading != null;
              final angle = ready ? (bearing! - heading) * math.pi / 180 : 0.0;
              return Stack(alignment: Alignment.center, children: [
                Container(width: 266, height: 266,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: RW.gold, width: 3),
                    gradient: const RadialGradient(colors: [RW.green2, RW.black]))),
                for (var i=0; i<12; i++) Transform.rotate(angle: i * math.pi / 6,
                  child: const Align(alignment: Alignment(0,-.84), child: Icon(Icons.circle,
                    color: RW.gold, size: 4))),
                const Align(alignment: Alignment(0,-.71),
                  child: Text('N', style: TextStyle(color: RW.lightGold, fontSize: 21))),
                Transform.rotate(angle: angle, child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation, size: 58, color: RW.gold),
                    const SizedBox(height: 5),
                    const Icon(Icons.mosque, size: 26, color: RW.lightGold),
                  ])),
                if (!ready) Positioned(bottom: 38, child: Text(
                  bearing == null ? 'في انتظار الموقع' : 'المستشعر غير متاح أو لم يُعاير',
                  style: RW.style(11, color: RW.muted))),
              ]);
            })),
          if (bearing != null) Text('${bearing!.toStringAsFixed(1)}° من الشمال الحقيقي',
            style: RW.style(17, color: RW.gold, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(status, textAlign: TextAlign.center, style: RW.style(12, color: RW.muted)),
        ])),
        const SizedBox(height: 18),
        WatchPrimaryButton(label: busy ? 'جارٍ التحديد...' : 'استخدمي موقعي لحساب القبلة',
          icon: Icons.my_location, onTap: busy ? () {} : _locate),
        const SizedBox(height: 14),
        Text('تنبيه: بوصلة الهاتف قد تتأثر بالمغناطيس والمعادن. لا نعتمد على الاتجاه قبل التحقق من الموقع وتوفر مستشعر البوصلة.',
          style: RW.style(12, color: RW.muted), textAlign: TextAlign.center),
      ])),
    ]));
}
