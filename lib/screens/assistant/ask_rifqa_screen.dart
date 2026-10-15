// lib/features/ask_rifqa/ask_rifqa_screen.dart
//
// pubspec.yaml:
//   speech_to_text: ^7.0.0
//   flutter_tts: ^4.2.0
//
// Android  → AndroidManifest.xml:
//   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//   <uses-permission android:name="android.permission.INTERNET"/>
//   <queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>
//
// iOS → Info.plist:
//   NSMicrophoneUsageDescription = "نستخدم الميكروفون لتسمع رفقة سؤالك"
//   NSSpeechRecognitionUsageDescription = "نحوّل صوتك إلى نص لنجيب عن سؤالك"

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import 'rifqa_ai_service.dart';
import 'rifqa_history_service.dart';
import 'lost_help_screen.dart';
import 'rifqa_history_screen.dart';

const _cream = Color(0xFFFAF7F0);
const _ink = Color(0xFF1F2A24);
const _gold = Color(0xFFB8893A);
const _danger = Color(0xFFB3261E);

class _Msg {
  _Msg(this.text, {required this.isUser, this.sos = false, this.fromAi = false})
      : time = DateTime.now();
  final String text;
  final bool isUser;
  final bool sos;
  final bool fromAi;
  final DateTime time;
  int feedback = 0; // 1 مفيد، -1 غير مفيد

  StoredMessage toStored() => StoredMessage(
      text: text, isUser: isUser, fromAi: fromAi, sos: sos, time: time);
}

class AskRifqaScreen extends StatefulWidget {
  const AskRifqaScreen({
    super.key,
    this.lostProfile = const LostProfile(),
    this.onShareLocationWithGroup,
    this.onCallCompanion,
  });

  /// بيانات المستخدمة من ملفها الشخصي (اسم، فندق، تليفون المرافق…).
  final LostProfile lostProfile;

  /// اربطيها بمجموعات رفقة لإرسال الموقع كرسالة في الجروب.
  /// لو null بنستخدم المشاركة العادية (واتساب/رسائل).
  final ShareLocationCallback? onShareLocationWithGroup;
  final VoidCallback? onCallCompanion;

  @override
  State<AskRifqaScreen> createState() => _AskRifqaScreenState();
}

