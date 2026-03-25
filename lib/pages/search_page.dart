import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  String modo = "publicados";
  
  // 1. CONTROLADORES PARA FILTRAR BÚSQUEDA
  final _origenBusqueda = TextEditingController();
  final _destinoBusqueda = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fade;

  // 2. LISTA DINÁMICA DE EJEMPLO (Lo que vendría de Vercel/API)
  List<Map<String, dynamic>> viajesData = [
    {
      "origen": "Colima Centro",
      "destino": "Villa de Álvarez",
      "hora": "08:30 AM",
      "cupo": "3",
      "precio": "25"
    },
    {
      "origen": "Facultad de Telemática",
      "destino": "Coquimatlán",
      "hora": "02:00 PM",
      "cupo": "2",
      "precio": "40"
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _origenBusqueda.dispose();
    _destinoBusqueda.dispose();
    _controller.dispose();
    super.dispose();
  }

  // 3. INPUT ACTUALIZADO PARA RECIBIR CONTROLADOR
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
              _infoRow(Icons.location_on, "Salida:", viaje["origen"], Colors.blue),
              _infoRow(Icons.flag, "Destino:", viaje["destino"], Colors.red),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniInfo(Icons.access_time, viaje["hora"]),
                  _miniInfo(Icons.people, "Cupo: ${viaje["cupo"]}"),
                  _miniInfo(Icons.attach_money, "Cuota: \$${viaje["precio"]}"),
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

  Widget listaViajes() {
    return Column(
      children: viajesData.map((v) => viajeCard(v)).toList(),
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
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            // Aquí filtrarías la lista 'viajesData' según los controllers
            setState(() {
               modo = "publicados"; // Al buscar, regresamos a la lista
            });
          },
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text("Buscar Raite", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscar viaje"),
        backgroundColor: Colors.blue,
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
                fillColor: Colors.blue,
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.of(context).size.width - 36) / 2,
                  minHeight: 40,
                ),
                children: const [
                  Text("Disponibles"),
                  Text("Nueva Búsqueda"),
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