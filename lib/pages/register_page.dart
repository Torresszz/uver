import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'dart:convert';
import 'dart:io'; // Para manejar archivos de imagen
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Asegúrate de tenerlo en pubspec.yaml

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String tipoUsuario = "conductor";
  bool _isLoading = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  // Mapa para guardar las fotos seleccionadas
  // Las llaves coinciden con los nombres de los campos que espera la API
  final Map<String, File?> _fotos = {
    'foto_ine': null,
    'foto_placas': null,
    'foto_licencia': null,
    'foto_calcomania': null,
  };

  final ImagePicker _picker = ImagePicker();
  final String _apiUrl = 'https://uver-oxnw.vercel.app/api/usuarios';

  // Función para seleccionar imagen
  Future<void> _seleccionarImagen(String campo) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Reducimos calidad para que el Base64 no sea gigante
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        _fotos[campo] = File(pickedFile.path);
      });
    }
  }

  // Convertir archivo a String Base64
  Future<String?> _convertirBase64(File? file) async {
    if (file == null) return null;
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> registrarUsuario() async {
    if (_nombreController.text.isEmpty || _correoController.text.isEmpty) {
      _showSnackBar("Por favor llena los campos principales", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertimos las imágenes a Base64 antes de enviar
      String? ineBase64 = await _convertirBase64(_fotos['foto_ine']);
      String? placasBase64 = await _convertirBase64(_fotos['foto_placas']);
      String? licenciaBase64 = await _convertirBase64(_fotos['foto_licencia']);

      final Map<String, dynamic> userData = {
        'nombre': _nombreController.text.trim(),
        'email': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'rol': tipoUsuario,
        'fecha_registro': DateTime.now().toIso8601String(),
        'estado': 'Pendiente',
        'foto_ine': ineBase64,
        'foto_placas': placasBase64,
        'foto_licencia': licenciaBase64,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("¡Registro exitoso! Enviado a revisión", Colors.green);
        _limpiarFormulario();
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar("Error al conectar con el servidor", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _fotos.updateAll((key, value) => null);
    setState(() {});
  }

  void _showSnackBar(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
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
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget buildUpload(String label, IconData icon, String campo) {
    bool tieneArchivo = _fotos[campo] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _seleccionarImagen(campo),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: tieneArchivo ? Colors.green : Colors.blue),
            borderRadius: BorderRadius.circular(12),
            color: tieneArchivo ? Colors.green.shade50 : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(tieneArchivo ? Icons.check_circle : icon, 
                   color: tieneArchivo ? Colors.green : Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tieneArchivo ? "Archivo seleccionado" : label,
                  style: TextStyle(color: tieneArchivo ? Colors.green : Colors.black87),
                ),
              ),
              const Icon(Icons.upload_file, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Selector de Rol
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(child: _roleButton("conductor", Icons.directions_car, "Conductor")),
                  Expanded(child: _roleButton("pasajero", Icons.person, "Pasajero")),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            buildInput("Nombre completo", Icons.person_outline, _nombreController),
            buildInput("Correo Institucional", Icons.email_outlined, _correoController, type: TextInputType.emailAddress),
            buildInput("Teléfono", Icons.phone_android, _telefonoController, type: TextInputType.phone),
            
            const Divider(height: 40),
            const Text("Documentación Requerida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            buildUpload("Foto INE (Frente)", Icons.badge_outlined, 'foto_ine'),

            if (tipoUsuario == "conductor") ...[
              buildUpload("Tarjeta de Circulación / Placas", Icons.vpn_key_outlined, 'foto_placas'),
              buildUpload("Licencia de Conducir", Icons.contact_page_outlined, 'foto_licencia'),
            ],

            const SizedBox(height: 30),
            
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: registrarUsuario,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text("Registrarse", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(String role, IconData icon, String text) {
    bool isSelected = tipoUsuario == role;
    return GestureDetector(
      onTap: () => setState(() => tipoUsuario = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.blue.shade800 : Colors.grey),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(
              color: isSelected ? Colors.blue.shade800 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}