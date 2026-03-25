import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Esta es la URL de tu API en Vercel que acabamos de arreglar
  static const String baseUrl = 'https://uver-oxnw.vercel.app/api/usuarios';

  // Función para obtener los usuarios
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar usuarios');
      }
    } catch (e) {
      print("Error de conexión: $e");
      return [];
    }
  }

  // Función para guardar un nuevo usuario (conductor)
  Future<bool> guardarUsuario(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(datos),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al guardar: $e");
      return false;
    }
  }
}