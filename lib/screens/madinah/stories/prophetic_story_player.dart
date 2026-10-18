import 'package:flutter/material.dart';

import '../../../models/madinah/prophetic_story.dart';

// ───────────────────────────────────────────────────────
// رِفقة · مُشغِّل الحكايات النبوية ﷺ
// ───────────────────────────────────────────────────────
// عرض سينمائي مشهدًا بمشهد (على غرار "Stories") لأي
// PropheticStory كما هي مخزّنة في المستودع. الودجت لا يضيف
// ولا يبدّل أي نص حديثي؛ هو فقط طبقة عرض فوق البيانات
// الموجودة أصلًا في PropheticStoriesRepository، مع احترام
// تمييز النص الموثّق (authenticText) عن الصياغة التحريرية،
// تمامًا كما يفرضه editorialNote في النموذج.
//
// الاستخدام المقترح من الشاشة المستضيفة:
//   PropheticStoryPlayer(
//     story: story,
//     backgroundAssets: [...], // صور مرتبطة بالحكاية، اختياري
//     onFinished: (id) => repository.markStoryRead(id),
//   )

const _night = Color(0xFF04130F);
const _emerald = Color(0xFF104B39);
const _gold = Color(0xFFC9A96E);

int _clampI(int v, int lo, int hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

class PropheticStoryPlayer extends StatefulWidget {
  const PropheticStoryPlayer({
    super.key,
    required this.story,
    this.backgroundAssets = const [],
    this.onFinished,
  });

  final PropheticStory story;

  /// صور خلفية اختيارية (صور حقيقية للمسجد النبوي أو المدينة)
  /// تتلاشى بين بعضها أثناء عرض المشاهد. يمكن تركها فارغة.
  final List<String> backgroundAssets;

  /// يُستدعى عند إغلاق المُشغِّل بعد الوصول إلى البطاقة
  /// الختامية — نقطة الاتصال المقترحة لاستدعاء
  /// MadinahRepository.markStoryRead(story.id).
  final ValueChanged<String>? onFinished;

  @override
  State<PropheticStoryPlayer> createState() => _PropheticStoryPlayerState();
}

class _PropheticStoryPlayerState extends State<PropheticStoryPlayer>
    with SingleTickerProviderStateMixin {
  late final List<PropheticStoryScene> _scenes = widget.story.scenes;
  late final AnimationController _progress = AnimationController(
    vsync: this,
  );

  int _index = 0;
  bool _paused = false;
  bool _showEndCard = false;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_handleStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrent());
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_handleStatus);
    _progress.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_paused) {
      _advance();
    }
  }

  Duration _durationFor(PropheticStoryScene scene) {
    final int ms = _clampI(scene.text.length * 55, 3200, 9500);
    return Duration(milliseconds: ms);
  }

  void _playCurrent() {
    if (!mounted || _scenes.isEmpty) {
      if (mounted) setState(() => _showEndCard = true);
      return;
    }
    _progress
      ..stop()
      ..duration = _durationFor(_scenes[_index])
      ..value = 0.0;
    if (!_paused) _progress.forward();
  }

  void _advance() {
    if (_index >= _scenes.length - 1) {
      setState(() => _showEndCard = true);
      return;
    }
    setState(() => _index += 1);
    _playCurrent();
  }

  void _retreat() {
    if (_showEndCard) {
      setState(() => _showEndCard = false);
      _playCurrent();
      return;
    }
    if (_index == 0) {
      _playCurrent();
      return;
    }
    setState(() => _index -= 1);
    _playCurrent();
  }

  void _togglePause(bool paused) {
    if (!mounted || _showEndCard) return;
    setState(() => _paused = paused);
    if (paused) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  void _finish() {
    widget.onFinished?.call(widget.story.id);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC04130F), Color(0xF2041009)],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _progressBars(),
                  const SizedBox(height: 8),
                  _topBar(),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (_) => _togglePause(true),
                      onLongPressEnd: (_) => _togglePause(false),
                      onTapUp: (details) {
                        final double width = MediaQuery.sizeOf(context).width;
                        final bool tappedRightHalf =
                            details.globalPosition.dx > width / 2;
                        // المحتوى عربي (RTL): اليمين = رجوع، اليسار = تقدّم.
                        if (tappedRightHalf) {
                          _retreat();
                        } else {
                          _advance();
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: (_showEndCard || _scenes.isEmpty)
                            ? _EndCard(
                                key: const ValueKey('end'),
                                story: widget.story,
                                onFinish: _finish,
                              )
                            : _SceneView(
                                key: ValueKey(_scenes[_index].id),
                                scene: _scenes[_index],
                              ),
                      ),
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

  Widget _background() {
    if (widget.backgroundAssets.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_emerald, _night],
          ),
        ),
      );
    }

    final int safeIndex = _clampI(_index, 0, widget.backgroundAssets.length - 1);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      child: Image.asset(
        widget.backgroundAssets[safeIndex],
        key: ValueKey(safeIndex),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(color: _emerald);
        },
      ),
    );
  }

  Widget _progressBars() {
    if (_scenes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: List.generate(_scenes.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 3,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      double value = 0.0;
                      if (_showEndCard || i < _index) {
                        value = 1.0;
                      } else if (i == _index) {
                        value = _progress.value;
                      }
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Scene view — تنسيق مختلف حسب نوع المشهد
// ───────────────────────────────────────────────────────

class _SceneView extends StatelessWidget {
  const _SceneView({super.key, required this.scene});

  final PropheticStoryScene scene;

  @override
  Widget build(BuildContext context) {
    final String typeName = scene.type.name;

    if (typeName == 'authenticText') {
      return _AuthenticTextScene(scene: scene);
    }
    if (typeName == 'opening') {
      return _OpeningScene(scene: scene);
    }
    if (typeName == 'reflection') {
      return _ReflectionScene(scene: scene);
    }
    // narrative, takeaway، وأي نوع مستقبلي غير معروف:
    return _NarrativeScene(scene: scene);
  }
}

class _OpeningScene extends StatelessWidget {
  const _OpeningScene({required this.scene});
  final PropheticStoryScene scene;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          scene.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            height: 1.9,
          ),
        ),
      ),
    );
  }
}

