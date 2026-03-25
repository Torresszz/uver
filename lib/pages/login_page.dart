import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // URL de tu API de usuarios en Vercel
  final String _urlUsuarios = 'https://uver-oxnw.vercel.app/api/usuarios';

  Future<void> _intentarLogin() async {
    String email = _emailController.text.trim();
    String password = _passController.text
        .trim(); // <-- Obtenemos la contraseña

    if (email.isEmpty || password.isEmpty) {
      _showError("Por favor, ingresa correo y contraseña");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_urlUsuarios));

      if (response.statusCode == 200) {
        List<dynamic> usuarios = jsonDecode(response.body);

        var usuarioEncontrado = usuarios.firstWhere(
          (u) => u['email'] == email,
          orElse: () => null,
        );

        if (usuarioEncontrado != null) {
          // ==========================================
          // 🔑 VALIDACIÓN DE CONTRASEÑA
          // ==========================================
          if (usuarioEncontrado['password'] == password) {
            final prefs = await SharedPreferences.getInstance();
            // Dentro de tu _intentarLogin en LoginPage.dart
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString(
              'user_nombre',
              usuarioEncontrado['nombre'] ?? 'Usuario',
            ); // Cambiado a user_nombre
            await prefs.setString(
              'user_email',
              usuarioEncontrado['email'] ?? email,
            ); // Cambiado a user_email
            await prefs.setString(
              'user_rol',
              usuarioEncontrado['rol'] ?? 'peaton',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("¡Bienvenido, ${usuarioEncontrado['nombre']}!"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          } else {
            // Si el correo existe pero la contraseña no coincide
            _showError("Contraseña incorrecta");
          }
          // ==========================================
        } else {
          _showError("Correo no registrado. Por favor, crea una cuenta.");
        }
      } else {
        _showError("Error del servidor (${response.statusCode})");
      }
    } catch (e) {
      _showError("Error de conexión. Revisa tu internet.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Hero(
                tag: 'logo',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car_filled,
                    size: 80,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "RouteMate",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const Text(
                "Comparte tu camino",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // Input de Correo
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Correo",
                  hintText: "ejemplo@correo.mx",
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 25),

              // Input de Contraseña
              TextField(
                controller:
                    _passController, // Asegúrate de haberlo declarado arriba
                obscureText: true, // Esto oculta el texto (******)
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              // Botón de Entrar
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _intentarLogin,
                      child: const Text(
                        "Iniciar Sesión",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // Enlace a Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Aún no tienes cuenta?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: Text(
                      "Regístrate",
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
