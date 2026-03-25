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

  // 1. CONTROLADORES (Para capturar los datos que verá el Dashboard)
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  // 2. FUNCIÓN DE ENVÍO A LA API
  Future<void> registrarUsuario() async {
    // URL orientada a Vercel/API local
    final url = Uri.parse('/api/users'); 

    final Map<String, dynamic> userData = {
      'nombre': _nombreController.text,
      'correo': _correoController.text,
      'telefono': _telefonoController.text,
      'rol': tipoUsuario, // "conductor" o "pasajero"
      'fecha_registro': DateTime.now().toIso8601String(),
      'estado': 'pendiente', // Útil para que el admin lo apruebe en la web
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso"), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Error en el servidor');
      }
    } catch (e) {
      // Fallback por si no tienes el backend listo aún: imprimimos el JSON
      debugPrint("==== JSON PARA EL DASHBOARD WEB ====");
      debugPrint(jsonEncode(userData));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e (JSON impreso en consola)")),
      );
    }
  }

  // 3. INPUT MODIFICADO (Ahora recibe un controller)
  Widget buildInput(String label, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller, // <-- Conexión clave
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
      appBar: AppBar(title: const Text("Registro"), backgroundColor: Colors.blue),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.directions_car, color: Colors.white),
                  label: const Text("Tengo carro"),
                  selected: tipoUsuario == "conductor",
                  selectedColor: Colors.blue,
                  onSelected: (val) => setState(() => tipoUsuario = "conductor"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  avatar: const Icon(Icons.person, color: Colors.white),
                  label: const Text("Busco raite"),
                  selected: tipoUsuario == "pasajero",
                  selectedColor: Colors.blue,
                  onSelected: (val) => setState(() => tipoUsuario = "pasajero"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            formularioComun(), // Campos que ambos comparten
            if (tipoUsuario == "conductor") ...[
              buildUpload("Foto placas del carro", Icons.directions_car),
              buildUpload("Foto licencia", Icons.credit_card),
              buildUpload("Foto calcomanías fiscales", Icons.verified),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: registrarUsuario, // <-- Conectado a la API
              icon: const Icon(Icons.app_registration, color: Colors.white),
              label: const Text("Registrarse", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}