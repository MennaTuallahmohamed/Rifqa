import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// مصادر صور المناسك. ضع الصور الأصلية (بدون واجهة هاتف أو نصوص)
/// في assets/hajj/ ثم نفّذ flutter pub get.
///
/// الصورة الأولى غلاف المنسك، والصورتان الأخريان تفاصيل إضافية للمعرض.
/// في حالة عدم وجود الصورة، يظهر بديل آمن بدون تعطيل التطبيق.
class HajjPhoto {
  final String asset;
  final String caption;
  const HajjPhoto(this.asset, this.caption);
}

const Map<int, List<HajjPhoto>> hajjStepPhotos = {
  0: [HajjPhoto('assets/hajj/step_1.jpg', 'خيام منى - يوم التروية')],
  1: [HajjPhoto('assets/hajj/step_2.jpg', 'جبل الرحمة - عرفة')],
  2: [HajjPhoto('assets/hajj/step_3.jpg', 'مشعر مزدلفة وقت الفجر')],
  3: [HajjPhoto('assets/hajj/step_4.jpg', 'الجمرات في منى')],
  4: [HajjPhoto('assets/hajj/step_5.jpg', 'مقص الشعر - صورة توضيحية للحلق والتقصير')],
  5: [HajjPhoto('assets/hajj/step_6.jpg', 'المسجد الحرام - طواف الإفاضة')],
  6: [HajjPhoto('assets/hajj/step_7.jpg', 'الجمرات في أيام التشريق')],
  7: [HajjPhoto('assets/hajj/step_8.jpg', 'المسجد الحرام - طواف الوداع')],
};

/// يُستخدم مع خطوات الشرح الصغيرة لإعادة استخدام نفس صور المنسك.
String? hajjPhotoAsset(int step, int k) {
  final photos = hajjStepPhotos[step];
  if (photos == null || photos.isEmpty || k < 0) return null;
  return photos[k % photos.length].asset;
}


const Map<int, String> _hajjCredits = {
  0: 'الصورة: Seeley International — Wikimedia Commons — CC BY-SA 4.0',
  1: 'الصورة: Fahad Faisal — Wikimedia Commons — CC BY-SA 4.0',
  2: 'الصورة: Arisdp — Wikimedia Commons — CC BY-SA 4.0',
  3: 'الصورة: Aiman titi — Wikimedia Commons — CC BY-SA 3.0',
  4: 'الصورة: Rakoon — Wikimedia Commons — CC0 1.0',
  5: 'الصورة: Wurzelgnohm — Wikimedia Commons — CC0 1.0',
  6: 'الصورة: Aiman titi — Wikimedia Commons — CC BY-SA 3.0',
  7: 'الصورة: Wurzelgnohm — Wikimedia Commons — CC0 1.0',
};

class HajjPhotoGallery extends StatelessWidget {
  final int step;
  const HajjPhotoGallery({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final photos = hajjStepPhotos[step] ?? const <HajjPhoto>[];
    if (photos.isEmpty) {
      return const Center(child: Text('لا توجد صور لهذا المنسك بعد.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('مشاهد المنسك',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 230,
          child: PageView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openPhoto(context, photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PhotoImage(photo: photo),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xC6051A14)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(photo.caption,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ),
                              const Icon(Icons.zoom_in_rounded,
                                  color: AppColors.gold),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('${photos.length} صورة — اضغطي للتكبير',
            style: const TextStyle(color: Color(0xFF66756F), fontSize: 12)),

        const SizedBox(height: 6),
        Text(_hajjCredits[step] ?? '',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF66756F))),
      ],
    );
  }

  void _openPhoto(BuildContext context, HajjPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF061B17),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(
                      photo.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _missingPhoto(),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'إغلاق',
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Text(photo.caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final HajjPhoto photo;
  const _PhotoImage({required this.photo});

  @override
  Widget build(BuildContext context) => Image.asset(
        photo.asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _missingPhoto(),
      );
}

Widget _missingPhoto() => Container(
      color: const Color(0xFF0C3D32),
      alignment: Alignment.center,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 32, color: AppColors.gold),
            SizedBox(height: 8),
            Text('تُضاف الصورة الواقعية هنا',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          ],
        ),
      ),
    );
