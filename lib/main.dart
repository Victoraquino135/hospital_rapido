import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  // ==========================================================
  // INICIALIZA O SQLITE PARA WINDOWS / LINUX / MAC
  // ==========================================================

  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;
  }

  // ==========================================================
  // INICIA O APLICATIVO
  // ==========================================================

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Rápido',

      debugShowCheckedModeBanner: false,

      // ========================================================
      // TEMA
      // ========================================================

      theme: AppTheme.lightTheme,

      // ========================================================
      // IDIOMA
      // ========================================================

      locale: const Locale('pt', 'BR'),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],

      // ========================================================
      // TELA INICIAL
      // ========================================================

      home: const LoginScreen(),
    );
  }
}