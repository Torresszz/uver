import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String tipoUsuario = "conductor";

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  // 1. URL CORREGIDA: Debe ser la de tu proyecto en Vercel
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/usuarios';

  Future<void> registrarUsuario() async {
    // Verificamos que los campos no estén vacíos antes de enviar
    if (_nombreController.text.isEmpty || _correoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena los campos principales")),
      );
      return;
    }

    final Map<String, dynamic> userData = {
      'nombre': _nombreController.text,
      'email': _correoController.text, // Cambié 'correo' a 'email' para que coincida con el Dashboard
      'telefono': _telefonoController.text,
      'rol': tipoUsuario,
      'fecha_registro': DateTime.now().toIso8601String(),
      'estado': 'Pendiente', // 'P' mayúscula para que se vea bien en la tabla
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl), // Usamos la URL completa
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Registro exitoso! Enviado a revisión"), backgroundColor: Colors.green),
        );
        // Limpiar campos después del éxito
        _nombreController.clear();
        _correoController.clear();
        _telefonoController.clear();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("==== ERROR EN REGISTRO ====");
      debugPrint(e.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No se pudo conectar con el servidor")),
      );
    }
  }

  // --- El resto de tus widgets (buildInput, buildUpload, etc.) se mantienen igual ---
  
  Widget buildInput(String label, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildUpload(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            TextButton(onPressed: () {}, child: const Text("Subir"))
          ],
        ),
      ),
    );
  }

  Widget formularioComun() {
    return Column(
      children: [
        buildInput("Nombre completo", Icons.person, _nombreController),
        buildInput("Correo", Icons.email, _correoController, type: TextInputType.emailAddress),
        buildInput("Teléfono", Icons.phone, _telefonoController, type: TextInputType.phone),
        buildUpload("Foto INE", Icons.badge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  avatar: Icon(Icons.directions_car, color: tipoUsuario == "conductor" ? Colors.white : Colors.blue),
                  label: Text("Tengo carro", style: TextStyle(color: tipoUsuario == "conductor" ? Colors.white : Colors.black)),
                  selected: tipoUsuario == "conductor",
                  selectedColor: Colors.blue,
                  onSelected: (val) => setState(() => tipoUsuario = "conductor"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  avatar: Icon(Icons.person, color: tipoUsuario == "pasajero" ? Colors.white : Colors.blue),
                  label: Text("Busco raite", style: TextStyle(color: tipoUsuario == "pasajero" ? Colors.white : Colors.black)),
                  selected: tipoUsuario == "pasajero",
                  selectedColor: Colors.blue,
                  onSelected: (val) => setState(() => tipoUsuario = "pasajero"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            formularioComun(),
            if (tipoUsuario == "conductor") ...[
              buildUpload("Foto placas del carro", Icons.directions_car),
              buildUpload("Foto licencia", Icons.credit_card),
              buildUpload("Foto calcomanías fiscales", Icons.verified),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                onPressed: registrarUsuario,
                icon: const Icon(Icons.app_registration, color: Colors.white),
                label: const Text("Registrarse", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}