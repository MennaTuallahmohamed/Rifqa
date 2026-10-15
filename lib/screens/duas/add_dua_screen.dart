import 'package:flutter/material.dart';

import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';

class AddDuaScreen extends StatefulWidget {
  const AddDuaScreen({
    super.key,
    required this.repository,
    this.dua,
  });

  final DuasRepository repository;

  final Dua? dua;

  @override
  State<AddDuaScreen> createState() => _AddDuaScreenState();
}

class _AddDuaScreenState extends State<AddDuaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late final TextEditingController _textController;

  late DuaCategory _category;

  bool _saving = false;

  bool get editing => widget.dua != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.dua?.title ?? '',
    );

    _textController = TextEditingController(
      text: widget.dua?.arabicText ?? '',
    );

    _category = widget.dua?.category ?? DuaCategory.general;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (editing) {
        await widget.repository.updateUserDua(
          widget.dua!.id,
          title: _titleController.text,
          arabicText: _textController.text,
          category: _category,
        );
      } else {
        await widget.repository.addUserDua(
          title: _titleController.text,
          arabicText: _textController.text,
          category: _category,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing ? 'تعديل الدعاء' : 'إضافة دعاء',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(
                18,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          'اكتبي الدعاء الذي تريدين الاحتفاظ به. سيظهر داخل «أدعيتي» منفصلًا عن المحتوى الموثق.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الدعاء',
                    hintText: 'مثال: دعاء لأهلي',
                    prefixIcon: const Icon(
                      Icons.title_rounded,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اكتبي عنوانًا للدعاء';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller: _textController,
                  minLines: 6,
                  maxLines: 12,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'نص الدعاء',
                    alignLabelWithHint: true,
                    hintText: 'اكتبي دعاءك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اكتبي نص الدعاء';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  'التصنيف',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in DuaCategory.values)
                      ChoiceChip(
                        label: Text(
                          '${category.emoji} ${category.label}',
                        ),
                        selected: _category == category,
                        onSelected: (_) {
                          setState(() {
                            _category = category;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(
                  height: 28,
                ),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.favorite_rounded,
                          ),
                    label: Text(
                      editing ? 'حفظ التعديلات' : 'حفظ في أدعيتي',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Text(
                  'هذا المحتوى شخصي ولن يظهر باعتباره دعاءً موثقًا من القرآن أو السنة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
