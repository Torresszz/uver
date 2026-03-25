import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // URL base para usuarios
  static const String baseUrl = 'https://uver-oxnw.vercel.app/api/usuarios';

  // 1. OBTENER TODOS LOS USUARIOS
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error de conexión (obtener): $e");
      return [];
    }
  }

  // 2. CAMBIAR ESTADO (Aceptado / Rechazado / Pendiente)
  // Esta es la que usan los botones de Check y Close en tu Dashboard
  Future<bool> cambiarEstadoUsuario(String email, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrl), // Usamos PUT para actualizar
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'estado': nuevoEstado,
        }),
      );

      // Aceptamos 200 (OK) o 204 (No Content) según como responda tu backend
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error al actualizar estado: $e");
      return false;
    }
  }

  // 3. ELIMINAR USUARIO
  Future<bool> eliminarUsuario(String email) async {
    try {
      final response = await http.delete(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al eliminar: $e");
      return false;
    }
  }

  // 4. GUARDAR NUEVO USUARIO (Registro)
  Future<bool> guardarUsuario(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(datos),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al guardar: $e");
      return false;
    }
  }

 // 5. RESERVA DE VIAJE (PASAJERO -> ENVÍA SOLICITUD)
  Future<bool> reservarViaje({
    required String viajeId, 
    required String pasajeroEmail, 
    required String pasajeroNombre
  }) async {
    try {
      final response = await http.post(
        // Cambiamos a la nueva ruta de reservar
        Uri.parse('https://uver-oxnw.vercel.app/api/reservar'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
          'pasajeroNombre': pasajeroNombre,
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error en ApiService (reservarViaje): $e");
      return false;
    }
  }

  // 6. DECIDIR SOLICITUD (CHOFER -> ACEPTA O RECHAZA)
  Future<bool> decidirSolicitud(String viajeId, String pasajeroEmail, String accion) async {
    try {
      final response = await http.post(
        // Apuntamos al nuevo archivo decidir.js
        Uri.parse('https://uver-oxnw.vercel.app/api/decidir'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'viajeId': viajeId,
          'pasajeroEmail': pasajeroEmail,
          'accion': accion, // "aceptar" o "rechazar"
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error en decidirSolicitud: $e");
      return false;
    }
  }
}