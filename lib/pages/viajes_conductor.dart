import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/app_drawer.dart';
import '../api_service.dart';

class MisViajesConductor extends StatefulWidget {
  const MisViajesConductor({super.key});

  @override
  State<MisViajesConductor> createState() => _MisViajesConductorState();
}

class _MisViajesConductorState extends State<MisViajesConductor> {
  final ApiService _apiService = ApiService();
  List<dynamic> _misViajes = [];
  bool _isLoading = true;
  String _emailConductor = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosYViajes();
  }

  // Carga el email de SharedPreferences y luego los viajes de la API
  Future<void> _cargarDatosYViajes() async {
    final prefs = await SharedPreferences.getInstance();
    _emailConductor = prefs.getString('userEmail') ?? "";
    
    try {
      final response = await http.get(Uri.parse('https://uver-oxnw.vercel.app/api/viajes'));
      if (response.statusCode == 200) {
        List<dynamic> todos = json.decode(response.body);
        setState(() {
          // Filtramos: Solo viajes donde el conductorEmail sea el logueado
          _misViajes = todos.where((v) => v['conductorEmail'] == _emailConductor).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando viajes: $e");
      setState(() => _isLoading = false);
    }
  }

  // Envía la decisión a la API y refresca la vista
  void _procesarSolicitud(String viajeId, String pEmail, String accion) async {
    bool exito = await _apiService.decidirSolicitud(viajeId, pEmail, accion);
    if (exito) {
      _cargarDatosYViajes(); // Refrescar datos para ver el cambio de estado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Solicitud ${accion}ada correctamente"),
            backgroundColor: accion == "aceptar" ? Colors.green : Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al procesar la solicitud")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Gestión de Mis Viajes"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _misViajes.isEmpty 
          ? const Center(child: Text("Aún no has publicado ningún viaje."))
          : RefreshIndicator(
              onRefresh: _cargarDatosYViajes,
              child: ListView.builder(
                itemCount: _misViajes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  var viaje = _misViajes[index];
                  List pasajeros = viaje['pasajeros'] ?? [];
                  // ID de Vercel KV suele ser 'id' o '_id'
                  String vId = (viaje['id'] ?? viaje['_id']).toString();

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: Icon(Icons.directions_car, color: Colors.blue.shade800),
                      title: Text(
                        "Hacia: ${viaje['destino']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Cupo: ${pasajeros.length} / ${viaje['capacidad']}"),
                      children: [
                        if (pasajeros.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Nadie ha solicitado unirse todavía.", 
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          ),
                        ...pasajeros.map<Widget>((p) {
                          final bool esConfirmado = p['estado'] == 'confirmado';
                          final Color colorEstado = esConfirmado ? Colors.green : Colors.orange;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.08),
                              border: Border.all(color: colorEstado, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorEstado,
                                child: Icon(
                                  esConfirmado ? Icons.check : Icons.access_time,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(p['nombre'] ?? "Pasajero", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${p['email']}\nEstado: ${p['estado']?.toUpperCase()}"),
                              isThreeLine: true,
                              trailing: !esConfirmado 
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                        onPressed: () => _procesarSolicitud(vId, p['email'], "aceptar"),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                                        onPressed: () => _procesarSolicitud(vId, p['email'], "rechazar"),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.verified, color: Colors.green, size: 28),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}