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
      child: Column( // Cambié a Column para poder poner el botón de cerrar sesión al final
        children: [
          // Header con diseño más moderno
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            accountName: const Text(
              'RouteMate',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Tu comunidad de raites'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.directions_car, size: 40, color: Colors.blue),
            ),
          ),

          // Lista de navegación
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  onTap: () => _navigate(context, const HomePage()),
                ),
                _buildMenuItem(
                  icon: Icons.map_rounded,
                  title: 'Explorar Mapa',
                  iconColor: Colors.blue.shade700,
                  onTap: () => _navigate(context, const MapaViajesScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.search_rounded,
                  title: 'Buscar Viaje',
                  onTap: () => _navigate(context, const SearchPage()),
                ),
                _buildMenuItem(
                  icon: Icons.add_location_alt_rounded,
                  title: 'Publicar Viaje',
                  onTap: () => _navigate(context, const PublishPage()),
                ),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Registro / Perfil',
                  onTap: () => _navigate(context, const RegisterPage()),
                ),
              ],
            ),
          ),
          
          // Pie del Drawer (Opcional: Versión de la app o cerrar sesión)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'v1.0.2 Beta',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Función para evitar repetir código de navegación
  void _navigate(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  // Widget personalizado para los items del menú
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}