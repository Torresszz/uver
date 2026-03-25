import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Necesario para el mapa
import 'package:latlong2/latlong.dart'; // Necesario para las coordenadas
import '../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _horaController = TextEditingController();
  final _cuotaController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _duracionController = TextEditingController();

  // Variables para el Mapa (Opción A)
  // Iniciamos en el centro de Colima
  LatLng _puntoSeleccionado = const LatLng(19.2433, -103.725);
  final MapController _mapController = MapController();

  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    _horaController.dispose();
    _cuotaController.dispose();
    _capacidadController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> enviarReporte(BuildContext context) async {
    if (_origenController.text.isEmpty || _destinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Origen y Destino son obligatorios")),
      );
      return;
    }

    // --- NUEVO: Obtener datos del usuario logueado ---
    final prefs = await SharedPreferences.getInstance();
    final String nombreConductor = prefs.getString('userName') ?? "Conductor";
    final String emailConductor = prefs.getString('userEmail') ?? "";

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Publicando viaje...")));

    // MODIFICADO: Incluimos los datos del conductor en el JSON
    final Map<String, dynamic> requestBody = {
      'conductor': nombreConductor, // Para que no salga "Anon"
      'conductorEmail': emailConductor, // Para filtrar en "Mis Viajes"
      'origen': _origenController.text,
      'destino': _destinoController.text,
      'latitud': _puntoSeleccionado.latitude,
      'longitud': _puntoSeleccionado.longitude,
      'hora': _horaController.text,
      'cuota': _cuotaController.text,
      'capacidad': _capacidadController.text,
      'duracion': _duracionController.text,
      'fecha_publicacion': DateTime.now().toIso8601String(),
      'estado': 'Activo',
      'pasajeros': [], // Inicializamos la lista de pasajeros vacía
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Viaje publicado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar formulario y resetear punto
        _origenController.clear();
        _destinoController.clear();
        _horaController.clear();
        _cuotaController.clear();
        _capacidadController.clear();
        _duracionController.clear();
        setState(() {
          _puntoSeleccionado = const LatLng(19.2433, -103.725);
        });
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
    }
  }

  Widget buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String rol = snapshot.data!.getString('userRole') ?? 'peaton';
          if (rol != 'chofer' && rol != 'conductor') {
            return const Scaffold(
              body: Center(
                child: Text("No tienes permiso para publicar viajes."),
              ),
            );
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Publicar viaje',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue.shade800,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: const AppDrawer(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Detalles del viaje",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                buildInput(
                  "Lugar de Origen (Referencia)",
                  Icons.location_on,
                  _origenController,
                ),

                // --- MINI MAPA PARA SELECCIÓN EXACTA ---
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Toca el mapa para marcar el punto exacto de encuentro:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _puntoSeleccionado,
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _puntoSeleccionado = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.routemate',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _puntoSeleccionado,
                              width: 45,
                              height: 45,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ---------------------------------------
                buildInput("Destino", Icons.flag, _destinoController),
                Row(
                  children: [
                    Expanded(
                      child: buildInput(
                        "Hora",
                        Icons.access_time,
                        _horaController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildInput(
                        "Duración",
                        Icons.timer,
                        _duracionController,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: buildInput(
                        "Cuota \$",
                        Icons.attach_money,
                        _cuotaController,
                        type: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildInput(
                        "Capacidad",
                        Icons.people,
                        _capacidadController,
                        type: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () => enviarReporte(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text(
                    'PUBLICAR VIAJE AHORA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
