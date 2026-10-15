import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'haramain_live_models.dart';
import '../../models/haramain/haramain_map_demo_models.dart' show HaramainSite;
import 'haramain_geo.dart';

/// النقاط غير الموثّقة تُعرض للاستكشاف فقط. الملاحة لا تستخدمها أبدًا.
const bool kShowUnverifiedPois = true;

class _Node {
  final String id;
  final LatLng p;
  final String? poiId;
  final HaramainSite site;
  _Node(this.id, this.p, this.poiId, this.site);
}

class _Edge {
  final String a, b;
  final bool accessible;
  final double w;
  _Edge(this.a, this.b, this.accessible, this.w);
}

/// يحمّل assets/data/haramain/haramain_live.json
/// - النقاط: تُعرض (الموثّقة فقط في النسخة النهائية).
/// - الحواف (edges): تدخل في الملاحة فقط لو VERIFIED_ROUTE و navigationAllowed=true.
///   لا يُخترع أي مسار: لو مفيش شبكة موثّقة، الدالة route() ترجع null.
class HaramainDataService {
  static const asset = 'lib/screens/haramain/haramain_live.json';

  final List<HlPoi> _pois = [];
  final Map<String, _Node> _nodes = {};
  final List<_Edge> _edges = [];
  bool loaded = false;
  String? error;

  Future<void> load() async {
    try {
      final j = jsonDecode(await rootBundle.loadString(asset))
          as Map<String, dynamic>;
      for (final e in (j['pois'] as List? ?? const [])) {
        final p = HlPoi.fromJson(Map<String, dynamic>.from(e as Map));
        if (p.verified || kShowUnverifiedPois) _pois.add(p);
      }
      for (final e in (j['nodes'] as List? ?? const [])) {
        final m = Map<String, dynamic>.from(e as Map);
        _nodes[m['id'] as String] = _Node(
          m['id'] as String,
          LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
          m['poiId'] as String?,
          m['site'] == 'madinah' ? HaramainSite.madinah : HaramainSite.makkah,
        );
      }
      for (final e in (j['edges'] as List? ?? const [])) {
        final m = Map<String, dynamic>.from(e as Map);
        final ok = hlTrustFrom(m['verificationStatus'] as String?) ==
                HlTrust.verifiedRoute &&
            m['navigationAllowed'] == true;
        final a = _nodes[m['a']], b = _nodes[m['b']];
        if (!ok || a == null || b == null) continue;
        _edges.add(_Edge(a.id, b.id, m['accessible'] == true,
            HmGeo.distance(a.p, b.p)));
      }
    } catch (e) {
      error = '$e';
    }
    loaded = true;
  }

  List<HlPoi> poisFor(HaramainSite s) =>
      _pois.where((p) => p.site == s).toList(growable: false);

  bool hasVerifiedNetwork(HaramainSite s) =>
      _edges.any((e) => _nodes[e.a]?.site == s);

  HlPoi? byId(String id) {
    for (final p in _pois) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ───────────── الملاحة على الشبكة الموثّقة ─────────────
  HlRoute? route(HaramainSite site, LatLng from, HlPoi dest,
      {bool accessible = false}) {
    final nodes = _nodes.values.where((n) => n.site == site).toList();
    if (nodes.isEmpty) return null;

    _Node? nearestTo(LatLng p, double max) {
      _Node? b;
      var bd = max;
      for (final n in nodes) {
        final d = HmGeo.distance(p, n.p);
        if (d <= bd) {
          bd = d;
          b = n;
        }
      }
      return b;
    }

    final start = nearestTo(from, 120);
    _Node? end;
    for (final n in nodes) {
      if (n.poiId == dest.id) end = n;
    }
    end ??= nearestTo(dest.position, 30);
    if (start == null || end == null) return null;

    final adj = <String, List<_Edge>>{};
    for (final e in _edges) {
      if (accessible && !e.accessible) continue;
      (adj[e.a] ??= []).add(e);
      (adj[e.b] ??= []).add(_Edge(e.b, e.a, e.accessible, e.w));
    }

    final dist = <String, double>{for (final n in nodes) n.id: double.infinity};
    final prev = <String, String>{};
    final todo = nodes.map((n) => n.id).toSet();
    dist[start.id] = 0;
    while (todo.isNotEmpty) {
      String? u;
      var ud = double.infinity;
      for (final id in todo) {
        if (dist[id]! < ud) {
          ud = dist[id]!;
          u = id;
        }
      }
      if (u == null) break;
      todo.remove(u);
      if (u == end.id) break;
      for (final e in adj[u] ?? const <_Edge>[]) {
        final nd = ud + e.w;
        if (nd < (dist[e.b] ?? double.infinity)) {
          dist[e.b] = nd;
          prev[e.b] = u;
        }
      }
    }
    if (start.id != end.id && !prev.containsKey(end.id)) return null;

    final ids = <String>[end.id];
    while (ids.last != start.id) {
      ids.add(prev[ids.last]!);
    }
    final raw = <LatLng>[from, ...ids.reversed.map((i) => _nodes[i]!.p), dest.position];

    // إزالة النقاط المتقاربة جدًا (أقل من متر) لتفادي اتجاهات عشوائية.
    final pts = <LatLng>[raw.first];
    for (final p in raw.skip(1)) {
      if (HmGeo.distance(pts.last, p) >= 1) pts.add(p);
    }
    if (pts.length < 2) pts.add(dest.position);
    final cum = HmGeo.cumulative(pts);
    return HlRoute(pts, cum, _steps(pts, cum, dest), dest, accessible: accessible);
  }

  List<HlStep> _steps(List<LatLng> pts, List<double> cum, HlPoi dest) {
    double brg(int i) => HmGeo.bearing(pts[i], pts[i + 1]);
    final raw = <(HlTurn, String, int)>[
      (HlTurn.start, 'الاتجاه ${HmGeo.cardinal(brg(0))}', 0),
    ];
    for (var i = 1; i < pts.length - 1; i++) {
      final d = HmGeo.angleDiff(brg(i - 1), brg(i));
      if (d.abs() < 25) continue;
      final HlTurn t;
      if (d.abs() > 150) {
        t = HlTurn.uTurn;
      } else if (d > 0) {
        t = d < 60 ? HlTurn.slightRight : HlTurn.right;
      } else {
        t = d > -60 ? HlTurn.slightLeft : HlTurn.left;
      }
      raw.add((t, _turnText(t), i));
    }
    raw.add((HlTurn.arrive, 'الوصول إلى ${dest.title}', pts.length - 1));
    return [
      for (var k = 0; k < raw.length; k++)
        HlStep(
          raw[k].$1,
          raw[k].$2,
          raw[k].$3,
          k + 1 < raw.length ? cum[raw[k + 1].$3] - cum[raw[k].$3] : 0,
        ),
    ];
  }

  String _turnText(HlTurn t) => switch (t) {
        HlTurn.slightRight => 'الانعطاف قليلًا يمينًا',
        HlTurn.right => 'الانعطاف يمينًا',
        HlTurn.slightLeft => 'الانعطاف قليلًا يسارًا',
        HlTurn.left => 'الانعطاف يسارًا',
        HlTurn.uTurn => 'الدوران للخلف',
        _ => 'الاستمرار للأمام',
      };
}
