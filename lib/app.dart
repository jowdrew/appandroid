import 'package:flutter/material.dart';

import 'features/expenses/presentation/pages/home_page.dart';

/// Root widget of the application.
///
/// This widget provides light and dark themes using Material 3 and
/// delegates routing to its [MaterialApp]. The `themeMode` is set
/// to follow the system preference, giving users a modern, adaptive
/// appearance. A consistent color seed is used for both themes to
/// leverage dynamic color generation introduced in Material 3.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.green;

    return MaterialApp(
      title: 'Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}