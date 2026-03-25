import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  String modo = "publicados";
  
  final _origenBusqueda = TextEditingController();
  final _destinoBusqueda = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fade;

  // URL de tu API de viajes en Vercel
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/viajes';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  // FUNCIÓN PARA OBTENER VIAJES DESDE VERCEL
  Future<List<dynamic>> obtenerViajes() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error cargando viajes: $e");
      return [];
    }
  }

  @override
  void dispose() {
    _origenBusqueda.dispose();
    _destinoBusqueda.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget buildInput(String label, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget viajeCard(Map viaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoRow(Icons.location_on, "Salida:", viaje["origen"] ?? "No especificado", Colors.blue),
              _infoRow(Icons.flag, "Destino:", viaje["destino"] ?? "No especificado", Colors.red),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniInfo(Icons.access_time, viaje["hora"] ?? "--:--"),
                  _miniInfo(Icons.people, "Cupo: ${viaje["capacidad"] ?? '?' }"),
                  _miniInfo(Icons.attach_money, "Cuota: \$${viaje["cuota"] ?? '0'}"),
                ],
              ),
            ],
          ),
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

  // LISTA DINÁMICA CON FUTUREBUILDER
  Widget listaViajes() {
    return FutureBuilder<List<dynamic>>(
      future: obtenerViajes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No hay viajes disponibles en este momento."),
          );
        }

        return Column(
          children: snapshot.data!.map((v) => viajeCard(v)).toList(),
        );
      },
    );
  }

  Widget buscarViajeForm() {
    return Column(
      children: [
        buildInput("¿De dónde sales?", Icons.location_on, _origenBusqueda),
        buildInput("¿A dónde vas?", Icons.flag, _destinoBusqueda),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            // Aquí podrías filtrar, por ahora solo refrescamos la lista
            setState(() {
               modo = "publicados"; 
            });
          },
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text("Buscar Raite", style: TextStyle(color: Colors.white, fontSize: 16)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar viaje", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ToggleButtons(
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
                  Text("Disponibles", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Nueva Búsqueda", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: modo == "publicados" ? listaViajes() : buscarViajeForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}