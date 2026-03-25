import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // URLs base
  static const String baseUrlUsuarios = 'https://uver-oxnw.vercel.app/api/usuarios';
  static const String baseUrlViajes = 'https://uver-oxnw.vercel.app/api/viajes';

  // ---------------------------------------------------------
  // SECCIÓN: USUARIOS (ADMINISTRACIÓN)
  // ---------------------------------------------------------

  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final response = await http.get(Uri.parse(baseUrlUsuarios));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      debugPrint("Error de conexión (obtenerUsuarios): $e");
      return [];
    }
  }

  Future<bool> cambiarEstadoUsuario(String email, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrlUsuarios),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'estado': nuevoEstado}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error al actualizar estado usuario: $e");
      return false;
    }
  }

  Future<bool> eliminarUsuario(String email) async {
    try {
      final response = await http.delete(
        Uri.parse(baseUrlUsuarios),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error al eliminar usuario: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // SECCIÓN: VIAJES Y RESERVAS
  // ---------------------------------------------------------

  // 1. Reservar (Pasajero envía solicitud inicial) -> Apunta a api/reservas.js
  Future<bool> reservarViaje({
    required String viajeId,
    required String pasajeroEmail,
    required String pasajeroNombre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://uver-oxnw.vercel.app/api/reservas'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
          'pasajeroNombre': pasajeroNombre,
          // 'estado': 'pendiente', // El backend ya lo asigna por defecto, pero no estorba
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en reservarViaje: $e");
      return false;
    }
  }

  // 2. Decidir (Conductor acepta o rechaza) -> Apunta a api/decidir.js
  Future<bool> decidirSolicitud(String viajeId, String pasajeroEmail, String accion) async {
    try {
      final response = await http.post(
        // CORRECCIÓN: Quitamos el '/viajes' de la ruta
        Uri.parse('https://uver-oxnw.vercel.app/api/decidir'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
          'accion': accion, // 'aceptar' o 'rechazar'
        }),
      );
      
      if (response.statusCode != 200) {
        debugPrint("Error API decidir: ${response.statusCode} - ${response.body}");
      }
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error en decidirSolicitud: $e");
      return false;
    }
  }

  //Cancelar Solicitud
  Future<bool> cancelarSolicitud(String viajeId, String pasajeroEmail) async {
  try {
    final response = await http.delete(
      Uri.parse('https://uver-oxnw.vercel.app/api/cancelar-reserva'),
      headers: {
        'Content-Type': 'application/json', // <--- OBLIGATORIO para que el body se lea
      },
      body: json.encode({
        'viajeId': viajeId,
        'pasajeroEmail': pasajeroEmail,
      }),
    );
    
    if (response.statusCode != 200) {
      debugPrint("Error al cancelar: ${response.body}");
    }
    
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Error en cancelarSolicitud: $e");
    return false;
  }
}
}