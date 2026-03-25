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
  bool _isLoading = false;

  // URL de tu API de usuarios en Vercel
  final String _urlUsuarios = 'https://uver-oxnw.vercel.app/api/usuarios';

  Future<void> _intentarLogin() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError("Por favor, ingresa tu correo universitario");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Consultamos la lista de usuarios en Vercel
      final response = await http.get(Uri.parse(_urlUsuarios));
      
      if (response.statusCode == 200) {
        List<dynamic> usuarios = jsonDecode(response.body);
        
        // 2. Buscamos si el email existe
        // Nota: Usamos 'email' porque es como lo definimos en el Dashboard/Vercel
        var usuarioEncontrado = usuarios.firstWhere(
          (u) => u['email'] == email,
          orElse: () => null,
        );

        if (usuarioEncontrado != null) {
          // 3. ¡Éxito! Guardamos la sesión en el dispositivo
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', usuarioEncontrado['nombre'] ?? 'Usuario');
          await prefs.setString('userEmail', usuarioEncontrado['email'] ?? email);
          await prefs.setString('userRole', usuarioEncontrado['rol'] ?? 'peaton');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("¡Bienvenido, ${usuarioEncontrado['nombre']}!"), backgroundColor: Colors.green),
            );
            // Vamos a la Home y quitamos el Login del historial
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const HomePage())
            );
          }
        } else {
          _showError("Correo no registrado. Por favor, crea una cuenta.");
        }
      } else {
        _showError("Error del servidor (${response.statusCode})");
      }
    } catch (e) {
      _showError("Error de conexión. Revisa tu internet.");
      debugPrint("Error Login: $e");
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
                  child: Icon(Icons.directions_car_filled, size: 80, color: Colors.blue.shade800),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "RouteMate",
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blue.shade900
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
                  labelText: "Correo Universitario",
                  hintText: "ejemplo@ucol.mx",
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 25),

              // Botón de Entrar
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                    ),
                    onPressed: _intentarLogin,
                    child: const Text("Iniciar Sesión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              
              const SizedBox(height: 20),

              // Enlace a Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Aún no tienes cuenta?"),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: Text("Regístrate", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
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