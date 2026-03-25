import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';

class MisSolicitudes extends StatefulWidget {
  const MisSolicitudes({super.key});

  @override
  State<MisSolicitudes> createState() => _MisSolicitudesState();
}

class _MisSolicitudesState extends State<MisSolicitudes> {
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
      final response = await http.get(Uri.parse('https://uver-oxnw.vercel.app/api/viajes'));
      if (response.statusCode == 200) {
        List<dynamic> todosLosViajes = json.decode(response.body);
        List<dynamic> filtrados = [];

        // Buscamos los viajes donde YO aparezco en la lista de pasajeros
        for (var viaje in todosLosViajes) {
          List pasajeros = viaje['pasajeros'] ?? [];
          var yoComoPasajero = pasajeros.firstWhere(
            (p) => p['email'] == _miEmail,
            orElse: () => null,
          );

          if (yoComoPasajero != null) {
            // Guardamos el viaje junto con MI estado específico en ese viaje
            filtrados.add({
              'destino': viaje['destino'],
              'origen': viaje['origen'],
              'hora': viaje['hora'],
              'conductor': viaje['conductorNombre'] ?? 'Conductor',
              'miEstado': yoComoPasajero['estado'], // 'pendiente' o 'confirmado'
            });
          }
        }

        setState(() {
          _misRaites = filtrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Solicitudes de Raite"),
        backgroundColor: Colors.blue.shade800,
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
                      final bool esAceptado = raite['miEstado'] == 'confirmado';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: esAceptado ? Colors.green : Colors.orange.shade100,
                            child: Icon(
                              esAceptado ? Icons.check : Icons.timer_outlined,
                              color: esAceptado ? Colors.white : Colors.orange,
                            ),
                          ),
                          title: Text(
                            "Destino: ${raite['destino']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Origen: ${raite['origen']}"),
                              Text("Conductor: ${raite['conductor']}"),
                              Text("Hora: ${raite['hora']}"),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: esAceptado ? Colors.green.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  esAceptado ? "SOLICITUD ACEPTADA ✅" : "ESPERANDO CONFIRMACIÓN ⏳",
                                  style: TextStyle(
                                    color: esAceptado ? Colors.green.shade700 : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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
          Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("No has solicitado ningún raite aún", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}