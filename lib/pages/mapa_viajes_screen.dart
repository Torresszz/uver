import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapaViajesScreen extends StatefulWidget {
  final LatLng? centroInicial;
  const MapaViajesScreen({super.key, this.centroInicial});

  @override
  State<MapaViajesScreen> createState() => _MapaViajesScreenState();
}

class _MapaViajesScreenState extends State<MapaViajesScreen> {
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  // Instancia del servicio para realizar la reserva
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> obtenerViajes() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> todosLosViajes = jsonDecode(response.body);

        // Lógica de filtrado por tiempo (opcional según tu API)
        DateTime ahora = DateTime.now();
        return todosLosViajes.where((viaje) {
          try {
            DateTime fechaViaje = DateTime.parse(
              viaje['fecha_publicacion'] ?? ahora.toString(),
            );
            return fechaViaje.isAfter(ahora.subtract(const Duration(hours: 2)));
          } catch (e) {
            return true;
          }
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error conectando al mapa: $e");
      return [];
    }
  }

  void _mostrarDetalleViaje(BuildContext context, dynamic viaje) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  "${viaje['origen']} ➔ ${viaje['destino']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text("Sale a las: ${viaje['hora']}"),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _datoExtra(
                    Icons.attach_money,
                    "Cuota",
                    "\$${viaje['cuota']}",
                  ),
                  _datoExtra(Icons.people, "Lugares", "${viaje['capacidad']}"),
                  _datoExtra(Icons.timer, "Duración", "${viaje['duracion']}"),
                ],
              ),
              const SizedBox(height: 25),

              // BOTÓN DE RESERVA (REEMPLAZA AL DE CORREO)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.event_seat),
                label: const Text(
                  "Reservar Asiento",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final String viajeId = viaje['id'].toString();
                  final String destino = viaje['destino'] ?? "tu destino";

                  // 1. Obtener datos usando los nombres que definiste en el Login
                  final prefs = await SharedPreferences.getInstance();

                  // AQUÍ ESTÁ EL CAMBIO: Usamos 'userEmail' y 'userName'
                  final String? emailPasajero = prefs.getString('userEmail');
                  final String? nombrePasajero = prefs.getString('userName');

                  if (emailPasajero == null || nombrePasajero == null) {
                    // Si falla, mostramos qué falta para debuguear
                    print(
                      "DEBUG: Email: $emailPasajero, Nombre: $nombrePasajero",
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error: No se encontró sesión activa."),
                      ),
                    );
                    return;
                  }

                  // ... resto del código del diálogo y la llamada a _apiService

                  // 2. Diálogo de confirmación
                  bool confirmar =
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirmar Reserva"),
                          content: Text(
                            "¿$nombrePasajero, quieres apartar tu lugar a $destino?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                "Confirmar",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (confirmar) {
                    try {
                      // 3. Llamada corregida con los 3 parámetros NOMBRADOS
                      final exito = await _apiService.reservarViaje(
                        viajeId: viajeId,
                        pasajeroEmail: emailPasajero,
                        pasajeroNombre:
                            nombrePasajero, // <-- Ahora sí pasamos el nombre
                      );

                      if (exito) {
                        Navigator.pop(context); // Cierra el detalle del viaje
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("¡Lugar apartado con éxito!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        throw Exception("Error en el servidor");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No se pudo completar la reserva"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _datoExtra(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Explorar Raites",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<dynamic>>(
        future: obtenerViajes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Marker> marcadores = (snapshot.data ?? []).map((viaje) {
            double lat = viaje['latitud'] ?? 19.2620;
            double lng = viaje['longitud'] ?? -103.7229;

            return Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _mostrarDetalleViaje(context, viaje),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(19.2620, -103.7229),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.routemate',
              ),
              MarkerLayer(markers: marcadores),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => setState(() {}),
        child: const Icon(Icons.refresh, color: Colors.blue),
      ),
    );
  }
}
