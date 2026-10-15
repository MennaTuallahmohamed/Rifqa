import 'package:flutter/material.dart';

import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'add_dua_screen.dart';
import 'dua_details_screen.dart';

class MyDuasScreen extends StatelessWidget {
  const MyDuasScreen({
    super.key,
    required this.repository,
  });

  final DuasRepository repository;

  Future<void> _delete(
    BuildContext context,
    Dua dua,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف الدعاء؟',
          ),
          content: Text(
            'هل تريدين حذف «${dua.title}» من أدعيتك؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await repository.deleteUserDua(
      dua.id,
    );
  }

  void _open(
    BuildContext context,
    Dua dua,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuaDetailsScreen(
          repository: repository,
          duaId: dua.id,
        ),
      ),
    );
  }

  void _edit(
    BuildContext context,
    Dua dua,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDuaScreen(
          repository: repository,
          dua: dua,
        ),
      ),
    );
  }

  void _add(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDuaScreen(
          repository: repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final duas = repository.userDuas;

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'أدعيتي',
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'دعاء جديد',
              ),
            ),
            body: duas.isEmpty
                ? _EmptyState(
                    onAdd: () => _add(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      100,
                    ),
                    itemCount: duas.length,
                    itemBuilder: (context, index) {
                      final dua = duas[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                          onTap: () => _open(
                            context,
                            dua,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        dua.category.emoji,
                                        style: const TextStyle(
                                          fontSize: 21,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Text(
                                        dua.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _edit(
                                            context,
                                            dua,
                                          );
                                        }

                                        if (value == 'delete') {
                                          _delete(
                                            context,
                                            dua,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            'تعديل',
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'حذف',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  dua.arabicText,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        height: 1.8,
                                      ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Chip(
                                      label: const Text(
                                        'من أدعيتي',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Chip(
                                      label: Text(
                                        dua.category.label,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🤲',
              style: TextStyle(
                fontSize: 64,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'دفتر أدعيتك',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'احتفظي بالأدعية الخاصة بك لتكون معك طوال الرحلة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'أضيفي أول دعاء',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
