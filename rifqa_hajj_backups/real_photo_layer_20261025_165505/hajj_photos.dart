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
  0: [
    HajjPhoto('assets/hajj/step_1.jpg', 'الإحرام ويوم التروية'),
    HajjPhoto('assets/hajj/gallery/step_1_2.jpg', 'التلبية والاستعداد للحج'),
    HajjPhoto('assets/hajj/gallery/step_1_3.jpg', 'خيام منى يوم التروية'),
  ],
  1: [
    HajjPhoto('assets/hajj/step_2.jpg', 'الوقوف بعرفة'),
    HajjPhoto('assets/hajj/gallery/step_2_2.jpg', 'مشهد جبل الرحمة'),
    HajjPhoto('assets/hajj/gallery/step_2_3.jpg', 'الدعاء يوم عرفة'),
  ],
  2: [
    HajjPhoto('assets/hajj/step_3.jpg', 'المبيت بمزدلفة'),
    HajjPhoto('assets/hajj/gallery/step_3_2.jpg', 'المشعر الحرام'),
    HajjPhoto('assets/hajj/gallery/step_3_3.jpg', 'الحصى ومزدلفة'),
  ],
  3: [
    HajjPhoto('assets/hajj/step_4.jpg', 'رمي جمرة العقبة'),
    HajjPhoto('assets/hajj/gallery/step_4_2.jpg', 'جسر الجمرات'),
    HajjPhoto('assets/hajj/gallery/step_4_3.jpg', 'موضع الرمي'),
  ],
  4: [
    HajjPhoto('assets/hajj/step_5.jpg', 'الهدي والحلق والتقصير'),
    HajjPhoto('assets/hajj/gallery/step_5_2.jpg', 'الحلق أو التقصير'),
    HajjPhoto('assets/hajj/gallery/step_5_3.jpg', 'التحلل الأول'),
  ],
  5: [
    HajjPhoto('assets/hajj/step_6.jpg', 'طواف الإفاضة حول الكعبة'),
    HajjPhoto('assets/hajj/gallery/step_6_2.jpg', 'المسجد الحرام والطواف'),
    HajjPhoto('assets/hajj/gallery/step_6_3.jpg', 'السعي بين الصفا والمروة'),
  ],
  6: [
    HajjPhoto('assets/hajj/step_7.jpg', 'أيام التشريق ورمي الجمرات'),
    HajjPhoto('assets/hajj/gallery/step_7_2.jpg', 'الجمرات الثلاث'),
    HajjPhoto('assets/hajj/gallery/step_7_3.jpg', 'منى أيام التشريق'),
  ],
  7: [
    HajjPhoto('assets/hajj/step_8.jpg', 'طواف الوداع'),
    HajjPhoto('assets/hajj/gallery/step_8_2.jpg', 'الكعبة المشرفة'),
    HajjPhoto('assets/hajj/gallery/step_8_3.jpg', 'ختام رحلة الحج'),
  ],
};

/// يُستخدم مع خطوات الشرح الصغيرة لإعادة استخدام نفس صور المنسك.
String? hajjPhotoAsset(int step, int k) {
  final photos = hajjStepPhotos[step];
  if (photos == null || photos.isEmpty || k < 0) return null;
  return photos[k % photos.length].asset;
}

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
        Text('${photos.length} مشاهد — اسحبي للتنقل واضغطي للتكبير',
            style: const TextStyle(color: Color(0xFF66756F), fontSize: 12)),
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
