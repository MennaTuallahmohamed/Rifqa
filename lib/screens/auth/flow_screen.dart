import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../state/app_state.dart';
import '../shell.dart';

class CountryData {
  final String name;
  final String flag;
  final String code;

  const CountryData({
    required this.name,
    required this.flag,
    required this.code,
  });
}

const List<CountryData> countries = [
  CountryData(name: 'مصر', flag: '🇪🇬', code: '+20'),
  CountryData(name: 'السعودية', flag: '🇸🇦', code: '+966'),
  CountryData(name: 'الإمارات', flag: '🇦🇪', code: '+971'),
  CountryData(name: 'الكويت', flag: '🇰🇼', code: '+965'),
  CountryData(name: 'قطر', flag: '🇶🇦', code: '+974'),
  CountryData(name: 'البحرين', flag: '🇧🇭', code: '+973'),
  CountryData(name: 'عُمان', flag: '🇴🇲', code: '+968'),
  CountryData(name: 'الأردن', flag: '🇯🇴', code: '+962'),
  CountryData(name: 'العراق', flag: '🇮🇶', code: '+964'),
  CountryData(name: 'فلسطين', flag: '🇵🇸', code: '+970'),
  CountryData(name: 'المغرب', flag: '🇲🇦', code: '+212'),
  CountryData(name: 'الجزائر', flag: '🇩🇿', code: '+213'),
  CountryData(name: 'تونس', flag: '🇹🇳', code: '+216'),
  CountryData(name: 'ليبيا', flag: '🇱🇾', code: '+218'),
  CountryData(name: 'السودان', flag: '🇸🇩', code: '+249'),
  CountryData(name: 'تركيا', flag: '🇹🇷', code: '+90'),
  CountryData(name: 'باكستان', flag: '🇵🇰', code: '+92'),
  CountryData(name: 'إندونيسيا', flag: '🇮🇩', code: '+62'),
  CountryData(name: 'ماليزيا', flag: '🇲🇾', code: '+60'),
  CountryData(name: 'الهند', flag: '🇮🇳', code: '+91'),
  CountryData(name: 'المملكة المتحدة', flag: '🇬🇧', code: '+44'),
  CountryData(name: 'الولايات المتحدة', flag: '🇺🇸', code: '+1'),
];

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  int page = -1;
  bool signup = false;
  int ob = 0;

  CountryData selectedCountry = countries.first;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? error;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      setState(() {
        page = AppScope.of(context).onboardingDone ? 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (page == -1) {
      return _buildSplash();
    }

    if (page == 0) {
      return _buildOnboarding(context);
    }

    return _buildAuth(context);
  }

  Widget _buildSplash() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.green,
              AppColors.greenDark,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🕋',
                  style: TextStyle(fontSize: 54),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'رِفقة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'رفيقك في الحج والعمرة',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    const data = [
      (
        '🕋',
        'عمرتك خطوة بخطوة',
        'دليل تفاعلي بالأدعية ومحاكاة للطواف والسعي، وعدّاد يحفظ تقدمك.'
      ),
      (
        '🗺️',
        'خريطة الحرم وزر «أنا تائه»',
        'اعرف أقرب باب وطريقك، وأبلغ مجموعتك بمكانك بضغطة واحدة.'
      ),
      (
        '👥',
        'رفاقك ومنبهك',
        'اجمع أهلك بكود واحد، وصحّيك بصوتك ورسالتك للفجر والطواف.'
      ),
    ];

    final slide = data[ob];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      page = 1;
                    });
                  },
                  child: const Text('تخطّي'),
                ),
              ),

              const Spacer(),

              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.green,
                      AppColors.greenDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                alignment: Alignment.center,
                child: Text(
                  slide.$1,
                  style: const TextStyle(fontSize: 104),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                slide.$2,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                slide.$3,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              PrimaryButton(
                ob == 2 ? 'ابدأ الآن' : 'التالي',
                onTap: () {
                  if (ob == 2) {
                    final state = AppScope.of(context);

                    state.change(() {
                      state.onboardingDone = true;
                    });

                    setState(() {
                      page = 1;
                    });
                  } else {
                    setState(() {
                      ob++;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuth(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🕋',
                  style: TextStyle(fontSize: 40),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                signup ? 'أنشئ حسابك' : 'أهلًا بعودتك',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              SegButton(
                signup: signup,
                onChanged: (value) {
                  setState(() {
                    signup = value;
                    error = null;
                  });
                },
              ),

              AppCard(
                child: Column(
                  children: [
                    if (signup) ...[
                      TextField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],

                    _buildCountrySelector(),

                    const SizedBox(height: 12),

                    _buildPhoneField(),

                    if (signup) ...[
                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    PrimaryButton(
                      signup ? 'إنشاء الحساب' : 'تسجيل الدخول',
                      onTap: () => login(context),
                    ),

                    const SizedBox(height: 16),

                    const Text('أو'),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => go(context),
                            child: const Text('Apple'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => go(context),
                            child: const Text('G  Google'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              PrimaryButton(
                'متابعة كضيف',
                outline: true,
                onTap: () => go(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _showCountryPicker,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الدولة',
          prefixIcon: Icon(Icons.public),
        ),
        child: Row(
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedCountry.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              selectedCountry.code,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'رقم الجوال',
        hintText: '10xxxxxxxx',
        prefixIcon: Container(
          constraints: const BoxConstraints(minWidth: 82),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(
            '${selectedCountry.flag} ${selectedCountry.code}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'اختر الدولة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: ListView.separated(
                    itemCount: countries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final country = countries[index];

                      return ListTile(
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(country.name),
                        trailing: Text(
                          country.code,
                          textDirection: TextDirection.ltr,
                        ),
                        onTap: () {
                          setState(() {
                            selectedCountry = country;
                          });

                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void login(BuildContext context) {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (signup && name.length < 2) {
      setState(() {
        error = 'اكتب الاسم الكامل';
      });
      return;
    }

    if (phone.length < 7) {
      setState(() {
        error = 'أدخل رقم جوال صحيح';
      });
      return;
    }

    if (signup &&
        (!email.contains('@') || !email.contains('.'))) {
      setState(() {
        error = 'أدخل بريدًا إلكترونيًا صحيحًا';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      });
      return;
    }

    // الرقم الذي سنرسله للـ Backend لاحقًا.
    final internationalPhone =
        '${selectedCountry.code}${_cleanPhone(phone)}';

    debugPrint('Country: ${selectedCountry.name}');
    debugPrint('Phone: $internationalPhone');
    debugPrint('Email: $email');

    final state = AppScope.of(context);

    state.change(() {
      state.loggedIn = true;

      if (name.isNotEmpty) {
        state.name = name;
      }
    });

    go(context);
  }

  String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    while (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  void go(BuildContext context) {
    final state = AppScope.of(context);

    state.change(() {
      state.loggedIn = true;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AppShell(),
      ),
    );
  }
}

class SegButton extends StatelessWidget {
  final bool signup;
  final ValueChanged<bool> onChanged;

  const SegButton({
    super.key,
    required this.signup,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    !signup ? Theme.of(context).cardColor : null,
              ),
              onPressed: () => onChanged(false),
              child: const Text('تسجيل الدخول'),
            ),
          ),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    signup ? Theme.of(context).cardColor : null,
              ),
              onPressed: () => onChanged(true),
              child: const Text('حساب جديد'),
            ),
          ),
        ],
      ),
    );
  }
}