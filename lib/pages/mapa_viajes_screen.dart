import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../pages/home_page.dart';
import '../widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Para manejar horas y fechas

class MapaViajesScreen extends StatefulWidget {

  final LatLng? centroInicial;
  const MapaViajesScreen({super.key, this.centroInicial});

  @override
  State<MapaViajesScreen> createState() => _MapaViajesScreenState();
}

class _MapaViajesScreenState extends State<MapaViajesScreen> {
  // URL de tu API de viajes en Vercel
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  Future<List<dynamic>> obtenerViajes() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> todosLosViajes = jsonDecode(response.body);
        
        // --- LÓGICA DE CADUCIDAD ---
        // Filtramos para que solo aparezcan viajes cuya hora no haya pasado
        DateTime ahora = DateTime.now();
        
        return todosLosViajes.where((viaje) {
          try {
            // Asumimos que guardamos 'fecha_publicacion' o un campo 'hora' ISO8601
            // Si guardas solo texto como "08:30 PM", la lógica requiere un parseo más complejo
            DateTime fechaViaje = DateTime.parse(viaje['fecha_publicacion'] ?? ahora.toString());
            return fechaViaje.isAfter(ahora.subtract(const Duration(hours: 2))); // Ejemplo: Caduca 2h después
          } catch (e) {
            return true; // Si hay error de formato, lo mostramos por si acaso
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
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                title: Text("${viaje['origen']} ➔ ${viaje['destino']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text("Sale a las: ${viaje['hora']}"),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _datoExtra(Icons.attach_money, "Cuota", "\$${viaje['cuota']}"),
                  _datoExtra(Icons.people, "Lugares", "${viaje['capacidad']}"),
                  _datoExtra(Icons.timer, "Duración", "${viaje['duracion']}"),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Contactar Conductor", style: TextStyle(color: Colors.white)),
              )
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
        title: const Text("Explorar Raites", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

          // Generar marcadores
          List<Marker> marcadores = (snapshot.data ?? []).map((viaje) {
            // Coordenadas por defecto (Colima) si no hay reales
            double lat = viaje['latitud'] ?? 19.2620 + (0.005 * (viaje['id'] % 10)); 
            double lng = viaje['longitud'] ?? -103.7229 + (0.005 * (viaje['id'] % 5));

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
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 25),
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
        onPressed: () => setState(() {}), // Refrescar mapa
        child: const Icon(Icons.refresh, color: Colors.blue),
      ),
    );
  }
}