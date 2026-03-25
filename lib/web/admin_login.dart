import 'package:flutter/material.dart';
import 'admin_dashboard.dart'; // Importas el dashboard que ya hicimos

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  // Datos "Hardcoded" para el admin (Como pediste)
  final String adminUser = "admin@routemate.com";
  final String adminPass = "Routemate2024!";

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _intentarLogin() {
    if (_userController.text == adminUser && _passController.text == adminPass) {
      // Si coinciden, navegamos al Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      // Si no, mostramos un error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuario o contraseña incorrectos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400, // Ancho fijo para que se vea como una tarjeta en la web
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Acceso Administrativo", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: "Usuario", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _intentarLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Entrar al Dashboard", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}