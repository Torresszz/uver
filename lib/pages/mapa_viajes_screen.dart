import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapaViajesScreen extends StatefulWidget {
  const MapaViajesScreen({super.key});

  @override
  State<MapaViajesScreen> createState() => _MapaViajesScreenState();
}

class _MapaViajesScreenState extends State<MapaViajesScreen> {
  // Variable para el filtro
  String filtroActual = "Todos";

  // 1. CONSUMO DE LA API (GET)
  Future<List<dynamic>> obtenerViajes() async {
  // Al usar solo '/api/reports', funcionará perfecto en Vercel
  // Para probar local, asegúrate de que tu server node corra en el mismo dominio
  final url = Uri.parse('/api/reports'); 
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  } catch (e) {
    // Si falla la ruta relativa (en local), puedes poner un fallback
    print("Error conectando: $e");
    return []; 
  }
}

  // 2. INTERACTIVIDAD: BOTTOM SHEET CON FOTO BASE64
  void _mostrarDetalleViaje(BuildContext context, dynamic viaje) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Viaje #${viaje['id']} - ${viaje['tipo_incidente']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text("Descripción: ${viaje['descripcion']}"),
              Text("Fecha: ${viaje['fecha_hora']}"),
              const SizedBox(height: 15),
              const Text(
                "Evidencia fotográfica:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Aquí decodificamos el Base64 que viene de la API para mostrar la imagen
              Center(
                child:
                    viaje['foto_base64'] != null &&
                        viaje['foto_base64'].isNotEmpty
                    ? Image.memory(
                        base64Decode(viaje['foto_base64']),
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.broken_image, size: 50),
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mapa de Raites",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // 3. FILTROS RÁPIDOS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text("Todos"),
                  selected: filtroActual == "Todos",
                  onSelected: (val) => setState(() => filtroActual = "Todos"),
                ),
                FilterChip(
                  label: const Text("Solo Raites"),
                  selected: filtroActual == "Publicación de Raite",
                  onSelected: (val) =>
                      setState(() => filtroActual = "Publicación de Raite"),
                ),
              ],
            ),
          ),

          // USO DE FUTUREBUILDER (Regla de Oro del Sprint)
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: obtenerViajes(),
              builder: (context, snapshot) {
                // Si está cargando, mostramos el indicador
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Cargando Mapa y Viajes..."),
                      ],
                    ),
                  );
                }

                // Si hay error
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Si no hay datos
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No hay viajes publicados aún."),
                  );
                }

                // Aplicar el filtro a la lista de datos
                List<dynamic> viajesFiltrados = snapshot.data!;
                if (filtroActual != "Todos") {
                  viajesFiltrados = viajesFiltrados
                      .where((v) => v['tipo_incidente'] == filtroActual)
                      .toList();
                }

                // ========================================================
                // FRAGMENTO DE CÓDIGO PARA EL ENTREGABLE (El .map)
                // ========================================================
                List<Marker> marcadores = viajesFiltrados.map((viaje) {
                  // Validar que las coordenadas sean números válidos
                  double lat =
                      double.tryParse(viaje['latitud'].toString()) ?? 19.2433;
                  double lng =
                      double.tryParse(viaje['longitud'].toString()) ??
                      -103.7256;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _mostrarDetalleViaje(context, viaje),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  );
                }).toList();
                // ========================================================

                return FlutterMap(
                  options: MapOptions(
                    // Centro inicial en Colima
                    initialCenter: const LatLng(19.2620, -103.7229),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.routemate',
                    ),
                    MarkerLayer(markers: marcadores),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
