enum UserRole { conductor, peaton, admin }

class UserModel {
  final String id;
  final String nombre;
  final String correo;
  final UserRole rol;
  final String? vehiculo;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.vehiculo,
  });

  // Convertir de JSON (Base de datos) a Objeto Dart
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] == 'conductor' 
          ? UserRole.conductor 
          : (data['rol'] == 'admin' ? UserRole.admin : UserRole.peaton),
      vehiculo: data['vehiculo'],
    );
  }

  // VITAL PARA EL DASHBOARD: Convertir de Objeto Dart a JSON para enviar a la web
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol.name, // Guarda "conductor", "peaton" o "admin" como String
      'vehiculo': vehiculo,
    };
  }
}