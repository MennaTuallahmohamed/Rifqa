import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'haramain_live_models.dart';
import 'haramain_geo.dart';
import '../../services/haramain/haramain_voice_service.dart';

enum HlNavMode { none, route }

/// Step-by-step guidance on a VERIFIED_ROUTE only.
class HaramainNavSession extends ChangeNotifier {
  HaramainNavSession(this._voice);
  final HaramainVoiceService _voice;

  bool voiceOn = true;
  HlNavMode mode = HlNavMode.none;
  HlRoute? route;
  String targetName = '';

  bool arrived = false, offRoute = false;
  double remaining = 0, toNext = 0, arrow = 0;
  int stepIndex = 0;
  final _said = <String>{};

  bool get active => mode != HlNavMode.none;
  HlStep? get step => route?.steps[stepIndex];
  HlStep? get next {
    final r = route;
    if (r == null || stepIndex + 1 >= r.steps.length) return null;
    return r.steps[stepIndex + 1];
  }

  int get minutes => (remaining / 60).ceil().clamp(1, 999).toInt();

  void _say(String key, String text) {
    if (_said.add(key) && voiceOn) _voice.speak(text);
  }

  void startRoute(HlRoute r) {
    _reset();
    mode = HlNavMode.route;
    route = r;
    targetName = r.dest.title;
    remaining = r.meters;
    _say('start', 'بدء التوجيه إلى $targetName. ${r.steps.first.text}');
    notifyListeners();
  }

  void stop() {
    _reset();
    _voice.stop();
    notifyListeners();
  }

  void _reset() {
    mode = HlNavMode.none;
    route = null;
    arrived = false;
    offRoute = false;
    stepIndex = 0;
    remaining = toNext = arrow = 0;
    _said.clear();
  }

  void update(LatLng me, double? heading) {
    if (!active || route == null) return;
    final h = heading ?? 0;
    final r = route!;
    final pr = HmGeo.project(r.points, r.cum, me);
    offRoute = pr.dist > 45;
    remaining = (r.meters - pr.along).clamp(0.0, double.infinity).toDouble();

    var idx = 0;
    for (var i = 0; i < r.steps.length; i++) {
      if (r.cum[r.steps[i].pointIndex] <= pr.along + 3) idx = i;
    }
    if (idx != stepIndex) {
      stepIndex = idx;
      _say('s$idx', r.steps[idx].text);
    }
    final nx = next;
    toNext = nx == null
        ? remaining
        : (r.cum[nx.pointIndex] - pr.along).clamp(0.0, double.infinity).toDouble();
    if (nx != null && toNext < 40) {
      _say('n$stepIndex', 'بعد ${toNext.round()} متر، ${nx.text}');
    }
    final look = nx != null ? r.points[nx.pointIndex] : r.points.last;
    arrow = HmGeo.angleDiff(h, HmGeo.bearing(me, look));
    if (offRoute) {
      final slot = DateTime.now().millisecondsSinceEpoch ~/ 20000;
      _say('off$slot',
          'تنبيه: ابتعاد عن المسار المحدد. يُرجى العودة إلى الخط الأزرق.');
    }
    if (remaining < 15 && !arrived) {
      arrived = true;
      _say('arrive', 'تم الوصول إلى الوجهة.');
    }
    notifyListeners();
  }
}
