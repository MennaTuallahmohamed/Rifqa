RIFQA / MADINAH CINEMATIC v2
============================

الإصدار الثاني من تجربة المدينة المنورة. الحزمة تستهدف C:\Rifqa-main
وتعالج مشكلة الخلفيات الخضراء الفارغة: الصور المدمجة هي Assets فعلية داخل التطبيق،
وفي حالة فقدان أي صورة يظهر مسارها المفقود بدل شاشة فارغة.

محتويات الحزمة:
- cinematic_theme.dart: ألوان وتصميم وطريقة عرض الصور وتشخيص الصورة المفقودة.
- cinematic_hub.dart: شاشة الرحلات المصورة (المسجد والروضة ومعرض السيرة).
- cinematic_tour.dart: جولة سينمائية بمشاهد وعمق/زووم/انتقالات وصوت TTS.
- seerah_museum.dart: 50 قصة، بحث، فئات، سحب بطاقات، قراءة واستماع ومرجع.
- cinematic_salawat.dart: شاشة الصلاة والسلام بنصوص وصوت TTS ومصادر.
- 57 صورة JPEG مضمنة دون روابط إنترنت (7 مشاهد + 50 غلافًا).
- 50 ملخصًا وقصة بصيغة JSON من الملف الذي قدمتيه، مع المراجع المذكورة فيه.
- Install-RifqaMadinah-v2.ps1 لعمل نسخة احتياطية والتثبيت والفحص.

الصور الموجودة للحكايات أغلفة مصورة/توضيحية مشتقة من 7 صور مدخلية، وليست 50
صورة تاريخية أصلية. لابد من التأكد من رخص إعادة الاستخدام قبل النشر.
التجربة سينمائية 2.5D بصور حقيقية وتأثير عمق. لا تحتوي مجسم Unity مكانيًا كاملًا.

التثبيت (PowerShell - داخل VS Code):
cd C:\Rifqa-main
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\Rifqa-Madinah-Final-v2.zip" -DestinationPath ".\_madinah_v2" -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ".\_madinah_v2\Install-RifqaMadinah-v2.ps1" -ProjectRoot "C:\Rifqa-main" -Preview

لو ظهر PREVIEW ONLY من دون خطأ:
powershell -NoProfile -ExecutionPolicy Bypass -File ".\_madinah_v2\Install-RifqaMadinah-v2.ps1" -ProjectRoot "C:\Rifqa-main"
flutter clean
flutter pub get
flutter analyze
flutter run

لو ظهر خطأ Asset Missing في التطبيق: تابعي مسار الصورة المكتوب على الشاشة،
وتأكدي أن الصورة موجودة تحت C:\Rifqa-main\assets\images\madinah_cinematic\
وأن pubspec.yaml فيه مرة واحدة فقط:
    - assets/images/madinah_cinematic/
    - assets/data/madinah_cinematic/
ثم flutter clean وflutter pub get وflutter run.

التثبيت متكرر بأمان: يكتشف الimports والassets الحالية ولا يكررها.
كل تثبيت ينشئ نسخة احتياطية تحت %USERPROFILE%\Rifqa-Backups\madinah-v2-...
ولا يغير main.dart أو Firebase أو شاشات الحجز الموجودة.

ملاحظات مهمة:
- لا يعتمد على Firebase Blaze أو اشتراكات خارجية.
- الصوت نطق آلي TTS، ويتوقف على وجود صوت عربي بالجهاز. لا يضيف ملفات MP3.
- القصص والمراجع من الملف المقدم؛ المراجعة الشرعية والتحريرية لازمة قبل النشر.
- صور الديمو المولدة ليست دليلًا على شكل داخلي مطابق للمعمار الفعلي.
- لا توجد مكتبة Dart SDK أو Flutter SDK في بيئة إعداد الملف، لذا لم ينفذ
  flutter analyze على المشروع المحلي الفعلي. يجب تنفيذ الفحص على جهازك.
