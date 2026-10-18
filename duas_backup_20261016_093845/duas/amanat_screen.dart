import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/dua_request_model.dart';
import '../../services/duas/duas_repository.dart';

class AmanatScreen extends StatelessWidget {
  const AmanatScreen({
    super.key,
    required this.repository,
  });

  final DuasRepository repository;

  Future<void> _showEditor(
    BuildContext context, {
    DuaRequest? existing,
  }) async {
    final name = TextEditingController(
      text: existing?.personName ?? '',
    );

    final request = TextEditingController(
      text: existing?.request ?? '',
    );

    final note = TextEditingController(
      text: existing?.note ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(
                    sheetContext,
                  ).viewInsets.bottom +
                  20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? 'أمانة دعاء جديدة ❤️'
                          : 'تعديل أمانة الدعاء',
                      style:
                          Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(
                          Icons.person_outline,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اكتبي الاسم';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      controller: request,
                      minLines: 3,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'طلب الدعاء',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اكتبي طلب الدعاء';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: note,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة اختيارية',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.favorite_rounded,
                      ),
                      label: const Text(
                        'حفظ الأمانة',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != true) {
      name.dispose();
      request.dispose();
      note.dispose();
      return;
    }

    if (existing == null) {
      await repository.addAmanah(
        personName: name.text,
        request: request.text,
        note: note.text,
      );
    } else {
      await repository.updateAmanah(
        existing.id,
        personName: name.text,
        request: request.text,
        note: note.text,
      );
    }

    name.dispose();
    request.dispose();
    note.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    DuaRequest item,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'حذف الأمانة؟',
        ),
        content: Text(
          'حذف طلب الدعاء الخاص بـ ${item.personName}؟',
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
      ),
    );

    if (yes == true) {
      await repository.deleteAmanah(
        item.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final items = repository.amanat;

          final total = items.length;

          final completed = repository.completedAmanatCount;

          final progress = total == 0 ? 0.0 : completed / total;

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'أمانة الدعاء ❤️',
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showEditor(
                context,
              ),
              icon: const Icon(
                Icons.person_add_alt_1,
              ),
              label: const Text(
                'إضافة شخص',
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                100,
              ),
              children: [
                _ProgressCard(
                  total: total,
                  completed: completed,
                  progress: progress,
                ),
                const SizedBox(
                  height: 16,
                ),
                if (items.isEmpty) const _EmptyAmanat(),
                for (final item in items)
                  _AmanahCard(
                    item: item,
                    onToggle: () async {
                      await repository.toggleAmanahDone(
                        item.id,
                      );

                      HapticFeedback.mediumImpact();
                    },
                    onEdit: () => _showEditor(
                      context,
                      existing: item,
                    ),
                    onDelete: () => _delete(
                      context,
                      item,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.total,
    required this.completed,
    required this.progress,
  });

  final int total;
  final int completed;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0
                ? 'أمانة الدعاء'
                : 'معاك ${total - completed} أمانة لسه مستنياك 🤲',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            '$completed من $total تم الدعاء لهم',
          ),
          const SizedBox(
            height: 14,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmanahCard extends StatelessWidget {
  const _AmanahCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final DuaRequest item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(
                50,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  item.isPrayed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 32,
                  color: item.isPrayed
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.personName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    item.request,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          decoration:
                              item.isPrayed ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      item.note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (item.isPrayed)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                      ),
                      child: Text(
                        'تم الدعاء ✓',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                }

                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAmanat extends StatelessWidget {
  const _EmptyAmanat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Text(
            '❤️',
            style: TextStyle(
              fontSize: 58,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            'مين طلب منك تدعيله؟',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'سجّلي الأسماء وطلبات الدعاء، ورفقة هيفكرك بيهم أثناء رحلتك.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
