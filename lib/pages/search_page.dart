import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importante para la Opción B
import '../widgets/app_drawer.dart';
import 'mapa_viajes_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../api_service.dart';

class SearchPage extends StatefulWidget {
  // Eliminamos los parámetros obligatorios, ahora la página es independiente
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  String modo = "publicados";
  
  final ApiService _apiService = ApiService();
  final _origenBusqueda = TextEditingController();
  final _destinoBusqueda = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fade;

  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';
  List<dynamic> _todosLosViajes = [];
  List<dynamic> _viajesFiltrados = [];
  bool _estaCargando = true;

  // Variables para almacenar los datos del usuario logueado
  String _emailReal = "";
  String _nombreReal = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    
    _cargarDatosUsuario(); // 1. Cargamos quién es el usuario
    _cargarViajes();       // 2. Cargamos los viajes de la API
  }

  // Recupera el nombre y correo guardados en el dispositivo durante el Login
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailReal = prefs.getString('userEmail') ?? "";
      _nombreReal = prefs.getString('userName') ?? "Pasajero";
    });
  }

  Future<void> _cargarViajes() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _todosLosViajes = json.decode(response.body);
          _viajesFiltrados = _todosLosViajes;
          _estaCargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _estaCargando = false);
    }
  }

  void _navegarAlMapa(Map viaje) {
    if (viaje['latitud'] != null && viaje['longitud'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapaViajesScreen(
            centroInicial: LatLng(
              double.parse(viaje['latitud'].toString()),
              double.parse(viaje['longitud'].toString()),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este viaje no tiene coordenadas")),
      );
    }
  }

  void _aplicarFiltro() {
    String origen = _origenBusqueda.text.toLowerCase();
    String destino = _destinoBusqueda.text.toLowerCase();

    setState(() {
      _viajesFiltrados = _todosLosViajes.where((viaje) {
        final vOrigen = (viaje['origen'] ?? "").toString().toLowerCase();
        final vDestino = (viaje['destino'] ?? "").toString().toLowerCase();
        return vOrigen.contains(origen) && vDestino.contains(destino);
      }).toList();
      modo = "publicados";
    });
  }

  void _gestionarReserva(Map viaje) async {
    // Usamos las variables cargadas de SharedPreferences
    if (_emailReal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró sesión activa.")),
      );
      return;
    }

    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Solicitud"),
        content: Text("Hola $_nombreReal, ¿quieres enviar una solicitud para el viaje a ${viaje['destino']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sí, enviar")),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      bool exito = await _apiService.reservarViaje(
        viajeId: viaje['_id'], 
        pasajeroEmail: _emailReal,
        pasajeroNombre: _nombreReal
      );

      if (exito) {
        // Refrescamos la lista para actualizar los cupos disponibles
        _cargarViajes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Solicitud enviada correctamente."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget viajeCard(Map viaje) {
    List pasajerosActuales = viaje['pasajeros'] ?? [];
    int cupoTotal = int.tryParse(viaje['capacidad'].toString()) ?? 0;
    int disponibles = cupoTotal - pasajerosActuales.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            InkWell(
              onTap: () => _navegarAlMapa(viaje),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.location_on, "Salida:", viaje["origen"] ?? "N/A", Colors.blue),
                    _infoRow(Icons.flag, "Destino:", viaje["destino"] ?? "N/A", Colors.red),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniInfo(Icons.access_time, viaje["hora"] ?? "--:--"),
                        _miniInfo(Icons.people, "Libres: $disponibles de $cupoTotal"),
                        _miniInfo(Icons.attach_money, "Cuota: \$${viaje["cuota"]}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disponibles > 0 ? Colors.blue.shade700 : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: disponibles > 0 ? () => _gestionarReserva(viaje) : null,
                  child: Text(disponibles > 0 ? "SOLICITAR LUGAR" : "VIAJE LLENO"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget buildInput(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _origenBusqueda.dispose();
    _destinoBusqueda.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Buscar raite", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ToggleButtons(
                isSelected: [modo == "publicados", modo == "buscar"],
                onPressed: (index) {
                  setState(() {
                    modo = index == 0 ? "publicados" : "buscar";
                  });
                },
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Colors.blue.shade800,
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.of(context).size.width - 40) / 2,
                  minHeight: 45,
                ),
                children: const [
                  Text("Disponibles"),
                  Text("Filtrar Búsqueda"),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: modo == "publicados" 
                  ? _estaCargando 
                      ? const Center(child: CircularProgressIndicator())
                      : _viajesFiltrados.isEmpty 
                        ? const Center(child: Text("No se encontraron viajes."))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: _viajesFiltrados.map((v) => viajeCard(v)).toList(),
                          )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          buildInput("¿De dónde sales?", Icons.location_on, _origenBusqueda),
                          buildInput("¿A dónde vas?", Icons.flag, _destinoBusqueda),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: _aplicarFiltro,
                            icon: const Icon(Icons.search),
                            label: const Text("BUSCAR AHORA"),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}