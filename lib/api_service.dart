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

  // 1. Reservar (Pasajero envía solicitud inicial)
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
          'estado': 'pendiente',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en reservarViaje: $e");
      return false;
    }
  }

  // 2. Decidir (Conductor acepta o rechaza)
  Future<bool> decidirSolicitud(String viajeId, String pasajeroEmail, String accion) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrlViajes/decidir'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
          'accion': accion, // 'aceptar' o 'rechazar'
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error en decidirSolicitud: $e");
      return false;
    }
  }

  // 3. Cancelar (Pasajero se arrepiente y se elimina de la lista)
  Future<bool> cancelarSolicitud(String viajeId, String pasajeroEmail) async {
    try {
      final response = await http.delete(
        Uri.parse('https://uver-oxnw.vercel.app/api/viajes/cancelar-reserva'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
        }),
      );
      // Retornamos true si el servidor confirma la eliminación
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error en cancelarSolicitud: $e");
      return false;
    }
  }
}