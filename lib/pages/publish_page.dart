import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _horaController = TextEditingController();
  final _cuotaController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _duracionController = TextEditingController();

  // URL de tu nueva API de viajes
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    _horaController.dispose();
    _cuotaController.dispose();
    _capacidadController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> enviarReporte(BuildContext context) async {
    // Validación básica
    if (_origenController.text.isEmpty || _destinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Origen y Destino son obligatorios")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Publicando viaje...")),
    );

    final Map<String, dynamic> requestBody = {
      'origen': _origenController.text,
      'destino': _destinoController.text,
      'hora': _horaController.text,
      'cuota': _cuotaController.text,
      'capacidad': _capacidadController.text,
      'duracion': _duracionController.text,
      'fecha_publicacion': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Viaje publicado con éxito!"), backgroundColor: Colors.green),
        );
        
        // Limpiar formulario
        _origenController.clear();
        _destinoController.clear();
        _horaController.clear();
        _cuotaController.clear();
        _capacidadController.clear();
        _duracionController.clear();
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }
  }

  // Tu widget buildInput se mantiene igual...
  Widget buildInput(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar viaje', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildInput("Origen", Icons.location_on, _origenController),
            buildInput("Destino", Icons.flag, _destinoController),
            buildInput("Hora", Icons.access_time, _horaController),
            buildInput("Cuota de recuperación", Icons.attach_money, _cuotaController, type: TextInputType.number),
            buildInput("Capacidad", Icons.people, _capacidadController, type: TextInputType.number),
            buildInput("Duración del viaje", Icons.timer, _duracionController),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => enviarReporte(context),
              icon: const Icon(Icons.send),
              label: const Text('Publicar Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}