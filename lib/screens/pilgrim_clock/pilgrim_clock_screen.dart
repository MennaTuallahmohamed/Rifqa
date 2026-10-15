import 'dart:async';
import '../../services/pilgrim_clock/pilgrim_alarm_service.dart';
import 'package:flutter/material.dart';

class PilgrimClockScreen extends StatefulWidget {
  const PilgrimClockScreen({super.key});

  @override
  State<PilgrimClockScreen> createState() =>
      _PilgrimClockScreenState();
}

class _PilgrimClockScreenState extends State<PilgrimClockScreen> {
  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  Timer? _timer;

  DateTime _now = DateTime.now();

  int _selectedTab = 0;

  int _tawafCount = 0;
  int _saiCount = 0;
  int _tasbeehCount = 0;

  String _selectedDhikr = 'سبحان الله';

  final List<String> _adhkar = const [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
    'لبيك اللهم لبيك',
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _makkahTime {
    final utc = _now.toUtc();

    // Saudi Arabia uses UTC+3 throughout the year.
    return utc.add(
      const Duration(hours: 3),
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatClock(
    DateTime dateTime, {
    bool seconds = true,
  }) {
    final hour = _twoDigits(dateTime.hour);
    final minute = _twoDigits(dateTime.minute);

    if (!seconds) {
      return '$hour:$minute';
    }

    final second = _twoDigits(dateTime.second);

    return '$hour:$minute:$second';
  }

  String _weekdayArabic(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الاثنين';

      case DateTime.tuesday:
        return 'الثلاثاء';

      case DateTime.wednesday:
        return 'الأربعاء';

      case DateTime.thursday:
        return 'الخميس';

      case DateTime.friday:
        return 'الجمعة';

      case DateTime.saturday:
        return 'السبت';

      case DateTime.sunday:
        return 'الأحد';

      default:
        return '';
    }
  }

  String _gregorianDate(DateTime date) {
    return '${_weekdayArabic(date.weekday)}، '
        '${date.day}/${date.month}/${date.year}';
  }

  void _incrementTawaf() {
    if (_tawafCount >= 7) {
      return;
    }

    setState(() {
      _tawafCount++;
    });
  }

  void _incrementSai() {
    if (_saiCount >= 7) {
      return;
    }

    setState(() {
      _saiCount++;
    });
  }

  String get _saiDirection {
    if (_saiCount >= 7) {
      return 'تم إكمال 7 أشواط';
    }

    if (_saiCount.isEven) {
      return 'الشوط القادم: من الصفا إلى المروة';
    }

    return 'الشوط القادم: من المروة إلى الصفا';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _greenDark,
        title: const Text(
          'ساعة المعتمر والحاج',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  30,
                ),
                children: [
                  _buildClockHero(),

                  const SizedBox(height: 16),

                  _buildTabs(),

                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 220,
                    ),
                    child: _buildSelectedTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockHero() {
    final makkah = _makkahTime;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _green,
            _greenDark,
          ],
        ),
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                _greenDark.withValues(
              alpha: 0.20,
            ),
            blurRadius: 22,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _gregorianDate(makkah),
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.82,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 9),

          Directionality(
            textDirection:
                TextDirection.ltr,
            child: Text(
              _formatClock(makkah),
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 43,
                height: 1,
                letterSpacing: 1.2,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .location_on_outlined,
                color: _gold,
                size: 17,
              ),
              SizedBox(width: 5),
              Text(
                'بتوقيت مكة المكرمة',
                style: TextStyle(
                  color:
                      Color(0xFFE7F1ED),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _heroInfoBox(
                  icon:
                      Icons.access_time_rounded,
                  title:
                      'توقيتك المحلي',
                  value:
                      _formatClock(
                    _now,
                    seconds: false,
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _heroInfoBox(
                  icon:
                      Icons.mosque_outlined,
                  title:
                      'الصلاة القادمة',
                  value: 'قريبًا',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              border: Border.all(
                color:
                    Colors.white.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .verified_outlined,
                  color: _gold,
                  size: 17,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'مواقيت الصلاة ستُعرض بعد ربط مصدر موثوق',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Color(
                        0xFFE7F1ED,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroInfoBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _gold,
                size: 15,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFFE7F1ED,
                    ),
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Directionality(
            textDirection:
                TextDirection.ltr,
            child: Text(
              value,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      (
        icon: Icons.alarm_rounded,
        label: 'المنبه',
      ),
      (
        icon: Icons.mosque_rounded,
        label: 'العمرة',
      ),
      (
        icon:
            Icons.calendar_month_rounded,
        label: 'الحج',
      ),
      (
        icon:
            Icons.exposure_plus_1_rounded,
        label: 'عداد',
      ),
    ];

    return Container(
      padding:
          const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children:
            List.generate(
          tabs.length,
          (index) {
            final selected =
                _selectedTab ==
                    index;

            final tab =
                tabs[index];

            return Expanded(
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 2,
                ),
                child: InkWell(
                  borderRadius:
                      BorderRadius
                          .circular(
                    13,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTab =
                          index;
                    });
                  },
                  child:
                      AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds:
                          180,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 10,
                      horizontal: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? _green
                          : Colors
                              .transparent,
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          tab.icon,
                          size: 18,
                          color: selected
                              ? Colors
                                  .white
                              : _muted,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          tab.label,
                          style:
                              TextStyle(
                            color: selected
                                ? Colors
                                    .white
                                : _ink,
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case 0:
        return _buildAlarmTab();

      case 1:
        return _buildUmrahTab();

      case 2:
        return _buildHajjTab();

      case 3:
        return _buildCountersTab();

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _testAlarm() async {
    try {
      final granted =
          await PilgrimAlarmService.instance.requestPermissions();

      if (!mounted) {
        return;
      }

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لازم تسمحي بإشعارات رِفقة علشان المنبه يشتغل.',
            ),
          ),
        );

        return;
      }

      await PilgrimAlarmService.instance.scheduleTestAlarm(
        seconds: 5,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم ضبط منبه تجريبي بعد 5 ثواني ⏰',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تشغيل المنبه: $error',
          ),
        ),
      );
    }
  }

  Widget _buildAlarmTab() {
    return Column(
      key: const ValueKey('alarm'),
      children: [
        _sectionCard(
          icon: Icons.notifications_active_outlined,
          title: 'منبه المعتمر والحاج',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'يمكنك استخدام منبهات رِفقة للتذكير بالمواعيد المهمة أثناء العمرة والحج.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _testAlarm,
                icon: const Icon(
                  Icons.alarm_on_rounded,
                ),
                label: const Text(
                  'تجربة المنبه بعد 5 ثواني',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'في أول مرة قد يطلب الهاتف السماح بالإشعارات والمنبهات الدقيقة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUmrahTab() {
    return Column(
      key:
          const ValueKey('umrah'),
      children: [
        _sectionCard(
          icon:
              Icons.mosque_outlined,
          title: 'متابعة العمرة',
          child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'هنا هنضيف متابعة خطوات العمرة مع حفظ التقدم على الجهاز.',
                textAlign:
                    TextAlign.right,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 12),
              _ComingSoonBox(
                text:
                    'متابعة الخطوات ستُضاف في المرحلة التالية',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHajjTab() {
    return Column(
      key:
          const ValueKey('hajj'),
      children: [
        _sectionCard(
          icon: Icons
              .calendar_month_outlined,
          title:
              'برنامج أيام الحج',
          child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'سيظهر هنا برنامج أيام الحج بعد مراجعة المحتوى الديني واعتماده.',
                textAlign:
                    TextAlign.right,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 12),
              _ComingSoonBox(
                text:
                    'لن نعرض إرشادات دينية غير مراجعة',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountersTab() {
    return Column(
      key:
          const ValueKey('counter'),
      children: [
        _buildRoundCounter(
          title:
              'عداد أشواط الطواف',
          icon:
              Icons.rotate_right_rounded,
          count: _tawafCount,
          onAdd: _incrementTawaf,
          onReset: () {
            setState(() {
              _tawafCount = 0;
            });
          },
        ),

        const SizedBox(height: 12),

        _buildRoundCounter(
          title:
              'عداد أشواط السعي',
          icon:
              Icons.directions_walk_rounded,
          count: _saiCount,
          helper: _saiDirection,
          onAdd: _incrementSai,
          onReset: () {
            setState(() {
              _saiCount = 0;
            });
          },
        ),

        const SizedBox(height: 12),

        _buildTasbeeh(),
      ],
    );
  }

  Widget _buildRoundCounter({
    required String title,
    required IconData icon,
    required int count,
    required VoidCallback onAdd,
    required VoidCallback onReset,
    String? helper,
  }) {
    return _sectionCard(
      icon: icon,
      title: title,
      child: Column(
        children: [
          Text(
            '$count',
            style:
                const TextStyle(
              color: _green,
              fontSize: 54,
              height: 1,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 13),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children:
                List.generate(
              7,
              (index) {
                final active =
                    index < count;

                return Container(
                  width: 14,
                  height: 14,
                  margin:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color: active
                        ? _gold
                        : _border,
                  ),
                );
              },
            ),
          ),

          if (helper != null) ...[
            const SizedBox(
              height: 12,
            ),
            Text(
              helper,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      onReset,
                  icon:
                      const Icon(
                    Icons
                        .restart_alt_rounded,
                  ),
                  label:
                      const Text(
                    'صفر',
                  ),
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        _green,
                    side:
                        const BorderSide(
                      color: _border,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                flex: 2,
                child:
                    FilledButton.icon(
                  onPressed:
                      count < 7
                          ? onAdd
                          : null,
                  icon:
                      const Icon(
                    Icons.add_rounded,
                  ),
                  label: Text(
                    count >= 7
                        ? 'تمت 7 أشواط'
                        : 'إضافة شوط',
                  ),
                  style:
                      FilledButton
                          .styleFrom(
                    backgroundColor:
                        _green,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasbeeh() {
    return _sectionCard(
      icon:
          Icons.touch_app_outlined,
      title: 'المسبحة',
      child: Column(
        children: [
          DropdownButtonFormField<
              String>(
            initialValue:
                _selectedDhikr,
            isExpanded: true,
            decoration:
                InputDecoration(
              labelText:
                  'الذكر',
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
            ),
            items: _adhkar
                .map(
                  (dhikr) =>
                      DropdownMenuItem<
                          String>(
                    value: dhikr,
                    child: Text(
                      dhikr,
                      textAlign:
                          TextAlign.right,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedDhikr =
                    value;
              });
            },
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              setState(() {
                _tasbeehCount++;
              });
            },
            child: Container(
              width: 155,
              height: 155,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white,
                border: Border.all(
                  color: _gold,
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        _gold.withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 20,
                    offset:
                        const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),
              alignment:
                  Alignment.center,
              child: Text(
                '$_tasbeehCount',
                style:
                    const TextStyle(
                  color: _green,
                  fontSize: 42,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _selectedDhikr,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: () {
              setState(() {
                _tasbeehCount = 0;
              });
            },
            icon: const Icon(
              Icons
                  .restart_alt_rounded,
            ),
            label:
                const Text(
              'تصفير العداد',
            ),
            style:
                TextButton.styleFrom(
              foregroundColor:
                  _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(
                width: 9,
              ),
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      _green.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _green,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

class _ComingSoonBox
    extends StatelessWidget {
  const _ComingSoonBox({
    required this.text,
  });

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFF176B52)
                .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFF176B52)
                  .withValues(
            alpha: 0.13,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: SizedBox(),
          ),
          Flexible(
            flex: 8,
            child: Text(
              text,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    Color(0xFF6B7B74),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons
                .construction_rounded,
            color:
                Color(0xFFD5AE5B),
            size: 18,
          ),
        ],
      ),
    );
  }
}