import 'package:flutter/material.dart';
import 'package:mobile_kelompok/ui/login2.dart';
import 'package:mobile_kelompok/ui/login1.dart';
import 'package:mobile_kelompok/ui/new_passwordscreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Kita',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {'/': (context) => const Homepage()},
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/reset-password')) {
          final uri = Uri.parse(settings.name!);
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            builder: (context) => NewPasswordScreen(token: token ?? ''),
          );
        }
        return null;
      },
    );
  }
}
