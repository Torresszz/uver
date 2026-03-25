enum UserRole { conductor, peaton, admin }

class UserModel {
  final String id;
  final String nombre;
  final String correo;
  final UserRole rol;
  final String? vehiculo;
  final String estado; // "Pendiente", "Aprobado", "Rechazado"

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.vehiculo,
    this.estado = "Pendiente", // Por defecto al registrarse
  });

  // Convertir de JSON (Vercel KV) a Objeto Dart
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id']?.toString() ?? '',
      nombre: data['nombre'] ?? 'Sin nombre',
      // IMPORTANTE: En el dashboard usamos 'email', asegúrate de que sea consistente
      correo: data['email'] ?? data['correo'] ?? '', 
      rol: _parseRole(data['rol']),
      vehiculo: data['vehiculo'],
      estado: data['estado'] ?? 'Pendiente',
    );
  }

  // Lógica de apoyo para el Rol
  static UserRole _parseRole(String? rolStr) {
    if (rolStr == 'conductor') return UserRole.conductor;
    if (rolStr == 'admin') return UserRole.admin;
    return UserRole.peaton;
  }

  // Para enviar a Vercel/API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': correo, // Usamos 'email' para que el Dashboard lo lea bien
      'rol': rol.name, 
      'vehiculo': vehiculo,
      'estado': estado,
      'fecha_registro': DateTime.now().toIso8601String(),
    };
  }
}