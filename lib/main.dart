import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _defaultHome = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Cek status login saat app pertama kali dibuka
  Future<void> _checkLoginStatus() async {
    // Ambil data login dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username') ?? '';

    // Delay sebentar untuk efek loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Update tampilan: langsung ke Dashboard jika sudah login, ke Login jika belum
    setState(() {
      _defaultHome = isLoggedIn
          ? DashboardPage(username: username)
          : const LoginPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cek Obat App',
      home: _defaultHome,
      routes: {'/register': (context) => const RegisterPage()},
    );
  }
}
