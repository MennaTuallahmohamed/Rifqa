import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  final TextEditingController _controller = TextEditingController();

  final List<_ShoppingItem> _items = [
    _ShoppingItem(
      name: 'تمر عجوة',
      emoji: '🌴',
    ),
    _ShoppingItem(
      name: 'سجادة صلاة',
      emoji: '🕌',
    ),
    _ShoppingItem(
      name: 'هدايا للعائلة',
      emoji: '🎁',
    ),
    _ShoppingItem(
      name: 'عطر أو بخور',
      emoji: '🌸',
    ),
    _ShoppingItem(
      name: 'سبحة',
      emoji: '📿',
    ),
    _ShoppingItem(
      name: 'عباية أو ملابس',
      emoji: '👗',
    ),
    _ShoppingItem(
      name: 'حلويات',
      emoji: '🍬',
    ),
    _ShoppingItem(
      name: 'احتياجات شخصية',
      emoji: '🛍️',
    ),
  ];

  int get _completedCount {
    return _items.where((item) => item.completed).length;
  }

  double get _progress {
    if (_items.isEmpty) {
      return 0;
    }

    return _completedCount / _items.length;
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index].completed = !_items[index].completed;
    });
  }

  void _removeItem(int index) {
    final removedItem = _items[index];

    setState(() {
      _items.removeAt(index);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف "${removedItem.name}"',
        ),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            setState(() {
              _items.insert(index, removedItem);
            });
          },
        ),
      ),
    );
  }

  void _addItem() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    setState(() {
      _items.add(
        _ShoppingItem(
          name: value,
          emoji: '🛍️',
        ),
      );
    });

    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  void _clearCompleted() {
    setState(() {
      _items.removeWhere(
        (item) => item.completed,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        foregroundColor: _greenDark,
        elevation: 0,
        title: const Text(
          'قائمة التسوق',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  120,
                ),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 18),

                  _buildProgress(),

                  const SizedBox(height: 18),

                  _buildAddItem(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(),

                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(
                      _items.length,
                      (index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _buildItem(
                            _items[index],
                            index,
                          ),
                        );
                      },
                    ),

                  if (_completedCount > 0) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _clearCompleted,
                      icon: const Icon(
                        Icons.cleaning_services_outlined,
                      ),
                      label: const Text(
                        'حذف العناصر المكتملة',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _muted,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  _buildBeforeReturnCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _green,
            _greenDark,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _greenDark.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  'إيه اللي محتاجة تشتريه؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'رتّبي مشترياتك عشان ما تنسيش حاجة قبل العودة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFFE7F1ED),
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Text(
            '🛍️',
            style: TextStyle(
              fontSize: 43,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final percent = (_progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  color: _green,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$_completedCount من ${_items.length} تم شراؤها',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: _background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                _gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItem() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _addItem,
            style: IconButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addItem(),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'أضيفي شيئًا للقائمة...',
                hintStyle: TextStyle(
                  color: _muted,
                  fontSize: 12.5,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(
                  horizontal: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'قائمتي',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(width: 7),
        Icon(
          Icons.checklist_rounded,
          color: _green,
        ),
      ],
    );
  }

  Widget _buildItem(
    _ShoppingItem item,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      decoration: BoxDecoration(
        color: item.completed
            ? _green.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.completed
              ? _green.withValues(alpha: 0.25)
              : _border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: IconButton(
          onPressed: () {
            _removeItem(index);
          },
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: _muted,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          textAlign: TextAlign.right,
          style: TextStyle(
            color:
                item.completed ? _muted : _ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            decoration: item.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: item.completed
            ? const Text(
                'تم الشراء',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _green,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.emoji,
              style: const TextStyle(
                fontSize: 23,
              ),
            ),
            const SizedBox(width: 9),
            InkWell(
              onTap: () {
                _toggleItem(index);
              },
              borderRadius:
                  BorderRadius.circular(20),
              child: Icon(
                item.completed
                    ? Icons.check_circle_rounded
                    : Icons
                        .radio_button_unchecked_rounded,
                color: item.completed
                    ? _green
                    : _muted,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Column(
        children: [
          Text(
            '🛍️',
            style: TextStyle(
              fontSize: 42,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'قائمة التسوق فارغة',
            style: TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'أضيفي الأشياء التي تريدين شراءها.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeReturnCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _gold.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              Text(
                'قبل العودة إلى بلدك',
                style: TextStyle(
                  color: _greenDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 7),
              Icon(
                Icons.luggage_rounded,
                color: _green,
              ),
            ],
          ),
          SizedBox(height: 12),
          _ReturnReminder(
            text: 'راجعي هدايا العائلة والأصدقاء',
          ),
          _ReturnReminder(
            text: 'راجعي التمور والهدايا الغذائية',
          ),
          _ReturnReminder(
            text: 'تأكدي من العطور والهدايا الشخصية',
          ),
          _ReturnReminder(
            text: 'راجعي الملابس ومستلزمات الصلاة',
          ),
          _ReturnReminder(
            text: 'تأكدي من وزن الأمتعة قبل السفر',
          ),
        ],
      ),
    );
  }
}

class _ShoppingItem {
  _ShoppingItem({
    required this.name,
    required this.emoji,
    this.completed = false,
  });

  final String name;
  final String emoji;
  bool completed;
}

class _ReturnReminder extends StatelessWidget {
  const _ReturnReminder({
    required this.text,
  });

  final String text;

  static const Color _green =
      Color(0xFF176B52);
  static const Color _ink =
      Color(0xFF17322A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _green,
            size: 17,
          ),
        ],
      ),
    );
  }
}