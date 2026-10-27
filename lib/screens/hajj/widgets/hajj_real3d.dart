import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../hajj_3d.dart';
import '../hajj_data.dart';
import 'hajj_scenes.dart';

/// Genuine 3D GLB viewer with camera orbit; the original interactive training
/// modes remain separately accessible. Replace the sample model GLBs with
/// production-quality PBR assets from Blender/Unity for photorealism.
class HajjReal3DPage extends StatelessWidget {
  const HajjReal3DPage({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final ix = index.clamp(0, 7).toInt();
    final model = 'assets/models/hajj/step_${ix + 1}.glb';
    return Scaffold(
      backgroundColor: const Color(0xFF081B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081B1A),
        foregroundColor: Colors.white,
        title: Text('مشهد 3D · ${hajjGuide[ix].title}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<bool>(
                future: _exists(model),
                builder: (context, s) {
                  if (s.data != true) {
                    return Stack(
                      children: [
                        HajjScene(index: ix, height: double.infinity),
                        if (s.connectionState != ConnectionState.waiting)
                          const Center(
                            child: Text('المجسم غير متوفر بعد؛ يمكنك فتح المحاكاة القديمة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    );
                  }
                  return ModelViewer(
                    src: model,
                    poster: 'assets/hajj/step_${ix + 1}.jpg',
                    alt: hajjGuide[ix].title,
                    backgroundColor: const Color(0xFFE9E8DF),
                    ar: false,
                    cameraControls: true,
                    autoRotate: false,
                    disableZoom: false,
                    exposure: 1.13,
                    shadowIntensity: 0.8,
                    shadowSoftness: 0.8,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  const Text('حرّكي إصبعك لتدوير الكاميرا، وقربي بإصبعين. المجسمات الحالية نماذج أولية وليست تصويرًا للواقع.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const HajjJourney3DPage(),
                      )),
                      icon: const Icon(Icons.sports_esports_rounded),
                      label: const Text('المحاكاة التفاعلية القديمة · رحلة الحج'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _exists(String asset) async {
    try { await rootBundle.load(asset); return true; }
    catch (_) { return false; }
  }
}
