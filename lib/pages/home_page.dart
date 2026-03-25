import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'register_page.dart';
import 'search_page.dart'; // Importamos las pantallas que ya conectamos
import 'publish_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteMate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.white],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o Icono Principal con sombra
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: Icon(Icons.directions_car_rounded, size: 80, color: Colors.blue.shade800),
            ),

            const SizedBox(height: 30),

            const Text(
              '¡Bienvenido a RouteMate!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                'La forma más fácil y segura de compartir tus viajes en la universidad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN: BUSCAR VIAJE (Para Pasajeros)
            _buildHomeButton(
              context, 
              "Buscar un Raite", 
              Icons.search, 
              Colors.blue.shade700, 
              const SearchPage()
            ),

            const SizedBox(height: 15),

            // BOTÓN: PUBLICAR VIAJE (Para Conductores)
            _buildHomeButton(
              context, 
              "Publicar mi Viaje", 
              Icons.add_location_alt, 
              Colors.green.shade600, 
              const PublishPage()
            ),

            const SizedBox(height: 30),

            // Enlace a Registro por si son nuevos
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
              child: Text(
                "¿Eres nuevo? Regístrate aquí",
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para no repetir código de botones
  Widget _buildHomeButton(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}