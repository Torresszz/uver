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
  
  // Control de navegación lateral
  String _seccionActual = "Resumen";

  // URL para viajes
  final String _viajesUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  // Función para cambiar estado de usuario
  Future<void> _actualizarEstado(String email, String nuevoEstado) async {
    try {
      final exito = await _apiService.cambiarEstadoUsuario(email, nuevoEstado);
      if (exito) {
        setState(() {}); // Refrescar vista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Usuario $nuevoEstado"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // --- SIDEBAR ---
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

          // --- CONTENIDO DINÁMICO ---
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

  // Lógica de navegación interna
  Widget _obtenerVistaActual() {
    switch (_seccionActual) {
      case "Resumen":
        return _viewResumen();
      case "Conductores":
        return _viewUsuariosFiltrados("conductor");
      case "Pasajeros":
        return _viewUsuariosFiltrados("pasajero"); // También incluye 'peaton'
      case "Viajes Activos":
        return _viewViajes();
      default:
        return _viewResumen();
    }
  }

  // --- VISTA 1: RESUMEN GENERAL ---
  Widget _viewResumen() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.obtenerUsuarios(),
      builder: (context, snapshot) {
        final usuarios = snapshot.data ?? [];
        int cond = usuarios.where((u) => u['rol'] == 'conductor').length;
        int pas = usuarios.where((u) => u['rol'] != 'conductor').length;
        int pend = usuarios.where((u) => u['estado'] == 'Pendiente').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTitle("Panel de Control / Resumen"),
            Row(
              children: [
                _buildStatCard("Conductores", cond.toString(), Colors.blue),
                _buildStatCard("Pasajeros", pas.toString(), Colors.green),
                _buildStatCard("Por Validar", pend.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 30),
            _tablaCard("Todos los Usuarios", usuarios),
          ],
        );
      },
    );
  }

  // --- VISTA 2: USUARIOS FILTRADOS ---
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

  // --- VISTA 3: VIAJES ---
  Widget _viewViajes() {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse(_viajesUrl)).then((res) => jsonDecode(res.body)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final viajes = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTitle("Viajes en Tiempo Real"),
            _tablaCardViajes(viajes),
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

  Widget _buildMenuItem(IconData icon, String title, bool isSelected, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() => _seccionActual = title);
        }
      },
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

  Widget _tablaCard(String title, List<dynamic> datos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
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
          datos.isEmpty 
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay datos disponibles")))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Nombre")),
                  DataColumn(label: Text("Correo")),
                  DataColumn(label: Text("Rol")),
                  DataColumn(label: Text("Estado")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: datos.map((u) => _buildUserRow(u)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildUserRow(dynamic user) {
    String estado = user['estado'] ?? 'Pendiente';
    return DataRow(cells: [
      DataCell(Text(user['nombre'] ?? 'N/A')),
      DataCell(Text(user['email'] ?? 'N/A')),
      DataCell(Text(user['rol']?.toString().toUpperCase() ?? 'USER')),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: estado == "Pendiente" ? Colors.orange[50] : Colors.green[50], borderRadius: BorderRadius.circular(8)),
        child: Text(estado, style: TextStyle(color: estado == "Pendiente" ? Colors.orange[900] : Colors.green[900], fontWeight: FontWeight.bold, fontSize: 12)),
      )),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: estado == "Pendiente" ? () => _actualizarEstado(user['email'], "Aceptado") : null),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _actualizarEstado(user['email'], "Eliminado")),
        ],
      )),
    ]);
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