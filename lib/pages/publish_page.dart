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
  // 1. CONTROLADORES PARA CAPTURAR EL TEXTO
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _horaController = TextEditingController();
  final _cuotaController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _duracionController = TextEditingController();

  // Limpiar controladores al cerrar la pantalla para evitar fugas de memoria
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

  // 2. INPUT MODIFICADO (Ahora acepta un controller)
  Widget buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller, // <--- Conexión clave
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> enviarReporte(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Enviando publicación..."),
          ],
        ),
      ),
    );

    // 3. PAYLOAD DINÁMICO (Usando los valores de los controladores)
    final Map<String, dynamic> requestBody = {
      'tipo_incidente': 'Publicación de Raite',
      'latitud': 19.2620, // Aquí podrías usar geolocalización real después
      'longitud': -103.7229,
      'fecha_hora': DateTime.now().toIso8601String(),
      'descripcion': 'Viaje de ${_origenController.text} a ${_destinoController.text}',
      'detalles': {
        'origen': _origenController.text,
        'destino': _destinoController.text,
        'hora': _horaController.text,
        'cuota': _cuotaController.text,
        'capacidad': _capacidadController.text,
        'duracion': _duracionController.text,
      },
      'foto_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    };

    try {
      // Nota: Cambia esta URL por la de tu backend real o tu IP local
      final url = Uri.parse('/api/reports'); 
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Viaje publicado con éxito!"), backgroundColor: Colors.green),
        );
        // Opcional: Limpiar campos después de enviar
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint("Error: $e");
      // Si falla la red, al menos vemos el JSON en consola para el Dashboard
      debugPrint("JSON generado: ${jsonEncode(requestBody)}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión. Revisa la consola.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar viaje'), backgroundColor: Colors.blue),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => enviarReporte(context),
              icon: const Icon(Icons.send),
              label: const Text('Publicar Viaje', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}