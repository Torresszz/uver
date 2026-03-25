import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';
import 'mapa_viajes_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../api_service.dart';

class SearchPage extends StatefulWidget {
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

  String _emailReal = "";
  String _nombreReal = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _cargarDatosUsuario();
    _cargarViajes();
  }

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
      debugPrint("Error al cargar viajes: $e");
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
    if (_emailReal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró sesión activa.")),
      );
      return;
    }

    // Validación de Capacidad antes de mostrar el diálogo
    List pasajeros = viaje['pasajeros'] ?? [];
    int ocupados = pasajeros.where((p) => p['estado'].toString().toLowerCase() == 'confirmado').length;
    int capacidadMax = int.tryParse(viaje['capacidad'].toString()) ?? 0;

    if (ocupados >= capacidadMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lo sentimos, este viaje se acaba de llenar.")),
      );
      _cargarViajes(); // Recargar para actualizar la UI
      return;
    }

    if (viaje['conductorEmail'] == _emailReal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes solicitar tu propio viaje.")),
      );
      return;
    }

    bool yaSolicitado = pasajeros.any((p) => p['email'] == _emailReal);
    if (yaSolicitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ya enviaste una solicitud para este viaje.")),
      );
      return;
    }

    bool confirmar = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmar Solicitud"),
            content: Text(
              "Hola $_nombreReal, ¿quieres enviar una solicitud para el viaje a ${viaje['destino']}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Sí, enviar",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 15),
              Text("Procesando solicitud..."),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        final viajeId = (viaje['id'] ?? viaje['_id']).toString();
        bool exito = await _apiService.reservarViaje(
          viajeId: viajeId,
          pasajeroEmail: _emailReal,
          pasajeroNombre: _nombreReal,
        );

        if (exito) {
          await _cargarViajes();
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("¡Solicitud enviada! El conductor la revisará."),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          throw Exception("La API rechazó la solicitud");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al reservar: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget viajeCard(Map viaje) {
    List pasajerosActuales = viaje['pasajeros'] ?? [];

    // Cálculo real de cupos (Solo confirmados ocupan lugar)
    int ocupados = pasajerosActuales
        .where((p) => p['estado'].toString().toLowerCase() == 'confirmado')
        .length;

    int cupoTotal = int.tryParse(viaje['capacidad'].toString()) ?? 0;
    int disponibles = cupoTotal - ocupados;
    if (disponibles < 0) disponibles = 0;

    bool yaSolicitado = pasajerosActuales.any((p) => p['email'] == _emailReal);
    bool esMiPropioViaje = viaje['conductorEmail'] == _emailReal;

    Color botonColor;
    String botonTexto;
    bool botonHabilitado;

    if (esMiPropioViaje) {
      botonColor = Colors.grey.shade400;
      botonTexto = "TU VIAJE";
      botonHabilitado = false;
    } else if (yaSolicitado) {
      botonColor = Colors.orange.shade800;
      botonTexto = "SOLICITUD ENVIADA";
      botonHabilitado = false;
    } else if (disponibles <= 0) {
      botonColor = Colors.grey.shade400;
      botonTexto = "VIAJE LLENO";
      botonHabilitado = false;
    } else {
      botonColor = Colors.blue.shade700;
      botonTexto = "SOLICITAR LUGAR";
      botonHabilitado = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            InkWell(
              onTap: () => _navegarAlMapa(viaje),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(Icons.location_on, "Salida:", viaje["origen"] ?? "N/A", Colors.blue),
                    const SizedBox(height: 8),
                    _infoRow(Icons.flag, "Destino:", viaje["destino"] ?? "N/A", Colors.red),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniInfo(Icons.access_time, viaje["hora"] ?? "--:--"),
                        // Mini Info de Cupos con color dinámico
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: disponibles == 0 ? Colors.red : (disponibles == 1 ? Colors.orange : Colors.green),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Libres: $disponibles",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: disponibles == 0 ? Colors.red : (disponibles == 1 ? Colors.orange.shade900 : Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                        _miniInfo(Icons.attach_money, "Cuota: \$${viaje["cuota"]}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: botonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: botonColor.withOpacity(0.7),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: botonHabilitado ? 2 : 0,
                  ),
                  onPressed: botonHabilitado ? () => _gestionarReserva(viaje) : null,
                  child: Text(
                    botonTexto,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
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
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
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
                    minWidth: (MediaQuery.of(context).size.width - 60) / 2,
                    minHeight: 40,
                  ),
                  children: const [Text("Disponibles"), Text("Filtrar Búsqueda")],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: modo == "publicados"
                    ? _estaCargando
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _cargarViajes,
                            child: _viajesFiltrados.isEmpty
                                ? const Center(child: Text("No se encontraron viajes."))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: _viajesFiltrados.length,
                                    itemBuilder: (context, index) => viajeCard(_viajesFiltrados[index]),
                                  ),
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
                              label: const Text("BUSCAR AHORA", style: TextStyle(fontWeight: FontWeight.bold)),
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