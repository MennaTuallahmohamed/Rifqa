import 'package:flutter/material.dart';

import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';

import 'add_dua_screen.dart';
import 'amanat_screen.dart';
import 'dua_details_screen.dart';
import 'my_duas_screen.dart';

import 'widgets/dua_card.dart';
import 'widgets/dua_category_card.dart';

enum _Quick {
  all,
  favorites,
  mine,
  quran,
  sunnah,
}

class DuasScreen extends StatefulWidget {
  const DuasScreen({
    super.key,
    required this.repository,
  });

  final DuasRepository repository;

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  final TextEditingController _controller = TextEditingController();

  DuaCategory? _category;

  _Quick _quick = _Quick.all;

  // =========================================================
  // Lifecycle
  // =========================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================================================
  // Navigation
  // =========================================================

  void _openDua(Dua dua) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuaDetailsScreen(
          repository: widget.repository,
          duaId: dua.id,
        ),
      ),
    );
  }

  void _openMyDuas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyDuasScreen(
          repository: widget.repository,
        ),
      ),
    );
  }

  void _openAmanat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AmanatScreen(
          repository: widget.repository,
        ),
      ),
    );
  }

  void _openAddDua() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddDuaScreen(
          repository: widget.repository,
        ),
      ),
    );
  }

  // =========================================================
  // Search + Filters
  // =========================================================

  List<Dua> _results(DuasRepository repo) {
    return repo.search(
      query: _controller.text,
      category: _category,
      favoritesOnly: _quick == _Quick.favorites,
      mineOnly: _quick == _Quick.mine,
      sources: switch (_quick) {
        _Quick.quran => {
            DuaSourceType.quran,
          },
        _Quick.sunnah => {
            DuaSourceType.hadith,
          },
        _ => null,
      },
    );
  }

  void _setQuick(_Quick quick) {
    setState(() {
      _quick = quick;

      if (quick == _Quick.all) {
        _category = null;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
    });
  }

  void _resetFilters() {
    setState(() {
      _controller.clear();
      _category = null;
      _quick = _Quick.all;
    });
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الأدعية',
          ),
          actions: [
            IconButton(
              tooltip: 'أمانة الدعاء',
              onPressed: _openAmanat,
              icon: Badge(
                isLabelVisible: widget.repository.pendingAmanatCount > 0,
                label: Text(
                  widget.repository.pendingAmanatCount.toString(),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                ),
              ),
            ),
            IconButton(
              tooltip: 'أدعيتي',
              onPressed: _openMyDuas,
              icon: const Icon(
                Icons.menu_book_rounded,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddDua,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'دعاء جديد',
          ),
        ),
        body: ListenableBuilder(
          listenable: widget.repository,
          builder: (context, _) {
            final repo = widget.repository;

            if (!repo.isReady) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final browsing = _controller.text.trim().isEmpty &&
                _category == null &&
                _quick == _Quick.all;

            final results = browsing ? const <Dua>[] : _results(repo);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Search + filters
                SliverToBoxAdapter(
                  child: _header(),
                ),

                // Feature shortcuts
                if (browsing)
                  SliverToBoxAdapter(
                    child: _featureActions(repo),
                  ),

                // Normal browse mode
                if (browsing)
                  ..._browse(repo)

                // Search/filter results
                else
                  ..._list(
                    repo,
                    results,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // Header
  // =========================================================

  Widget _header() {
    Widget chip(
      String label,
      _Quick quick, {
      IconData? icon,
    }) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          end: 8,
        ),
        child: ChoiceChip(
          avatar: icon == null
              ? null
              : Icon(
                  icon,
                  size: 17,
                ),
          label: Text(label),
          selected: _quick == quick,
          onSelected: (_) {
            _setQuick(quick);
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _controller,
            onChanged: (_) {
              setState(() {});
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحثي في الأدعية...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  18,
                ),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  'الكل',
                  _Quick.all,
                  icon: Icons.apps_rounded,
                ),
                chip(
                  'المفضلة',
                  _Quick.favorites,
                  icon: Icons.favorite_rounded,
                ),
                chip(
                  'أدعيتي',
                  _Quick.mine,
                  icon: Icons.person_rounded,
                ),
                chip(
                  'من القرآن',
                  _Quick.quran,
                  icon: Icons.menu_book_rounded,
                ),
                chip(
                  'من السنة',
                  _Quick.sunnah,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
          ),

          if (_category != null) ...[
            const SizedBox(height: 8),
            InputChip(
              avatar: Text(
                _category!.emoji,
              ),
              label: Text(
                _category!.label,
              ),
              onDeleted: () {
                setState(() {
                  _category = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // Main Feature Buttons
  // =========================================================

  Widget _featureActions(
    DuasRepository repo,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FeatureButton(
                  icon: Icons.menu_book_rounded,
                  title: 'أدعيتي',
                  subtitle: repo.userDuas.isEmpty
                      ? 'ابدئي دفتر أدعيتك'
                      : '${repo.userDuas.length} دعاء محفوظ',
                  onTap: _openMyDuas,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeatureButton(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'أمانة الدعاء',
                  subtitle: repo.pendingAmanatCount == 0
                      ? 'سجّلي من طلب الدعاء'
                      : '${repo.pendingAmanatCount} في انتظار الدعاء',
                  badge: repo.pendingAmanatCount,
                  onTap: _openAmanat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openAddDua,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
              ),
              label: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 13,
                ),
                child: Text(
                  'أضيفي دعاءك الخاص',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Browse Mode
  // =========================================================

  List<Widget> _browse(
    DuasRepository repo,
  ) {
    final theme = Theme.of(context);

    final daily = repo.duaOfTheDay();

    return [
      // -------------------------------------------------------
      // Dua of the day
      // -------------------------------------------------------

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            8,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(
                24,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  24,
                ),
                onTap: () {
                  _openDua(daily);
                },
                child: Padding(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(
                                30,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 17,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'دعاء اليوم',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            daily.category.emoji,
                            style: const TextStyle(
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        daily.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        daily.arabicText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 2,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      Row(
                        children: [
                          if (daily.sourceType.isDocumented) ...[
                            Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                          ],
                          Expanded(
                            child: Text(
                              daily.sourceType.label,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_back_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // -------------------------------------------------------
      // Statistics
      // -------------------------------------------------------

      SliverToBoxAdapter(
        child: _statsRow(repo),
      ),

      // -------------------------------------------------------
      // Categories title
      // -------------------------------------------------------

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            10,
          ),
          child: Row(
            children: [
              Text(
                'التصنيفات',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${DuaCategory.values.length} تصنيف',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),

      // -------------------------------------------------------
      // Categories
      // -------------------------------------------------------

      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        sliver: SliverGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            for (final category in DuaCategory.values)
              DuaCategoryCard(
                category: category,
                count: repo.countIn(category),
                onTap: () {
                  setState(() {
                    _category = category;
                  });
                },
              ),
          ],
        ),
      ),

      // -------------------------------------------------------
      // Trust notice
      // -------------------------------------------------------

      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            16,
            22,
            16,
            100,
          ),
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المصدر أولًا',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'الأدعية الموثقة تُعرض مع مصدرها. أما الدعاء العام الجائز وأدعيتك الشخصية فيظهران بشكل منفصل حتى لا يختلطا بالنصوص المنقولة.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // =========================================================
  // Stats
  // =========================================================

  Widget _statsRow(
    DuasRepository repo,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              icon: Icons.library_books_rounded,
              value: repo.documented.length.toString(),
              label: 'دعاء',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniStat(
              icon: Icons.favorite_rounded,
              value: repo.favorites.length.toString(),
              label: 'مفضلة',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniStat(
              icon: Icons.person_rounded,
              value: repo.userDuas.length.toString(),
              label: 'أدعيتي',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Results
  // =========================================================

  List<Widget> _list(
    DuasRepository repo,
    List<Dua> results,
  ) {
    if (results.isEmpty) {
      final message = switch (_quick) {
        _Quick.favorites => 'لسه ما ضفتيش أدعية للمفضلة ❤️',
        _Quick.mine => 'قسم «أدعيتي» فاضي حاليًا.',
        _Quick.quran => 'مفيش أدعية قرآنية مطابقة للبحث.',
        _Quick.sunnah => 'مفيش أدعية من السنة مطابقة للبحث.',
        _ => 'مفيش نتائج مطابقة للبحث.',
      };

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyResults(
            message: message,
            showAddButton: _quick == _Quick.mine,
            onReset: _resetFilters,
            onAdd: _openAddDua,
          ),
        ),
      ];
    }

    return [
      // Result count
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            6,
          ),
          child: Row(
            children: [
              Text(
                '${results.length} نتيجة',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (_quick != _Quick.all ||
                  _category != null ||
                  _controller.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'مسح الفلاتر',
                  ),
                ),
            ],
          ),
        ),
      ),

      // Result cards
      SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final dua = results[index];

          return DuaCard(
            dua: dua,
            isFavorite: repo.isFavorite(dua.id),
            onTap: () {
              _openDua(dua);
            },
            onFavorite: () {
              repo.toggleFavorite(
                dua.id,
              );
            },
          );
        },
      ),

      const SliverToBoxAdapter(
        child: SizedBox(
          height: 110,
        ),
      ),
    ];
  }
}

// ===========================================================
// Feature Button
// ===========================================================

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (badge > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          50,
                        ),
                      ),
                      child: Text(
                        badge.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// Mini Statistics
// ===========================================================

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// Empty Results
// ===========================================================

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.message,
    required this.showAddButton,
    required this.onReset,
    required this.onAdd,
  });

  final String message;
  final bool showAddButton;

  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🤲',
                style: TextStyle(
                  fontSize: 38,
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(
              height: 18,
            ),
            if (showAddButton)
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text(
                  'أضيفي أول دعاء',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(
                  Icons.restart_alt_rounded,
                ),
                label: const Text(
                  'عرض كل الأدعية',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
