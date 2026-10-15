import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/theme/app_colors.dart';
import '../../services/groups/group_service.dart';
import 'groups_screen.dart' show friendlyError, softOf, mutedOf, isDark, PulseDot, scaffoldOf;

String _fmt(int ms) {
  final s = (ms / 1000).round();
  return '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ------------------------------------------------------------ media cache
class MediaCache {
  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> load(
    String gid,
    String mediaId, {
    Future<Uint8List> Function()? loader,
  }) {
    final key = '$gid/$mediaId';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length > 40) _cache.remove(_cache.keys.first);
    final f = loader?.call() ?? GroupService.instance.fetchMedia(gid, mediaId);
    _cache[key] = f;
    f.catchError((_) {
      _cache.remove(key);
      return Uint8List(0);
    });
    return f;
  }
}

// ------------------------------------------------------------ image bubble
class ImageMessage extends StatefulWidget {
  final String groupId;
  final String mediaId;
  final Future<Uint8List> Function()? loadBytes;
  const ImageMessage({
    super.key,
    required this.groupId,
    required this.mediaId,
    this.loadBytes,
  });
  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  late Future<Uint8List> future = MediaCache.load(
    widget.groupId,
    widget.mediaId,
    loader: widget.loadBytes,
  );

  void retry() => setState(() {
        future = MediaCache.load(
          widget.groupId,
          widget.mediaId,
          loader: widget.loadBytes,
        );
      });

