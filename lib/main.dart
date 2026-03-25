import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // IMPORTANTE: Para detectar Vercel/Navegador
import 'pages/home_page.dart';
import 'web/admin_login.dart'; // Asegúrate de haber creado esta carpeta y archivo

void main() {
  runApp(const RideApp());
}

class RideApp extends StatelessWidget {
  const RideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RouteMate',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // LÓGICA DE SEPARACIÓN:
      // Si entras desde un navegador (Web), vas al Login del Admin.
      // Si entras desde el celular (App), vas a la Home Page.
      home: kIsWeb ? const AdminLogin() : const HomePage(),
    );
  }
}