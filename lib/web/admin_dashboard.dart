import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // 1. SIDEBAR (Menú lateral fijo)
          Container(
            width: 250,
            color: Colors.blue.shade900,
            child: Column(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text("RouteMate ADMIN", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildMenuItem(Icons.dashboard, "Resumen", true),
                _buildMenuItem(Icons.directions_car, "Conductores", false),
                _buildMenuItem(Icons.person, "Pasajeros", false),
                _buildMenuItem(Icons.map, "Viajes Activos", false),
                const Spacer(),
                _buildMenuItem(Icons.logout, "Cerrar Sesión", false),
              ],
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Panel de Control", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // FILA DE TARJETAS DE MÉTRICAS
                  Row(
                    children: [
                      _buildStatCard("Conductores", "24", Colors.blue),
                      _buildStatCard("Pasajeros", "150", Colors.green),
                      _buildStatCard("Viajes Hoy", "12", Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // TABLA DE USUARIOS REGISTRADOS
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Usuarios Pendientes de Aprobación", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        DataTable(
                          columns: const [
                            DataColumn(label: Text("Nombre")),
                            DataColumn(label: Text("Correo")),
                            DataColumn(label: Text("Rol")),
                            DataColumn(label: Text("Estado")),
                            DataColumn(label: Text("Acciones")),
                          ],
                          rows: [
                            _buildDataRow("Juan Pérez", "juan@mail.com", "Conductor", "Pendiente"),
                            _buildDataRow("Maria Sol", "maria@mail.com", "Pasajero", "Activo"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS AUXILIARES PARA LIMPIEZA DE CÓDIGO
  Widget _buildMenuItem(IconData icon, String title, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {},
      selected: isSelected,
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(String nombre, String correo, String rol, String estado) {
    return DataRow(cells: [
      DataCell(Text(nombre)),
      DataCell(Text(correo)),
      DataCell(Text(rol)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: estado == "Pendiente" ? Colors.orange[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(estado, style: TextStyle(color: estado == "Pendiente" ? Colors.orange[900] : Colors.green[900])),
      )),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
        ],
      )),
    ]);
  }
}