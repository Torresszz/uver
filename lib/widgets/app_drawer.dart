import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/publish_page.dart';
import '../pages/register_page.dart';
import '../pages/mapa_viajes_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Routemate',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Buscar viaje'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Publicar viaje'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PublishPage()),
              );
            },
          ),

          // ==========================================
          // NUEVO BOTÓN: VER MAPA DE RAITES
          // ==========================================
          ListTile(
            leading: const Icon(Icons.map, color: Colors.blue),
            title: const Text('Ver Mapa de Raites'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MapaViajesScreen()),
              );
            },
          ),

          // ==========================================
          ListTile(
            leading: const Icon(Icons.app_registration),
            title: const Text('Registro'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
