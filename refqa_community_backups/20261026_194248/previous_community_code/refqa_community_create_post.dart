import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'refqa_community_data.dart';
import 'refqa_community_widgets.dart';

class RefqaCommunityCreatePostScreen extends StatefulWidget {
  const RefqaCommunityCreatePostScreen({super.key});
  @override
  State<RefqaCommunityCreatePostScreen> createState() => _RefqaCommunityCreatePostScreenState();
}

class _RefqaCommunityCreatePostScreenState extends State<RefqaCommunityCreatePostScreen> {
  final text = TextEditingController();
  final location = TextEditingController(text: 'مكة المكرمة');
  final List<Uint8List> photos = [];
  RefqaPostType kind = RefqaPostType.question;
  RefqaTopic topic = RefqaTopic.umrah;
  bool picking = false;

  @override
  void initState() {
    super.initState();
    text.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    text.removeListener(_changed);
    text.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (picking || photos.length >= 5) {
      if (photos.length >= 5) refqaNotice(context, 'الحد الأقصى 5 صور');
      return;
    }
    setState(() => picking = true);
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1600);
      for (final file in files.take(5 - photos.length)) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 3 * 1024 * 1024) {
          if (mounted) refqaNotice(context, 'تم تجاهل صورة كبيرة؛ الحد 3 ميجابايت للصورة');
          continue;
        }
        photos.add(bytes);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) refqaNotice(context, 'تعذر اختيار الصور: $e');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void _publish() {
    final value = text.text.trim();
    if (value.length < 10) {
      refqaNotice(context, 'اكتبي تفاصيل لا تقل عن 10 أحرف');
      return;
    }
    RefqaCommunityData.instance.addPost(
      text: value,
      type: kind,
      topic: topic,
      location: location.text.trim(),
      images: List<Uint8List>.of(photos),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => RefqaRoot(
        child: Scaffold(
          body: Column(children: [
            const RefqaTopBar(title: 'إضافة منشور'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 20),
                children: [
                  RefqaWhitePanel(
                    padding: const EdgeInsets.all(15),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('نوع المنشور', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 13),
                      RefqaTypeStrip(
                        includeAll: false,
                        selected: kind,
                        onSelected: (v) { if (v != null) setState(() => kind = v); },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: text,
                        maxLength: 1000,
                        minLines: 5,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'اكتبي سؤالك أو نصيحتك أو معلومتك هنا...\nحاولي أن تكون واضحة ومفيدة قدر الإمكان.',
                          hintStyle: const TextStyle(fontSize: 13, height: 1.7, color: RefqaColors.muted),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(color: RefqaColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(color: RefqaColors.line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text('إضافة صور (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: _pickPhotos,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: RefqaColors.line, width: 1.4),
                            color: const Color(0xFFFDFDFC),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: RefqaColors.muted, size: 25),
                            const SizedBox(height: 4),
                            Text(picking ? 'جاري اختيار الصور...' : 'اضغطي لإضافة صور', style: const TextStyle(fontSize: 12, color: RefqaColors.muted)),
                            const Text('5 صور كحد أقصى • معاينة محلية', style: TextStyle(fontSize: 10, color: RefqaColors.muted)),
                          ]),
                        ),
                      ),
                      if (photos.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 75,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => Stack(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(photos[i], width: 78, height: 75, fit: BoxFit.cover)),
                              Positioned(top: 0, left: 0, child: InkWell(
                                onTap: () => setState(() => photos.removeAt(i)),
                                child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 15)),
                              )),
                            ]),
                          ),
                        ),
                      ],
                      const SizedBox(height: 17),
                      const Text('اختاري التصنيف المناسب', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      RefqaTopicStrip(current: topic, includeAll: false, onChanged: (v) => setState(() => topic = v)),
                      const SizedBox(height: 14),
                      const Text('الموقع (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: location,
                        maxLength: 70,
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: RefqaColors.teal),
                          hintText: 'مثال: مكة المكرمة',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: RefqaColors.paleGold, borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.verified_user_outlined, color: RefqaColors.golden),
                          SizedBox(width: 8),
                          Expanded(child: Text('في النسخة النهائية سيُراجع الفريق المحتوى قبل ظهوره للجميع. هذه الشاشة الآن معاينة محلية فقط.',
                              style: TextStyle(fontSize: 11, height: 1.5))),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SafeArea(
                top: false,
                child: RefqaPrimaryButton(text: 'نشر المنشور', onTap: text.text.trim().length >= 10 ? _publish : null),
              ),
            ),
          ]),
        ),
      );

}
