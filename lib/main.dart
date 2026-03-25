import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:shared_preferences/shared_preferences.dart';

// Páginas
import 'pages/home_page.dart';
import 'pages/login_page.dart'; // La que creamos hace un momento
import 'web/admin_login.dart'; 

void main() async {
  // 1. Necesario para inicializar SharedPreferences antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  bool loggedIn = false;

  // 2. Solo buscamos sesión si NO es Web (es decir, es Android/iOS)
  if (!kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    loggedIn = prefs.getBool('isLoggedIn') ?? false;
  }

  runApp(RideApp(isLoggedIn: loggedIn));
}

class RideApp extends StatelessWidget {
  final bool isLoggedIn;
  const RideApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RouteMate',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      // LÓGICA DE TRES VÍAS:
      // 1. ¿Es Web? -> AdminLogin
      // 2. ¿Es Móvil y ya inició sesión? -> HomePage
      // 3. ¿Es Móvil y NO ha iniciado sesión? -> LoginPage
      home: kIsWeb 
          ? const AdminLogin() 
          : (isLoggedIn ? const HomePage() : const LoginPage()),
    );
  }
}