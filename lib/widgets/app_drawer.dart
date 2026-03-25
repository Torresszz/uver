import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/publish_page.dart';
import '../pages/register_page.dart';
import '../pages/mapa_viajes_screen.dart';
import '../pages/viajes_conductor.dart';
import '../pages/mis_solicitudes.dart'; // <--- 1. NUEVO: Importa la página de solicitudes

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<Map<String, String>> _getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('userName') ?? 'Usuario', 
    'email': prefs.getString('userEmail') ?? 'Tu comunidad de raites',
    'role': prefs.getString('userRole') ?? 'peaton',
  };
}

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, String>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          final name = snapshot.data?['name'] ?? 'Cargando...';
          final email = snapshot.data?['email'] ?? '...';
          final role = snapshot.data?['role'] ?? 'peaton';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                    opacity: 0.4,
                  ),
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(email),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
              ),

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

                    // 2. NUEVO: Botón para que CUALQUIER usuario vea sus solicitudes enviadas
                    _buildMenuItem(
                      icon: Icons.history_rounded,
                      title: 'Mis Solicitudes (Pasajero)',
                      iconColor: Colors.purple.shade700,
                      onTap: () => _navigate(context, const MisSolicitudes()),
                    ),

                    if (role == "chofer" || role == "conductor") ...[
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.add_location_alt_rounded,
                        title: 'Publicar Viaje',
                        iconColor: Colors.green.shade700,
                        onTap: () => _navigate(context, const PublishPage()),
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment_ind_rounded,
                        title: 'Gestionar mis Viajes',
                        iconColor: Colors.orange.shade800,
                        onTap: () => _navigate(context, const MisViajesConductor()),
                      ),
                    ],

                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Mi Perfil / Registro',
                      onTap: () => _navigate(context, const RegisterPage()),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'v1.0.2 Beta',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

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