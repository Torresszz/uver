import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';
import '../api_service.dart';

class MisSolicitudes extends StatefulWidget {
  const MisSolicitudes({super.key});

  @override
  State<MisSolicitudes> createState() => _MisSolicitudesState();
}

class _MisSolicitudesState extends State<MisSolicitudes> {
  final ApiService _apiService = ApiService();
  List<dynamic> _misRaites = [];
  bool _isLoading = true;
  String _miEmail = "";

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    final prefs = await SharedPreferences.getInstance();
    _miEmail = prefs.getString('userEmail') ?? "";

    try {
      final response = await http.get(
        Uri.parse('https://uver-oxnw.vercel.app/api/viajes'),
      );
      if (response.statusCode == 200) {
        List<dynamic> todosLosViajes = json.decode(response.body);
        List<dynamic> filtrados = [];

        for (var viaje in todosLosViajes) {
          List pasajeros = viaje['pasajeros'] ?? [];

          var yoComoPasajero = pasajeros.firstWhere(
            (p) =>
                p['email'].toString().toLowerCase() == _miEmail.toLowerCase(),
            orElse: () => null,
          );

          if (yoComoPasajero != null) {
            filtrados.add({
              'id': (viaje['id'] ?? viaje['_id']).toString(),
              'destino': viaje['destino'] ?? 'Sin destino',
              'origen': viaje['origen'] ?? 'Sin origen',
              'hora': viaje['hora'] ?? '--:--',
              'conductor':
                  viaje['conductor'] ?? viaje['conductorNombre'] ?? 'Anon',
              'miEstado': yoComoPasajero['estado'] ?? 'pendiente',
            });
          }
        }

        setState(() {
          _misRaites = filtrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando solicitudes: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _intentarCancelar(String viajeId, bool esRechazado) async {
    // Si ya está rechazado, no preguntamos "cancelar", sino "eliminar del historial"
    String titulo = esRechazado
        ? "¿Eliminar del historial?"
        : "¿Cancelar solicitud?";
    String mensaje = esRechazado
        ? "Esta notificación desaparecerá de tu lista."
        : "Ya no aparecerás en la lista del conductor para este viaje.";

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("VOLVER"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("SÍ, ELIMINAR"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      bool exito = await _apiService.cancelarSolicitud(viajeId, _miEmail);

      if (exito) {
        _cargarSolicitudes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                esRechazado ? "Registro eliminado" : "Solicitud cancelada",
              ),
              backgroundColor: esRechazado ? Colors.black87 : Colors.redAccent,
              behavior: SnackBarBehavior.floating, // Se ve más moderno
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al procesar la acción")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Solicitudes de Raite"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _misRaites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _cargarSolicitudes,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _misRaites.length,
                itemBuilder: (context, index) {
                  final raite = _misRaites[index];
                  final String estado = raite['miEstado']
                      .toString()
                      .toLowerCase();

                  // Lógica de colores e iconos por estado
                  IconData iconoEstado;
                  String textoEstado;
                  final MaterialColor colorEstado;

                  if (estado == 'confirmado') {
                    colorEstado = Colors.green;
                    iconoEstado = Icons.check_circle;
                    textoEstado = "SOLICITUD ACEPTADA ✅";
                  } else if (estado == 'rechazado') {
                    colorEstado = Colors.red;
                    iconoEstado = Icons.cancel;
                    textoEstado = "SOLICITUD RECHAZADA ❌";
                  } else {
                    colorEstado = Colors.orange;
                    iconoEstado = Icons.timer_outlined;
                    textoEstado = "ESPERANDO CONFIRMACIÓN ⏳";
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: colorEstado.withOpacity(0.1),
                        child: Icon(iconoEstado, color: colorEstado),
                      ),
                      title: Text(
                        "Hacia: ${raite['destino']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text("Origen: ${raite['origen']}"),
                          Text("Conductor: ${raite['conductor']}"),
                          Text("Hora: ${raite['hora']}"),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              textoEstado,
                              style: TextStyle(
                                color: colorEstado.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          estado == 'rechazado'
                              ? Icons.delete_forever
                              : Icons.delete_sweep,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _intentarCancelar(
                          raite['id'],
                          estado == 'rechazado',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No tienes solicitudes activas",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
