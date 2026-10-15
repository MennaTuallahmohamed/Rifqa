import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../services/message_notification_service.dart';
import 'immersive_intro.dart';
import '../shell.dart';

// Rifqa Authentication + Onboarding
// Requires Firebase.initializeApp() in main.dart.
// SMS OTP is intentionally NOT implemented: real SMS may require billing.

const _green = Color(0xFF176B50);
const _darkGreen = Color(0xFF0C463A);
const _cream = Color(0xFFF7F8F3);

class CountryData {
  final String name;
  final String flag;
  final String dialCode;
  final String isoCode;

  const CountryData(this.name, this.flag, this.dialCode, this.isoCode);
}

const countries = <CountryData>[
  CountryData('مصر', '🇪🇬', '+20', 'EG'),
  CountryData('السعودية', '🇸🇦', '+966', 'SA'),
  CountryData('الإمارات', '🇦🇪', '+971', 'AE'),
  CountryData('الكويت', '🇰🇼', '+965', 'KW'),
  CountryData('قطر', '🇶🇦', '+974', 'QA'),
  CountryData('البحرين', '🇧🇭', '+973', 'BH'),
  CountryData('عُمان', '🇴🇲', '+968', 'OM'),
  CountryData('الأردن', '🇯🇴', '+962', 'JO'),
  CountryData('العراق', '🇮🇶', '+964', 'IQ'),
  CountryData('فلسطين', '🇵🇸', '+970', 'PS'),
  CountryData('المغرب', '🇲🇦', '+212', 'MA'),
  CountryData('الجزائر', '🇩🇿', '+213', 'DZ'),
  CountryData('تونس', '🇹🇳', '+216', 'TN'),
  CountryData('ليبيا', '🇱🇾', '+218', 'LY'),
  CountryData('السودان', '🇸🇩', '+249', 'SD'),
  CountryData('تركيا', '🇹🇷', '+90', 'TR'),
  CountryData('باكستان', '🇵🇰', '+92', 'PK'),
  CountryData('إندونيسيا', '🇮🇩', '+62', 'ID'),
  CountryData('ماليزيا', '🇲🇾', '+60', 'MY'),
  CountryData('الهند', '🇮🇳', '+91', 'IN'),
  CountryData('المملكة المتحدة', '🇬🇧', '+44', 'GB'),
  CountryData('الولايات المتحدة', '🇺🇸', '+1', 'US'),
];

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  // splash -> onboarding -> auth -> verify
  String _screen = 'splash';
  bool _signUp = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  CountryData _country = countries.first;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 5400), _afterSplash);
  }

  Future<void> _afterSplash() async {
    if (!mounted) return;
    final state = AppScope.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.isAnonymous || user.emailVerified)) {
      _enterApp(user);
      return;
    }
    setState(() {
      _screen = user != null
          ? 'verify'
          : (state.onboardingDone ? 'auth' : 'onboarding');
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setError(String? value) {
    if (mounted) setState(() => _error = value);
  }

  Future<void> _perform(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await operation();
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseError(e));
    } on FirebaseException catch (_) {
      _setError('حدث خطأ في حفظ البيانات، حاولي مرة أخرى.');
    } catch (_) {
      _setError('تعذر إكمال العملية الآن. تحققي من الإنترنت وحاولي مجددًا.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _firebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use': return 'البريد الإلكتروني مسجل بالفعل.';
      case 'invalid-email': return 'البريد الإلكتروني غير صحيح.';
      case 'weak-password': return 'استخدمي كلمة مرور أقوى.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found': return 'بيانات الدخول غير صحيحة.';
      case 'too-many-requests': return 'محاولات كثيرة، حاولي لاحقًا.';
      case 'network-request-failed': return 'تحققي من اتصال الإنترنت.';
      case 'operation-not-allowed': return 'طريقة الدخول غير مفعّلة في Firebase.';
      case 'requires-recent-login': return 'يرجى تسجيل الدخول مرة أخرى.';
      default: return 'تعذرت العملية (${error.code}).';
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'اكتبي بريدًا إلكترونيًا صحيحًا';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) return 'كلمة المرور 8 أحرف على الأقل';
    return null;
  }

  String _internationalPhone() {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    // A leading zero is a trunk prefix for most listed countries.
    final withoutZero = digits.replaceFirst(RegExp(r'^0+'), '');
    return '${_country.dialCode}$withoutZero';
  }

  Future<void> _submitAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _perform(() async {
      final auth = FirebaseAuth.instance;
      if (_signUp) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        final user = credential.user!;
        await user.updateDisplayName(_name.text.trim());
        // Profile data is only saved if your Firestore Security Rules allow it.
        // Never treat a phone number here as OTP-verified.
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': _name.text.trim(),
            'email': _email.text.trim(),
            'phone': _internationalPhone(),
            'phoneVerified': false,
            'countryCode': _country.isoCode,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } on FirebaseException {
          // Account exists: profile can be retried after rules are configured.
          // Do not falsely indicate profile storage succeeded.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم إنشاء الحساب، لكن حفظ الملف الشخصي لم يكتمل. سنحتاج مراجعة قواعد Firestore.'),
            ));
          }
        }
        await user.sendEmailVerification();
        if (!mounted) return;
        setState(() => _screen = 'verify');
      } else {
        final credential = await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        final user = credential.user!;
        if (!mounted) return;
        if (user.emailVerified) {
          _enterApp(user);
        } else {
          setState(() => _screen = 'verify');
        }
      }
    });
  }

  Future<void> _guest() async {
    await _perform(() async {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      if (!mounted) return;
      _enterApp(credential.user!);
    });
  }

  Future<void> _checkVerification() async {
    await _perform(() async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        _enterApp(user);
      } else {
        _setError('لم يتم تأكيد البريد بعد. افتحي رسالة التفعيل ثم اضغطي تحقق مجددًا.');
      }
    });
  }

  Future<void> _resendVerification() async {
    await _perform(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No user');
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رابط تأكيد جديد إلى بريدك الإلكتروني.')),
      );
    });
  }

  Future<void> _returnToLogin() async {
    await _perform(() async {
      await MessageNotificationService.instance.prepareForSignOut();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() { _screen = 'auth'; _signUp = false; _error = null; });
    });
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نسيت كلمة المرور؟'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('هنبعتلك رابط إعادة تعيين كلمة المرور على الإيميل، مش SMS.'),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    if (_validateEmail(result) != null) {
      _setError('اكتبي بريدًا إلكترونيًا صحيحًا لاستعادة كلمة المرور.');
      return;
    }
    await _perform(() async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لو البريد مرتبط بحساب، راجعي صندوق الوارد ورسائل Spam.'),
      ));
    });
  }

  void _enterApp(User user) {
    if (!mounted) return;
    final state = AppScope.of(context);
    state.change(() {
      state.loggedIn = true;
      if (!user.isAnonymous && (user.displayName ?? '').trim().isNotEmpty) {
        state.name = user.displayName!.trim();
      }
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MessageNotificationService.instance.markAppReady();
    });
  }

  void _finishOnboarding() {
    final state = AppScope.of(context);
    state.change(() => state.onboardingDone = true);
    setState(() => _screen = 'auth');
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case 'splash': return const ImmersiveSplash();
      case 'onboarding': return ImmersiveOnboarding(onComplete: _finishOnboarding);
      case 'verify': return _verify();
      default: return _auth();
    }
  }

  Widget _auth() => Scaffold(
    backgroundColor: _cream,
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 470),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text('🕋', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 10),
            Text(_signUp ? 'أهلًا بك في رِفقة' : 'أهلًا بعودتك', textAlign: TextAlign.center,
                style: const TextStyle(color: _darkGreen, fontSize: 29, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_signUp ? 'أنشئي حسابك لتبدئي رحلة مطمئنة مع رفاقك' : 'سجّلي دخولك لاستكمال رحلتك',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: const Color(0xFFE8EEE8), borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Expanded(child: _tabButton('تسجيل الدخول', !_signUp, () => setState(() { _signUp = false; _error = null; }))),
                Expanded(child: _tabButton('حساب جديد', _signUp, () => setState(() { _signUp = true; _error = null; }))),
              ]),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (_signUp) ...[
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: _input('الاسم الكامل', Icons.person_outline),
                      validator: (v) => (v ?? '').trim().length < 2 ? 'اكتبي اسمك الكامل' : null,
                    ),
                    const SizedBox(height: 12),
                    _countrySelector(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                      decoration: _input('رقم الجوال (بدون كود الدولة)', Icons.phone_outlined),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        return digits.length >= 7 && digits.length <= 15 ? null : 'أدخلي رقم هاتف صحيحًا';
                      },
                    ),
                    const SizedBox(height: 7),
                    const Text('رقم الهاتف غير مؤكد حتى تفعيل SMS OTP لاحقًا.',
                        style: TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    decoration: _input('البريد الإلكتروني', Icons.email_outlined),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    textDirection: TextDirection.ltr,
                    decoration: _input('كلمة المرور', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                    validator: (v) => _signUp ? _validatePassword(v) : ((v ?? "").isEmpty ? "اكتبي كلمة المرور" : null),
                  ),
                  if (!_signUp)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                  if (_error != null) _errorPanel(),
                  const SizedBox(height: 14),
                  _mainButton(_signUp ? 'إنشاء الحساب' : 'تسجيل الدخول', _submitAuth),
                  const SizedBox(height: 10),
                  const Text('Google وApple سيتم تفعيلهما بعد إعدادهما فعليًا.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _guest,
              icon: const Icon(Icons.person_outline),
              label: const Text('متابعة كضيف'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 8),
            const Text('بعض خصائص المجموعات والموقع قد تتطلب حسابًا مؤكدًا.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        )),
      ),
    ))),
  );

  Widget _verify() {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
          const Icon(Icons.mark_email_unread_outlined, size: 90, color: _green),
          const SizedBox(height: 16),
          const Text('تأكيد البريد الإلكتروني', style: TextStyle(fontSize: 27, color: _darkGreen, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('بعثنا رابط تأكيد على بريدك. افتحي الرسالة واضغطي على الرابط، ثم ارجعي واضغطي «تحقق مجددًا».',
              textAlign: TextAlign.center, style: TextStyle(height: 1.7)),
          const SizedBox(height: 14),
          Text(user?.email ?? '', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_error != null) _errorPanel(),
          const SizedBox(height: 22),
          _mainButton('تحقق مجددًا', _checkVerification),
          const SizedBox(height: 12),
          TextButton(onPressed: _busy ? null : _resendVerification, child: const Text('إعادة إرسال رابط التأكيد')),
          TextButton(onPressed: _busy ? null : _returnToLogin, child: const Text('الرجوع لتسجيل الدخول')),
          const SizedBox(height: 8),
          const Text('التأكيد هنا برابط إيميل، وليس كود SMS OTP.',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
      ))),
    );
  }

  Widget _countrySelector() => InkWell(
    onTap: _pickCountry,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: _input('الدولة وكود الاتصال', Icons.public),
      child: Row(children: [
        Text(_country.flag, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Text(_country.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(_country.dialCode, textDirection: TextDirection.ltr, style: const TextStyle(color: _green)),
        const SizedBox(width: 8),
        const Icon(Icons.keyboard_arrow_down),
      ]),
    ),
  );

  Future<void> _pickCountry() async {
    final chosen = await showModalBottomSheet<CountryData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        String query = '';
        return StatefulBuilder(builder: (context, setModalState) {
          final filtered = countries.where((c) {
            final key = query.toLowerCase().trim();
            return c.name.contains(key) || c.isoCode.toLowerCase().contains(key) || c.dialCode.contains(key);
          }).toList();
          return SafeArea(child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.75,
              child: Column(children: [
                const Padding(padding: EdgeInsets.all(12), child: Text('اختاري الدولة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
                  autofocus: true,
                  decoration: _input('ابحثي باسم الدولة أو كود الاتصال', Icons.search),
                  onChanged: (v) => setModalState(() => query = v),
                )),
                const SizedBox(height: 10),
                Expanded(child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                      title: Text(c.name),
                      subtitle: Text(c.isoCode),
                      trailing: Text(c.dialCode, textDirection: TextDirection.ltr),
                      selected: c.isoCode == _country.isoCode,
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                )),
              ]),
            ),
          ));
        });
      },
    );
    if (chosen != null && mounted) setState(() => _country = chosen);
  }

  Widget _errorPanel() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(12)),
      child: Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
    ),
  );

  Widget _tabButton(String title, bool selected, VoidCallback onPressed) => TextButton(
    onPressed: _busy ? null : onPressed,
    style: TextButton.styleFrom(
      foregroundColor: selected ? _green : Colors.black54,
      backgroundColor: selected ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _green),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD7DFD9))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _green, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
  );

  Widget _mainButton(String title, VoidCallback onPressed) => FilledButton(
    onPressed: _busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _green,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: _busy
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}
