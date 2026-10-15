import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/duas/duas_repository.dart';

class AppState extends ChangeNotifier {
  // =========================================================
  // Global app state
  // =========================================================

  bool onboardingDone = false;
  bool loggedIn = false;
  bool dark = false;

  String name = '';
  String userType = 'معتمر';
  String dest = 'mataf';
  String gate = 'g1';

  int step = 0;
  int tawaf = 0;
  int sai = 0;
  int jamarat = 0;

  final Set<int> done = {};

  // =========================================================
  // Feature repositories
  // =========================================================

  final DuasRepository duas = DuasRepository();

  // =========================================================
  // Progress
  // =========================================================

  int get progress {
    final completed = done.length + (tawaf >= 7 ? 1 : 0) + (sai >= 7 ? 1 : 0);

    return ((completed / 9) * 100).round();
  }

  // =========================================================
  // Load
  // =========================================================

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString('state');

    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;

        onboardingDone = json['onb'] ?? false;
        loggedIn = json['login'] ?? false;
        name = json['name'] ?? '';
        dark = json['dark'] ?? false;

        step = json['step'] ?? 0;
        tawaf = json['tw'] ?? 0;
        sai = json['sa'] ?? 0;
        jamarat = json['jamarat'] ?? 0;

        userType = json['userType'] ?? 'معتمر';
        dest = json['dest'] ?? 'mataf';
        gate = json['gate'] ?? 'g1';

        done
          ..clear()
          ..addAll(
            List<int>.from(
              json['done'] ?? const [],
            ),
          );
      } catch (e) {
        debugPrint(
          'AppState load error: $e',
        );
      }
    }

    // Initialize Duas feature.
    //
    // Repository نفسها مسؤولة عن:
    // - Favorites
    // - My Duas
    // - Amanat
    // - Dua settings
    await duas.init();

    notifyListeners();
  }

  // =========================================================
  // Save
  // =========================================================

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'onb': onboardingDone,
      'login': loggedIn,
      'name': name,
      'dark': dark,
      'step': step,
      'tw': tawaf,
      'sa': sai,
      'jamarat': jamarat,
      'userType': userType,
      'dest': dest,
      'gate': gate,
      'done': done.toList(),
    };

    await prefs.setString(
      'state',
      jsonEncode(data),
    );
  }

  // =========================================================
  // Generic state change
  // =========================================================

  void change(
    void Function() action,
  ) {
    action();

    _save();

    notifyListeners();
  }

  // =========================================================
  // Dark mode
  // =========================================================

  void toggleDarkMode() {
    change(() {
      dark = !dark;
    });
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    duas.dispose();
    super.dispose();
  }
}

// ===========================================================
// App Scope
// ===========================================================

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(
          notifier: state,
        );

  static AppState of(
    BuildContext context,
  ) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();

    assert(
      scope != null,
      'AppScope was not found in the widget tree.',
    );

    return scope!.notifier!;
  }
}
