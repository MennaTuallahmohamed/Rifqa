رِفقة - المدينة السينمائية + 50 قصة | الإصدار التجريبي الأول
=====================================================

ما الذي في الحزمة؟
- 4 ملفات Flutter جديدة، مستقلة، متوافقة مع نمط مشروع Rifqa الحالي.
- 3 مداخل: جولة المسجد النبوي، جولة الروضة، معرض السيرة النبوية.
- 50 قصة عربية كاملة في JSON (العنوان، الملخص، المرجع، التصنيف، مسار صورة).
- 50 صورة غلاف مستقلة، أُعدّت من صور المشروع المرفوعة وليست صورًا تاريخية لكل حدث.
- 7 صور للمشاهد، وانتقالات Fade / Depth / Ken Burns وزاوية مشاهدة متغيرة.
- صوت TTS عربي اختياري لقراءة الملخص، مع زر إيقاف.
- معرض قابل للبحث والتصنيف والتمرير بمنظور Coverflow ثلاثي الإحساس.
- زر داخل جولة الروضة يفتح دليل الحجز الأصلي دون إزالته.
- سكريبت فحص/تثبيت وملف استعادة مع نسخة احتياطية تلقائية خارج مجلد Git.

التجربة هنا 2.5D سينمائية موجّهة مع صور وإيهام عمق؛ ليست Unity ولا نموذجًا هندسيًا
ثلاثي الأبعاد للمسجد أو الروضة ولا تسمح بالمشي الحر داخل نموذج مكاني.

التثبيت - من PowerShell داخل VS Code
--------------------------------------
1. حمّلي Rifqa-Madinah-Cinematic-v1.zip واحفظيه في Downloads.
2. شغّلي الأوامر التالية:

cd C:\Rifqa-main
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\Rifqa-Madinah-Cinematic-v1.zip" -DestinationPath "C:\Rifqa-main\_madinah_cinematic_setup" -Force
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Rifqa-main\_madinah_cinematic_setup\Install-RifqaMadinah.ps1" -ProjectRoot "C:\Rifqa-main" -Preview

3. لو Preview نجح، شغّلي:

powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Rifqa-main\_madinah_cinematic_setup\Install-RifqaMadinah.ps1" -ProjectRoot "C:\Rifqa-main"
flutter pub get
flutter analyze
flutter run

إذا كان ZIP في مكان غير Downloads، عدّلي أول مسار فقط.

نطاق التعديل داخل المشروع
-------------------------
- يضيف ملفات lib/screens/madinah/immersive فقط.
- يضيف assets/images/madinah_cinematic وassets/data/madinah_cinematic.
- يغيّر ثلاثة روابط في lib/screens/madinah/madinah_screen.dart:
    _openVirtualTour -> MadinahImmersiveHub
    _openRawdah -> CinematicTourScreen.rawdah (مع رابط لدليل الحجز القديم)
    _openStories -> SeerahMuseumScreen
- يضيف مجلدي assets بالضبط مرة واحدة في pubspec.yaml.
- لا يُغيّر Firebase أو main.dart أو باقي شاشات المشروع.
- يفحص قبل التثبيت أسماء دوال الربط؛ إذا تغيّرت نسختك المحلية سيوقف التثبيت لحمايتها.
- في إعادة تشغيل السكريبت، يتجاوز تعديل الروابط المكتمل ولا يكرر مفاتيح YAML.
- النسخة الاحتياطية تنحفظ تحت %USERPROFILE%\Rifqa-Backups\cinematic_YYYYMMDD_HHMMSS.

استعادة الملفين الأساسيين إن لزم
---------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Rifqa-main\_madinah_cinematic_setup\Restore-RifqaMadinah.ps1" -ProjectRoot "C:\Rifqa-main" -BackupFolder "C:\Users\YOUR_USER\Rifqa-Backups\cinematic_YYYYMMDD_HHMMSS"
(استبدلي BackupFolder بالمسار الذي أظهره سكريبت التثبيت.)

الصوت والصور والمراجع
----------------------
- يستخدم flutter_tts الموجود أصلًا في pubspec.yaml؛ اختيار الصوت وسماعه يعتمد على
  أصوات TTS العربية المثبتة على الجهاز. لا يوجد تسجيل بصوت الرسول ﷺ.
- الصور مشتقة من الصور المرفوعة سابقًا في files.zip ولا تحمل ادعاء أنها توثيق
  تاريخي لأحداث القصص. بعض الأغلفة متشابهة لكونها من 7 أصول بصرية.
- لم تُسحب صور مباشرة من Pinterest لأن عرضها في منتج منشور يحتاج حقًا واضحًا
  في إعادة الاستخدام، وروابط Pinterest لا تضمن ثبات الصورة أو حق النشر.
- نصوص القصص ومراجعها نُقلت من ملف الـ50 قصة الذي قدمته صاحبة المشروع، ولم
  يجر التحقق العلمي من 50 مصدرًا حديثيًا واحدًا واحدًا. راجعيها قبل النشر النهائي.
- الصور الموجودة في files.zip يجب التحقق من إذن استخدامها تجاريًا قبل النشر.
- العمل هنا لا يحتاج مفاتيح API أو خطة Firebase مدفوعة إضافية.

الاختبار
--------
تم التحقق آليًا من بنية الحزمة، 50 قصة و50 غلافًا، ووجود الـAssets ومساراتها.
لم يتم تشغيل flutter analyze أو بناء APK هنا لأن Flutter SDK غير موجود في
بيئة إعداد الحزمة. لذلك يلزم اختبارها في جهازك ومراجعة مخرجات flutter analyze.

إضافة على تجربة المسجد:
- عند اختيار دخول المسجد من المركز السينمائي، يُعاد استخدام أنيميشن
  فتح البوابة ثلاثي المنظور الموجود بالفعل في ملف madinah_gate_experience.dart
  قبل بدء مراحل المشاهد الجديدة.