class _NarrativeScene extends StatelessWidget {
  const _NarrativeScene({required this.scene});
  final PropheticStoryScene scene;

  @override
  Widget build(BuildContext context) {
    final String? title = scene.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            scene.text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.85,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionScene extends StatelessWidget {
  const _ReflectionScene({required this.scene});
  final PropheticStoryScene scene;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, color: _gold, size: 24),
            const SizedBox(height: 16),
            Text(
              scene.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontStyle: FontStyle.italic,
                height: 1.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة النص الموثّق — تُميَّز بصريًا بوضوح عن أي صياغة
/// تحريرية، تمامًا كما يشترط النموذج (editorialNote).
class _AuthenticTextScene extends StatelessWidget {
  const _AuthenticTextScene({required this.scene});
  final PropheticStoryScene scene;

  @override
  Widget build(BuildContext context) {
    final String? title = scene.title;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gold.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, color: _gold, size: 20),
              const SizedBox(height: 12),
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                scene.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// End card — المصدر، وقفة التدبر، والقيم المقترحة
// ───────────────────────────────────────────────────────

class _EndCard extends StatelessWidget {
  const _EndCard({super.key, required this.story, required this.onFinish});

  final PropheticStory story;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final String sourceName = story.sourceName ?? '';
    final String sourceReference = story.sourceReference ?? '';
    final String editorialNote = story.editorialNote ?? '';
    final String reflectionQuestion = story.reflectionQuestion ?? '';
    final List<String> values = story.suggestedValues;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          if (sourceName.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded, color: _gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sourceReference.isEmpty
                          ? sourceName
                          : '$sourceName · $sourceReference',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (editorialNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              editorialNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10.5,
                height: 1.6,
              ),
            ),
          ],
          if (reflectionQuestion.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text('✦', style: TextStyle(color: _gold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              reflectionQuestion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.8,
              ),
            ),
          ],
          if (values.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: values.map((value) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(color: _gold, fontSize: 11.5),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton(
            onPressed: onFinish,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _night,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'تم القراءة، جزاكِ الله خيرًا',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
