import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/dua_model.dart';
import '../../services/duas/duas_audio_service.dart';
import '../../services/duas/duas_repository.dart';

class DuaPrayerModeScreen extends StatefulWidget {
  const DuaPrayerModeScreen({
    super.key,
    required this.repository,
    required this.duas,
    required this.initialIndex,
  });

  final DuasRepository repository;
  final List<Dua> duas;
  final int initialIndex;

  @override
  State<DuaPrayerModeScreen> createState() => _DuaPrayerModeScreenState();
}

class _DuaPrayerModeScreenState extends State<DuaPrayerModeScreen> {
  late final PageController _pageController;
  late final DuasAudioService _audio;

  late int _index;

  final Map<String, int> _counters = {};

  bool _controlsVisible = true;

  Dua get current => widget.duas[_index];

  int get counter => _counters[current.id] ?? 0;

  int get target => current.repeatCount;

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex.clamp(
      0,
      widget.duas.length - 1,
    );

    _pageController = PageController(
      initialPage: _index,
    );

    _audio = DuasAudioService();

    WakelockPlus.enable();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    _pageController.dispose();
    _audio.dispose();

    super.dispose();
  }

  void _increment() {
    final value = counter;

    if (value >= target) {
      HapticFeedback.mediumImpact();
      return;
    }

    final next = value + 1;

    setState(() {
      _counters[current.id] = next;
    });

    HapticFeedback.selectionClick();

    if (next == target) {
      HapticFeedback.heavyImpact();
    }
  }

  void _resetCounter() {
    setState(() {
      _counters[current.id] = 0;
    });

    HapticFeedback.lightImpact();
  }

  void _next() {
    if (_index >= widget.duas.length - 1) {
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_index <= 0) {
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _toggleAudio() async {
    if (_audio.isPlaying) {
      await _audio.stop();
    } else {
      await _audio.speak(current.arabicText);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _controlsVisible = !_controlsVisible;
              });
            },
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.duas.length,
                  onPageChanged: (value) async {
                    await _audio.stop();

                    setState(() {
                      _index = value;
                    });

                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, index) {
                    return _PrayerPage(
                      dua: widget.duas[index],
                      fontScale: widget.repository.fontScale,
                    );
                  },
                ),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _TopBar(
                        index: _index,
                        count: widget.duas.length,
                        favorite: widget.repository.isFavorite(
                          current.id,
                        ),
                        onClose: () => Navigator.pop(context),
                        onFavorite: () {
                          widget.repository.toggleFavorite(
                            current.id,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _BottomControls(
                        current: counter,
                        target: target,
                        playing: _audio.isPlaying,
                        canPrevious: _index > 0,
                        canNext: _index < widget.duas.length - 1,
                        onIncrement: _increment,
                        onReset: _resetCounter,
                        onPrevious: _previous,
                        onNext: _next,
                        onAudio: _toggleAudio,
                        onSmaller: () {
                          widget.repository.setFontScale(
                            widget.repository.fontScale - 0.1,
                          );
                          setState(() {});
                        },
                        onLarger: () {
                          widget.repository.setFontScale(
                            widget.repository.fontScale + 0.1,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerPage extends StatelessWidget {
  const _PrayerPage({
    required this.dua,
    required this.fontScale,
  });

  final Dua dua;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        110,
        28,
        210,
      ),
      child: Column(
        children: [
          Text(
            '${dua.category.emoji} ${dua.title}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dua.sourceType.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  dua.arabicText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30 * fontScale,
                    height: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (dua.reference.trim().isNotEmpty)
            Text(
              dua.reference,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.count,
    required this.favorite,
    required this.onClose,
    required this.onFavorite,
  });

  final int index;
  final int count;
  final bool favorite;

  final VoidCallback onClose;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '${index + 1} / $count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: onFavorite,
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.current,
    required this.target,
    required this.playing,
    required this.canPrevious,
    required this.canNext,
    required this.onIncrement,
    required this.onReset,
    required this.onPrevious,
    required this.onNext,
    required this.onAudio,
    required this.onSmaller,
    required this.onLarger,
  });

  final int current;
  final int target;

  final bool playing;
  final bool canPrevious;
  final bool canNext;

  final VoidCallback onIncrement;
  final VoidCallback onReset;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAudio;
  final VoidCallback onSmaller;
  final VoidCallback onLarger;

  @override
  Widget build(BuildContext context) {
    final done = current >= target;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 8),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onSmaller,
                icon: const Icon(Icons.text_decrease_rounded),
              ),
              IconButton.filledTonal(
                onPressed: onAudio,
                icon: Icon(
                  playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                ),
              ),
              IconButton(
                onPressed: onLarger,
                icon: const Icon(Icons.text_increase_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (target > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onIncrement,
                  icon: Icon(
                    done ? Icons.check_rounded : Icons.touch_app_rounded,
                  ),
                  label: Text(
                    done ? 'تم $target / $target' : '$current / $target',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canPrevious ? onPrevious : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canNext ? onNext : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('التالي'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
