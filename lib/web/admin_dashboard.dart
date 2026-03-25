import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  String _seccionActual = "Resumen";
  final String _viajesUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  // --- 1. FUNCIÓN PARA ELIMINAR USUARIO REAL (API) ---
  Future<void> _eliminarUsuarioReal(String email) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar permanentemente?"),
        content: Text("Esta acción borrará a $email de la base de datos de Vercel."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      final exito = await _apiService.eliminarUsuario(email);
      if (exito) {
        setState(() {}); // Refrescar la vista actual
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario eliminado con éxito"), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al eliminar el usuario"), backgroundColor: Colors.orange),
        );
      }
    }
  }

 // --- 1. FUNCIÓN PARA MOSTRAR CUALQUIER DOC BASE64 ---
void _mostrarDocumento(String? base64String, String tipoDoc, String nombre) {
  if (base64String == null || base64String.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("El usuario no subió $tipoDoc")),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("$tipoDoc de $nombre"),
      content: SizedBox(
        width: 500,
        height: 500,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
              const Center(child: Text("Error: El formato de imagen no es válido")),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar")),
      ],
    ),
  );
}

// --- 2. TABLA ACTUALIZADA CON TRES ICONOS ---
Widget _tablaCard(String title, List<dynamic> datos) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(15), 
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
          ],
        ),
        const Divider(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Nombre")),
              DataColumn(label: Text("Correo")),
              DataColumn(label: Text("Rol")),
              DataColumn(label: Text("Documentación")), // INE | PLACAS | LIC
              DataColumn(label: Text("Acciones")),
            ],
            rows: datos.map((u) {
              bool esConductor = u['rol'] == 'conductor';
              return DataRow(cells: [
                DataCell(Text(u['nombre'] ?? 'N/A')),
                DataCell(Text(u['email'] ?? 'N/A')),
                DataCell(Text(u['rol']?.toString().toUpperCase() ?? 'N/A')),
                DataCell(
                  Row(
                    children: [
                      // ICONO 1: INE (Para todos)
                      IconButton(
                        icon: Icon(Icons.badge, color: u['foto_ine'] != null ? Colors.blue : Colors.grey),
                        onPressed: () => _mostrarDocumento(u['foto_ine'], "INE", u['nombre']),
                        tooltip: "Ver INE",
                      ),
                      // ICONO 2: PLACAS (Solo conductores)
                      if (esConductor)
                        IconButton(
                          icon: Icon(Icons.minor_crash, color: u['foto_placas'] != null ? Colors.orange : Colors.grey),
                          onPressed: () => _mostrarDocumento(u['foto_placas'], "Placas", u['nombre']),
                          tooltip: "Ver Placas/Tarjeta",
                        ),
                      // ICONO 3: LICENCIA (Solo conductores)
                      if (esConductor)
                        IconButton(
                          icon: Icon(Icons.contact_page, color: u['foto_licencia'] != null ? Colors.green : Colors.grey),
                          onPressed: () => _mostrarDocumento(u['foto_licencia'], "Licencia", u['nombre']),
                          tooltip: "Ver Licencia",
                        ),
                    ],
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarUsuarioReal(u['email']),
                  )
                ),
              ]);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 260,
            color: Colors.blue.shade900,
            child: Column(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text("RouteMate ADMIN", 
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildMenuItem(Icons.dashboard, "Resumen", _seccionActual == "Resumen"),
                _buildMenuItem(Icons.directions_car, "Conductores", _seccionActual == "Conductores"),
                _buildMenuItem(Icons.person, "Pasajeros", _seccionActual == "Pasajeros"),
                _buildMenuItem(Icons.map, "Viajes Activos", _seccionActual == "Viajes Activos"),
                const Spacer(),
                _buildMenuItem(Icons.logout, "Cerrar Sesión", false, isLogout: true),
              ],
            ),
          ),

          // CONTENIDO DINÁMICO
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(35),
              child: _obtenerVistaActual(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _obtenerVistaActual() {
    switch (_seccionActual) {
      case "Resumen": return _viewResumen();
      case "Conductores": return _viewUsuariosFiltrados("conductor");
      case "Pasajeros": return _viewUsuariosFiltrados("pasajero");
      case "Viajes Activos": return _viewViajes();
      default: return _viewResumen();
    }
  }

  // --- VISTAS ESPECÍFICAS ---

  Widget _viewResumen() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.obtenerUsuarios(),
      builder: (context, snapshot) {
        final usuarios = snapshot.data ?? [];
        int cond = usuarios.where((u) => u['rol'] == 'conductor').length;
        int pas = usuarios.where((u) => u['rol'] != 'conductor').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTitle("Panel de Control / Resumen"),
            Row(
              children: [
                _buildStatCard("Conductores", cond.toString(), Colors.blue),
                _buildStatCard("Pasajeros", pas.toString(), Colors.green),
              ],
            ),
            const SizedBox(height: 30),
            _tablaCard("Todos los Usuarios", usuarios),
          ],
        );
      },
    );
  }

  Widget _viewUsuariosFiltrados(String rol) {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.obtenerUsuarios(),
      builder: (context, snapshot) {
        final todos = snapshot.data ?? [];
        final filtrados = todos.where((u) => 
          rol == "conductor" ? u['rol'] == "conductor" : u['rol'] != "conductor"
        ).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTitle("Gestión de ${rol.toUpperCase()}S"),
            _tablaCard("Listado de $rol", filtrados),
          ],
        );
      },
    );
  }

  Widget _viewViajes() {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse(_viajesUrl)).then((res) => jsonDecode(res.body)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTitle("Viajes en Tiempo Real"),
            _tablaCardViajes(snapshot.data!),
          ],
        );
      },
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _headerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(right: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() => _seccionActual = title);
        }
      },
    );
  }

  Widget _tablaCardViajes(List<dynamic> viajes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Conductor")),
          DataColumn(label: Text("Origen")),
          DataColumn(label: Text("Destino")),
          DataColumn(label: Text("Cupo")),
        ],
        rows: viajes.map((v) => DataRow(cells: [
          DataCell(Text(v['conductor'] ?? 'Anon')),
          DataCell(Text(v['origen'] ?? 'N/A')),
          DataCell(Text(v['destino'] ?? 'N/A')),
          DataCell(Text("${v['capacidad'] ?? '0'}")),
        ])).toList(),
      ),
    );
  }
}