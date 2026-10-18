import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'widgets/rifqa_market_style.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingEntry {
  _ShoppingEntry({required this.name, this.done = false});
  final String name;
  bool done;
  Map<String, dynamic> toJson() => {'name': name, 'done': done};
  factory _ShoppingEntry.fromJson(dynamic data) {
    final item = Map<String, dynamic>.from(data as Map);
    return _ShoppingEntry(name: (item['name'] ?? '').toString(), done: item['done'] == true);
  }
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const String _storageKey = 'rifqa_premium_shopping_list_v1';
  static const _starter = [
    'تمر عجوة', 'سجادة صلاة', 'هدايا للعائلة', 'عطر أو بخور',
    'سبحة', 'عباية أو ملابس', 'حلويات', 'احتياجات شخصية',
  ];
  final TextEditingController _input = TextEditingController();
  List<_ShoppingEntry> _items = [];
  bool _busy = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _input.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final raw = pref.getString(_storageKey);
      final parsed = raw == null
          ? _starter.map((name) => _ShoppingEntry(name: name)).toList()
          : (jsonDecode(raw) as List).map(_ShoppingEntry.fromJson).toList();
      if (mounted) setState(() { _items = parsed; _busy = false; });
      if (raw == null) await _save();
    } catch (_) {
      if (mounted) setState(() { _items = _starter.map((n) => _ShoppingEntry(name: n)).toList(); _busy = false; });
    }
  }

  Future<void> _save() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_storageKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _add(String name) {
    final text = name.trim();
    if (text.isEmpty) return;
    if (_items.any((e) => e.name == text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العنصر موجود بالفعل في القائمة')));
      return;
    }
    setState(() { _items.add(_ShoppingEntry(name: text)); });
    _input.clear();
    FocusScope.of(context).unfocus();
    _save();
  }

  void _toggle(int index) { setState(() => _items[index].done = !_items[index].done); _save(); }

  void _delete(int index) {
    final entry = _items.removeAt(index);
    setState(() {});
    _save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${entry.name}'),
      action: SnackBarAction(label: 'تراجع', onPressed: () {
        setState(() => _items.insert((index > _items.length ? _items.length : index), entry)); _save();
      }),
    ));
  }

  void _clearDone() { setState(() => _items.removeWhere((e) => e.done)); _save(); }
  int get _completed => _items.where((e) => e.done).length;
  double get _progress => _items.isEmpty ? 0 : _completed / _items.length;

  void _share() {
    final lines = _items.map((e) => (e.done ? '☑ ' : '☐ ') + e.name).join('\n');
    final text = _items.isEmpty ? 'قائمتي في رِفقة فارغة.' : 'قائمة مشترياتي — رِفقة 💚\n\n$lines';
    Share.share(text);
  }

  String _symbol(String title) {
    if (title.contains('تمر')) return '🌴';
    if (title.contains('سجاد')) return '🕌';
    if (title.contains('هد')) return '🎁';
    if (title.contains('عطر') || title.contains('بخور')) return '🌸';
    if (title.contains('سبح')) return '📿';
    if (title.contains('لبس') || title.contains('عباي')) return '👘';
    if (title.contains('حلو')) return '🍬';
    return '🛍️';
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      appBar: AppBar(
        backgroundColor: MarketPalette.evergreen,
        foregroundColor: Colors.white,
        title: const Text('قائمة التسوّق', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_forward_rounded)),
        actions: [IconButton(tooltip: 'مشاركة القائمة', onPressed: _share, icon: const Icon(Icons.ios_share_rounded))],
      ),
      body: _busy ? const Center(child: CircularProgressIndicator()) : SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 19, 16, 38),
        children: [
          _hero(), const SizedBox(height: 18),
          _progressCard(), const SizedBox(height: 18),
          _addBox(), const SizedBox(height: 14),
          _quickAdds(), const SizedBox(height: 23),
          Row(children: [const Text('قائمتي', style: TextStyle(color: MarketPalette.ink, fontSize: 20, fontWeight: FontWeight.w900)),
            const Spacer(), if (_completed > 0) TextButton.icon(onPressed: _clearDone,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18), label: const Text('حذف المكتمل'))]),
          const SizedBox(height: 8),
          if (_items.isEmpty) const MarketSoftCard(child: Padding(padding: EdgeInsets.all(24),
            child: Center(child: Text('ابدئي بإضافة أول مشترياتك 🎁')))) else
          ...List.generate(_items.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 9),
            child: _itemTile(_items[i], i))),
          const SizedBox(height: 18), _tips(),
        ],
      )),
    ),
  );

  Widget _hero() => Container(
    height: 148, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [MarketPalette.emerald, MarketPalette.evergreen]),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('هدايا من أرض الحرمين', style: TextStyle(color: Color(0xFFF5DC9D), fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('كل حاجة هتشتريها في مكان واحد، محفوظة حتى لو قفلتي التطبيق.',
          style: TextStyle(color: Colors.white, fontSize: 12, height: 1.6)),
      ])),
      const SizedBox(width: 15), const Text('🎁', style: TextStyle(fontSize: 52)),
    ]),
  );

  Widget _progressCard() => MarketSoftCard(child: Column(children: [
    Row(children: [
      const Icon(Icons.check_circle_outline_rounded, color: MarketPalette.emerald),
      const SizedBox(width: 7),
      Text('$_completed من ${_items.length} تم شراؤها',
        style: const TextStyle(color: MarketPalette.ink, fontSize: 13, fontWeight: FontWeight.w800)),
      const Spacer(),
      Text('${(_progress * 100).round()}%', style: const TextStyle(color: MarketPalette.emerald, fontSize: 20, fontWeight: FontWeight.w900)),
    ]),
    const SizedBox(height: 12),
    ClipRRect(borderRadius: BorderRadius.circular(15), child: LinearProgressIndicator(
      value: _progress, minHeight: 9, backgroundColor: MarketPalette.pale,
      color: MarketPalette.emerald)),
  ]));

  Widget _addBox() => MarketSoftCard(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    child: Row(children: [
      Expanded(child: TextField(
        controller: _input, onSubmitted: _add,
        decoration: const InputDecoration(hintText: 'ضيفي حاجة للقائمة...', border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 12, color: MarketPalette.muted)),
      )),
      IconButton.filled(style: IconButton.styleFrom(backgroundColor: MarketPalette.evergreen),
        onPressed: () => _add(_input.text), icon: const Icon(Icons.add_rounded)),
    ]));

  Widget _quickAdds() => Wrap(spacing: 6, runSpacing: 8, children: [
    const Text('اقتراحات:  ', style: TextStyle(color: MarketPalette.muted, fontSize: 12)),
    for (final text in ['تمر عجوة', 'سجادة صلاة', 'عطر', 'هدايا للعائلة'])
      ActionChip(label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () => _add(text), backgroundColor: Colors.white,
        side: const BorderSide(color: MarketPalette.line)),
  ]);

  Widget _itemTile(_ShoppingEntry entry, int index) => InkWell(
    onTap: () => _toggle(index), borderRadius: BorderRadius.circular(17),
    child: MarketSoftCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(children: [
        Icon(entry.done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
          color: MarketPalette.emerald, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(entry.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
          color: entry.done ? MarketPalette.muted : MarketPalette.ink,
          decoration: entry.done ? TextDecoration.lineThrough : null))),
        Text(_symbol(entry.name), style: const TextStyle(fontSize: 22)),
        IconButton(onPressed: () => _delete(index),
          tooltip: 'حذف', icon: const Icon(Icons.close_rounded, size: 18, color: MarketPalette.muted)),
      ]),
    ),
  );

  Widget _tips() => const MarketSoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [Icon(Icons.lightbulb_outline_rounded, color: MarketPalette.gold),
        SizedBox(width: 8), Text('قبل العودة', style: TextStyle(color: MarketPalette.ink,
          fontWeight: FontWeight.w900, fontSize: 16))]),
      SizedBox(height: 9),
      Text('راجعي وزن الأمتعة، وقواعد حمل السوائل والعطور والمواد الغذائية مع شركة الطيران. '
        'واحتفظي بفواتير المشتريات المهمة.',
        style: TextStyle(color: MarketPalette.muted, fontSize: 12, height: 1.8)),
    ],
  ));
}