  Widget box(BuildContext context, Widget child) => Container(
        width: 230,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark(context) ? Colors.white10 : const Color(0xFFE9EEEB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  void open(Uint8List bytes) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(children: [
          Positioned.fill(
            child: Hero(
              tag: 'img_${widget.groupId}_${widget.mediaId}',
              child: InteractiveViewer(
                  minScale: 1, maxScale: 5, child: Center(child: Image.memory(bytes))),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, s) {
        if (s.hasError) {
          return InkWell(
            onTap: retry,
            borderRadius: BorderRadius.circular(16),
            child: box(
              context,
              Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.broken_image_outlined, color: mutedOf(context)),
                const SizedBox(height: 6),
                Text('تعذر التحميل · اضغط للإعادة',
                    style: TextStyle(fontSize: 12, color: mutedOf(context))),
              ]),
            ),
          );
        }
        if (!s.hasData) {
          return box(context, const CircularProgressIndicator(strokeWidth: 2, color: AppColors.green));
        }
        final bytes = s.data!;
        return GestureDetector(
          onTap: () => open(bytes),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'img_${widget.groupId}_${widget.mediaId}',
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .1), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Image.memory(bytes, width: 230, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ voice bubble (waveform style)
List<double> _waveformFor(String seed) {
  // ارتفاعات ثابتة مشتقة من معرّف الرسالة، لتبدو كموجة صوتية حقيقية
  // بدون الحاجة لتحليل الملف الصوتي فعليًا.
  final rnd = Random(seed.isEmpty ? 1 : seed.codeUnits.fold<int>(0, (a, b) => a + b));
  return List.generate(28, (_) => 0.28 + rnd.nextDouble() * 0.72);
}

class VoiceMessage extends StatefulWidget {
  final String groupId;
  final String mediaId;
  final int durationMs;
  final bool mine;
  final Future<Uint8List> Function()? loadBytes;
  const VoiceMessage({
    super.key,
    required this.groupId,
    required this.mediaId,
    required this.durationMs,
    required this.mine,
    this.loadBytes,
  });
  @override
  State<VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> {
  static _VoiceMessageState? _active;
  AudioPlayer? _player;
  bool _loading = false;
  bool _playing = false;
  Duration _pos = Duration.zero;
  final List<StreamSubscription<dynamic>> _subs = [];
  late final List<double> _bars = _waveformFor(widget.mediaId);

  Future<void> _pause() async => _player?.pause();

  Future<void> _toggle() async {
    if (_loading) return;
    try {
      if (_player == null) {
        setState(() => _loading = true);
        final bytes = await MediaCache.load(
          widget.groupId,
          widget.mediaId,
          loader: widget.loadBytes,
        );
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/v_${widget.mediaId}.m4a');
        if (!await file.exists()) await file.writeAsBytes(bytes);
        final p = AudioPlayer();
        _subs.add(p.onPlayerStateChanged.listen((s) {
          if (mounted) setState(() => _playing = s == PlayerState.playing);
        }));
        _subs.add(p.onPositionChanged.listen((d) {
          if (mounted) setState(() => _pos = d);
        }));
        _subs.add(p.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _pos = Duration.zero;
              _playing = false;
            });
          }
        }));
        _player = p;
        if (_active != this) _active?._pause();
        _active = this;
        await p.play(DeviceFileSource(file.path));
        if (mounted) setState(() => _loading = false);
      } else if (_playing) {
        await _player!.pause();
      } else {
        if (_active != this) _active?._pause();
        _active = this;
        await _player!.resume();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر تشغيل الرسالة الصوتية')));
      }
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    if (_active == this) _active = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.mine ? Colors.white : AppColors.green;
    final track = widget.mine ? Colors.white38 : AppColors.green.withValues(alpha: .28);
    final total = widget.durationMs <= 0 ? 1 : widget.durationMs;
    final value = (_pos.inMilliseconds / total).clamp(0.0, 1.0);
    final playedBars = (value * _bars.length).round();
    return SizedBox(
      width: 220,
      child: Row(children: [
        InkWell(
          onTap: _toggle,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.mine ? Colors.white24 : softOf(context, AppColors.green, AppColors.softGreen),
              boxShadow: _playing
                  ? [BoxShadow(color: fg.withValues(alpha: .35), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: fg, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_bars.length, (i) {
                  final played = i < playedBars;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: .6),
                      height: 22 * _bars[i],
                      decoration: BoxDecoration(
                        color: played ? fg : track,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _playing || _pos > Duration.zero ? _fmt(_pos.inMilliseconds) : _fmt(widget.durationMs),
              style: TextStyle(fontSize: 11, color: widget.mine ? Colors.white70 : mutedOf(context)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ image preview
class _ImagePreviewSheet extends StatefulWidget {
  final Uint8List bytes;
  const _ImagePreviewSheet(this.bytes);
  @override
  State<_ImagePreviewSheet> createState() => _ImagePreviewSheetState();
}

class _ImagePreviewSheetState extends State<_ImagePreviewSheet> {
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.memory(widget.bytes, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: c,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'أضف تعليقًا (اختياري)',
            counterText: '',
            filled: true,
            fillColor: isDark(context) ? Colors.white10 : const Color(0xFFF3F5F3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenDark]),
              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context, c.text),
                child: const Center(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.send_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('إرسال الصورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ input bar
// التصميم: زر "+" دائري لإرفاق صورة على اليمين، حقل نص بداخله زر إيموجي،
// وزر إرسال دائري متدرج على اليسار — بنفس شكل شريط الكتابة في المرجع.
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool busy;
  final Future<void> Function(String text) onSendText;
  final Future<void> Function(Uint8List bytes, String caption) onSendImage;
  final Future<void> Function(Uint8List bytes, int durationMs) onSendVoice;
  final void Function(String message) onError;
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.busy,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onError,
  });
  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  bool _sending = false;
  bool _recording = false;
  bool _finishing = false;
  int _seconds = 0;
  DateTime? _started;
  String? _path;
  Timer? _timer;

  static const _maxSeconds = 60;
  static const _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😊', '🥰', '😍',
    '😘', '😋', '😎', '🤗', '🤔', '😭', '😂', '🤣',
    '🙂', '🙃', '😉', '😇', '🙏', '🤲', '💚', '❤️',
    '👍', '👏', '✨', '🌹', '🕋', '🤍', '💐', '🌙',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() fn) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await fn();
    } catch (e) {
      widget.onError(friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText() async {
    final t = widget.controller.text.trim();
    if (t.isEmpty) return;
    await _guard(() async {
      await widget.onSendText(t);
      widget.controller.clear();
    });
  }

  Future<void> _pickEmoji() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 280,
          child: GridView.count(
            crossAxisCount: 8,
            children: [
              for (final emoji in _emojis)
                IconButton(
                  tooltip: emoji,
                  onPressed: () => Navigator.pop(context, emoji),
                  icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
        ),
      ),
    );
    if (emoji == null) return;

    final value = widget.controller.value;
    final start = value.selection.start < 0 ? value.text.length : value.selection.start;
    final end = value.selection.end < 0 ? start : value.selection.end;
    final text = value.text.replaceRange(start, end, emoji);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  // ---- images
  void _attachSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: softOf(ctx, AppColors.green, AppColors.softGreen),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.photo_camera_outlined, color: AppColors.green),
            ),
            title: const Text('التقاط صورة', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: softOf(ctx, AppColors.green, AppColors.softGreen),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.photo_library_outlined, color: AppColors.green),
            ),
            title: const Text('اختيار من المعرض', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
          source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 60);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      final caption = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ImagePreviewSheet(bytes),
      );
      if (caption == null) return;
      await _guard(() => widget.onSendImage(bytes, caption));
    } catch (e) {
      widget.onError(friendlyError(e));
    }
  }

  // ---- voice
  Future<void> _startRecording() async {
    if (_sending || widget.busy) return;
    try {
      if (!await _recorder.hasPermission()) {
        widget.onError('اسمح للتطبيق باستخدام الميكروفون من إعدادات الجهاز');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc, bitRate: 24000, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      _path = path;
      _started = DateTime.now();
      _seconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) _finishRecording(send: true);
      });
      setState(() => _recording = true);
    } catch (e) {
      widget.onError('تعذر بدء التسجيل');
    }
  }

  Future<void> _finishRecording({required bool send}) async {
    if (_finishing || !_recording) return;
    _finishing = true;
    _timer?.cancel();
    try {
      final stopped = await _recorder.stop();
      final path = stopped ?? _path;
      final ms = DateTime.now().difference(_started ?? DateTime.now()).inMilliseconds;
      if (mounted) setState(() => _recording = false);
      if (path == null) return;
      final file = File(path);
      if (!send) {
        if (await file.exists()) await file.delete();
        return;
      }
      if (ms < 800) {
        widget.onError('التسجيل قصير جدًا');
        if (await file.exists()) await file.delete();
        return;
      }
      final bytes = await file.readAsBytes();
      if (await file.exists()) await file.delete();
      await _guard(() => widget.onSendVoice(bytes, ms));
    } catch (e) {
      if (mounted) setState(() => _recording = false);
      widget.onError('تعذر إرسال التسجيل');
    } finally {
      _finishing = false;
    }
  }

  // ---- ui
  Widget _circleButton({required IconData icon, required VoidCallback? onTap, Color? color, double size = 46}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: onTap == null
            ? null
            : LinearGradient(colors: [color ?? AppColors.green, (color ?? AppColors.green).withValues(alpha: .8)]),
        color: onTap == null ? Colors.grey : null,
        boxShadow: onTap == null
            ? null
            : [BoxShadow(color: (color ?? AppColors.green).withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(children: [
          IconButton(
            tooltip: 'إلغاء',
            onPressed: () => _finishRecording(send: false),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: softOf(context, AppColors.red, AppColors.softRed),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(children: [
                const PulseDot(color: AppColors.red, size: 10),
                const SizedBox(width: 10),
                Text('جاري التسجيل  ${_fmt(_seconds * 1000)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.red)),
                const Spacer(),
                Text('الحد $_maxSecondsث',
                    style: TextStyle(fontSize: 11, color: mutedOf(context))),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          _circleButton(icon: Icons.send_rounded, onTap: () => _finishRecording(send: true)),
        ]),
      );
    }

    final disabled = widget.busy || _sending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // زر "+" دائري لإرفاق صورة (يطابق زر الإضافة في التصميم المرجعي)
        _circleButton(
          icon: Icons.add_rounded,
          onTap: disabled ? null : _attachSheet,
          color: isDark(context) ? Colors.white24 : const Color(0xFFBFC6C2),
          size: 42,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: isDark(context) ? Colors.white10 : const Color(0xFFF3F5F3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  maxLength: 2000,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'إيموجي',
                onPressed: disabled ? null : _pickEmoji,
                icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.green, size: 21),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        if (_sending)
          const SizedBox(
            width: 46,
            height: 46,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green),
            ),
          )
        else
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, v, _) {
              final hasText = v.text.trim().isNotEmpty;
              return _circleButton(
                icon: hasText ? Icons.send_rounded : Icons.mic_rounded,
                onTap: widget.busy ? null : (hasText ? _sendText : _startRecording),
              );
            },
          ),
      ]),
    );
  }
}