class _AskRifqaScreenState extends State<AskRifqaScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _service = RifqaAiService();
  final _history = RifqaHistoryService();
  String? _conversationId;
  Future<void> _persistChain = Future.value();
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final _messages = <_Msg>[];

  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  bool _sending = false;
  bool _speechReady = false;
  bool _listening = false;
  bool _autoSpeak = false;
  _Msg? _speakingMsg;

  static const _lostWords = [
    'تائه',
    'تايه',
    'تايهة',
    'تائهة',
    'ضعت',
    'ضايع',
    'ضايعة',
    'مش لاقي',
    'مش لاقية',
    'اتوهت',
    'تهت',
  ];

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _listening = false);
            _pulse.stop();
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
          _pulse.stop();
        },
      );
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.42); // أبطأ قليلًا = أوضح لكبار السن
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speakingMsg = null);
      });
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _pulse.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  // ───────────────────────── الإرسال ─────────────────────────

  bool _isLost(String q) => _lostWords.any(q.contains);

  // ───────────────────────── السجل ─────────────────────────

  /// نحفظ بالترتيب وبدون ما نعطّل الواجهة. أي فشل في الحفظ يتجاهل بهدوء.
  void _persist(_Msg m) {
    _persistChain = _persistChain.then((_) async {
      try {
        _conversationId ??= await _history.create(m.text);
        final id = _conversationId;
        if (id == null) return;
        await _history.addMessage(id, m.toStored());
      } catch (_) {}
    });
  }

  Future<void> _openHistory() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => RifqaHistoryScreen(service: _history)),
    );
    if (id == null || !mounted) return;
    await _tts.stop();
    final stored = await _history.load(id);
    if (!mounted) return;
    _service.resetConversation();
    setState(() {
      _conversationId = id;
      _speakingMsg = null;
      _messages
        ..clear()
        ..addAll(stored.map((s) {
          final m =
              _Msg(s.text, isUser: s.isUser, sos: s.sos, fromAi: s.fromAi);
          return m;
        }));
    });
  }

  void _openLostHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LostHelpScreen(
          profile: widget.lostProfile,
          onShareToGroup: widget.onShareLocationWithGroup,
        ),
      ),
    );
  }

  Future<void> _callCompanion() async {
    final phone = widget.lostProfile.companionPhone;
    if (phone == null || phone.isEmpty) {
      _toast('ضيفي رقم المرافق في ملفك الشخصي عشان نتصل بيه بضغطة.');
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _shareLocationWithGroup() async {
    final callback = widget.onShareLocationWithGroup;
    if (callback == null) {
      _openLostHelp();
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('فعّلي خدمة الموقع أولًا.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        _toast('اسمحي للتطبيق باستخدام الموقع لإرساله للمجموعة.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final sent = await callback(
        position.latitude,
        position.longitude,
        position.accuracy,
      );
      if (sent && mounted) _toast('تم إرسال موقعك للمجموعة.');
    } catch (_) {
      if (mounted) _toast('تعذّر إرسال موقعك. حاولي مرة أخرى.');
    }
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty || _sending) return;
    HapticFeedback.selectionClick();
    await _tts.stop();

    final userMsg = _Msg(question, isUser: true);
    setState(() {
      _sending = true;
      _speakingMsg = null;
      _messages.add(userMsg);
      _controller.clear();
    });
    _persist(userMsg);

    // حالة الضياع: رد فوري محلي + أزرار. لا ننتظر الذكاء الاصطناعي.
    if (_isLost(question)) {
      final m = _Msg(
        'اهدي، أنا معاكي. افتحي شاشة المساعدة وهحدد موقعك فورًا:',
        isUser: false,
        sos: true,
      );
      setState(() {
        _messages.add(m);
        _sending = false;
      });
      _persist(m);
      HapticFeedback.heavyImpact();
      if (_autoSpeak) _speak(m);
      return;
    }

    final reply = await _service.ask(question);
    if (!mounted) return;
    final m =
        _Msg(reply.text, isUser: false, fromAi: reply.source == RifqaSource.ai);
    setState(() {
      _messages.add(m);
      _sending = false;
    });
    _persist(m);
    if (_autoSpeak) _speak(m);
  }

  // ───────────────────────── الصوت ─────────────────────────

  Future<void> _toggleListen() async {
    HapticFeedback.mediumImpact();
    if (_listening) {
      await _speech.stop();
      return;
    }
    if (!_speechReady) {
      _toast(
          'الميكروفون غير متاح. اسمحي للتطبيق بالإذن من الإعدادات، أو اكتبي سؤالك.');
      return;
    }
    await _tts.stop();
    setState(() {
      _listening = true;
      _controller.clear();
    });
    _pulse.repeat(reverse: true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _controller.text = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          _pulse.stop();
          setState(() => _listening = false);
          _send();
        }
      },
    );
  }

  Future<void> _speak(_Msg m) async {
    if (_speakingMsg == m) {
      await _tts.stop();
      setState(() => _speakingMsg = null);
      return;
    }
    await _tts.stop();
    setState(() => _speakingMsg = m);
    await _tts.speak(m.text);
  }

  // ───────────────────────── أدوات ─────────────────────────

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _newChat() {
    _tts.stop();
    _service.resetConversation();
    _conversationId = null;
    setState(() {
      _messages.clear();
      _speakingMsg = null;
    });
  }

  Future<void> _confirmSos({
    required String title,
    required String body,
    required String action,
    required Future<void> Function()? run,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          content:
              Text(body, style: const TextStyle(fontSize: 16, height: 1.6)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                minimumSize: const Size(130, 48),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (run == null) {
      _toast('هنربط الميزة دي بزر «أنا تائه» قريبًا.');
      return;
    }
    await run();
  }

  // ───────────────────────── الواجهة ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            const _SafetyStrip(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _messages.isEmpty ? _buildWelcome() : _buildChat(),
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .16),
              border: Border.all(color: _gold, width: 1.5),
            ),
            child: const Icon(Icons.spa_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اسألي رِفقة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('مساعدتك في الحج والعمرة',
                  style:
                      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'المحادثات السابقة',
          onPressed: _openHistory,
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: _autoSpeak ? 'إيقاف قراءة الردود' : 'قراءة الردود بصوت عالٍ',
          onPressed: () {
            setState(() => _autoSpeak = !_autoSpeak);
            if (!_autoSpeak) _tts.stop();
            _toast(_autoSpeak
                ? 'رفقة هتقرأ لك الردود'
                : 'تم إيقاف القراءة الصوتية');
          },
          icon: Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded),
        ),
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: 'محادثة جديدة',
            onPressed: _newChat,
            icon: const Icon(Icons.add_comment_rounded),
          ),
      ],
    );
  }

  // ── شاشة الترحيب ──

  Widget _buildWelcome() {
    final categories = <(IconData, String, String)>[
      (Icons.route_rounded, 'مناسك العمرة', 'إيه خطوات العمرة؟'),
      (Icons.place_rounded, 'أروح فين؟', 'فين أقرب دورة مياه؟'),
      (Icons.support_agent_rounded, 'محتاجة مساعدة', 'محتاجة مساعدة'),
      (Icons.menu_book_rounded, 'سؤال ديني', 'عندي سؤال ديني'),
    ];
    final suggestions = _service.suggestions.take(4).toList();

    return ListView(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      children: [
        const Text(
          'السلام عليكم ورحمة الله 🌿',
          style:
              TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink),
        ),
        const SizedBox(height: 6),
        const Text(
          'أنا معاكي خطوة بخطوة. اضغطي على الميكروفون وتكلمي، أو اختاري من تحت.',
          style:
              TextStyle(fontSize: 15.5, height: 1.7, color: Color(0xFF55615A)),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            for (final c in categories)
              _CategoryTile(icon: c.$1, label: c.$2, onTap: () => _send(c.$3)),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('أسئلة بيسألوها كتير',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF55615A))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in suggestions)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 14.5)),
                  backgroundColor: Colors.white,
                  side:
                      BorderSide(color: AppColors.green.withValues(alpha: .25)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  onPressed: () => _send(s),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ── المحادثة ──

  Widget _buildChat() {
    final itemCount = _messages.length + (_sending ? 1 : 0);
    return ListView.builder(
      key: const ValueKey('chat'),
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_sending && index == 0) return const _TypingBubble();
        final i = _sending ? index - 1 : index;
        final m = _messages[_messages.length - 1 - i];
        return _Bubble(
          msg: m,
          speaking: _speakingMsg == m,
          onSpeak: () => _speak(m),
          onCopy: () {
            Clipboard.setData(ClipboardData(text: m.text));
            _toast('تم النسخ');
          },
          onFeedback: (v) =>
              setState(() => m.feedback = m.feedback == v ? 0 : v),
          onShareLocation: () => _confirmSos(
            title: 'مشاركة موقعك مع المجموعة؟',
            body: 'هنبعت موقعك الحالي لأعضاء مجموعتك عشان يوصلولك.',
            action: 'ابعتي موقعي',
            run: _shareLocationWithGroup,
          ),
          onCallCompanion: () => _confirmSos(
            title: 'الاتصال بالمرافق؟',
            body: 'هنتصل بالمرافق المسجّل عندك دلوقتي.',
            action: 'اتصلي',
            run: widget.onCallCompanion == null
                ? _callCompanion
                : () async {
                    widget.onCallCompanion!();
                  },
          ),
        );
      },
    );
  }

  // ── شريط الإدخال (الميكروفون هو البطل) ──

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _listening
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _controller.text.isEmpty
                              ? 'بسمعك… اتكلمي دلوقتي'
                              : _controller.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: _controller.text.isEmpty
                                ? AppColors.green
                                : _ink,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Row(
                children: [
                  _MicButton(
                    listening: _listening,
                    pulse: _pulse,
                    onTap: _toggleListen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_listening,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 300,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16.5),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'أو اكتبي سؤالك هنا',
                        filled: true,
                        fillColor: _cream,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.green,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: (_sending ||
                            _controller.text.trim().isEmpty ||
                            _listening)
                        ? null
                        : _send,
                    tooltip: 'إرسال السؤال',
                    // السهم يشير لليسار في الواجهة العربية
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ مكوّنات مساعدة ═════════════════════════

class _SafetyStrip extends StatelessWidget {
  const _SafetyStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.softGreen,
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF3F6B4E)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'إرشادات عامة للحج والعمرة. للفتوى راجعي جهة إفتاء معتمدة، وللطوارئ اتصلي 997.',
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: Color(0xFF2F4A39)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.green.withValues(alpha: .14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.green),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton(
      {required this.listening, required this.pulse, required this.onTap});
  final bool listening;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: listening ? 'إيقاف الاستماع' : 'اضغطي وتكلمي',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (listening)
                AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => Container(
                    width: 52 + 16 * pulse.value,
                    height: 52 + 16 * pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _danger.withValues(
                          alpha: .18 * (1 - pulse.value) + .08),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening ? _danger : AppColors.green,
                  border: Border.all(color: _gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (listening ? _danger : AppColors.green)
                          .withValues(alpha: .35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.msg,
    required this.speaking,
    required this.onSpeak,
    required this.onCopy,
    required this.onFeedback,
    required this.onShareLocation,
    required this.onCallCompanion,
  });

  final _Msg msg;
  final bool speaking;
  final VoidCallback onSpeak;
  final VoidCallback onCopy;
  final ValueChanged<int> onFeedback;
  final VoidCallback onShareLocation;
  final VoidCallback onCallCompanion;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final maxW = MediaQuery.sizeOf(context).width * .84;

    return Align(
      // في RTL: المستخدم على اليمين (start)، رفقة على اليسار (end)
      alignment: isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.green : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(isUser ? 4 : 18),
            bottomEnd: Radius.circular(isUser ? 18 : 4),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.green.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 17,
                height: 1.75,
                color: isUser ? Colors.white : _ink,
              ),
            ),
            if (msg.sos) ...[
              const SizedBox(height: 12),
              _SosButton(
                icon: Icons.group_rounded,
                label: 'شاركي موقعي مع المجموعة',
                onTap: onShareLocation,
              ),
              const SizedBox(height: 8),
              _SosButton(
                icon: Icons.phone_rounded,
                label: 'اتصلي بالمرافق',
                onTap: onCallCompanion,
              ),
              const SizedBox(height: 6),
              const Text(
                'مش هيتبعت أي حاجة غير لما تأكدي.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B756F)),
              ),
            ],
            if (!isUser) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniAction(
                    icon: speaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    label: speaking ? 'إيقاف' : 'اسمعي الرد',
                    onTap: onSpeak,
                    highlighted: speaking,
                  ),
                  _MiniIcon(
                      icon: Icons.copy_rounded, tooltip: 'نسخ', onTap: onCopy),
                  if (msg.fromAi) ...[
                    _MiniIcon(
                      icon: msg.feedback == 1
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_alt_outlined,
                      tooltip: 'مفيد',
                      active: msg.feedback == 1,
                      onTap: () => onFeedback(1),
                    ),
                    _MiniIcon(
                      icon: msg.feedback == -1
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_alt_outlined,
                      tooltip: 'غير مفيد',
                      active: msg.feedback == -1,
                      onTap: () => onFeedback(-1),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _danger,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: highlighted ? _danger : AppColors.green,
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon,
          size: 19, color: active ? AppColors.green : const Color(0xFF8A948E)),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.green.withValues(alpha: .12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('رفقة بتكتب',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B756F))),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Row(
                children: List.generate(3, (i) {
                  final t = ((_c.value + i * .2) % 1.0);
                  final o = (t < .5 ? t : 1 - t) * 2; // 0..1..0
                  return Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withValues(alpha: .25 + .6 * o),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
