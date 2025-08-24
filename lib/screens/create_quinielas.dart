import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Agrega esto

class CrearQuinielaScreen extends StatefulWidget {
  @override
  _CrearQuinielaScreenState createState() => _CrearQuinielaScreenState();
}

class _CrearQuinielaScreenState extends State<CrearQuinielaScreen> {
  final _nombreQController = TextEditingController();
  final _apuestaController = TextEditingController();
  bool _loading = false;
  String? _usuarioActual;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _crearQuiniela() async {
    setState(() => _loading = true);
    bool ok = await ApiService.agregarQuiniela(
      _nombreQController.text,
      double.tryParse(_apuestaController.text) ?? 0.0,
    );
    setState(() => _loading = false);
    _showSnack(ok ? "Quiniela creada" : "Error al crear quiniela");
    if (ok) Navigator.pop(context, true); // Opcional: regresa a la lista
  }

  Future<void> _loadUsuarioActual() async {
    // <-- Agrega esto
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioActual = prefs.getString('username');
    });
  }

  @override
  void initState() {
    // <-- Agrega esto
    super.initState();
    _loadUsuarioActual();
  }

  @override
  void dispose() {
    _nombreQController.dispose();
    _apuestaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/nfl_logo.png', height: 32),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Crear Quiniela NFL",
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_usuarioActual != null)
                  Text(
                    '$_usuarioActual',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Color(0xFF013369),
      ),
      backgroundColor: Color(0xFFE5E5E5),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 12,
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFD50A0A), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/nfl_logo.png', height: 70),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "¡Crea tu Quiniela NFL!",
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      color: Color(0xFF013369),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Color(0xFFD50A0A),
                    thickness: 2,
                    indent: 40,
                    endIndent: 40,
                  ),
                  SizedBox(height: 18),
                  Text(
                    "Llena los datos para agregar una nueva quiniela y reta a tus amigos a predecir los partidos de la NFL.",
                    style: GoogleFonts.oswald(
                      fontSize: 16,
                      color: Color(0xFF013369),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _nombreQController,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      color: Color(0xFF013369),
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      labelText: "Nombre de la Quiniela",
                      labelStyle: GoogleFonts.oswald(
                        color: Color(0xFFD50A0A),
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title, color: Color(0xFFD50A0A)),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _apuestaController,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      color: Color(0xFF013369),
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      labelText: "Apuesta Individual (\$)",
                      labelStyle: GoogleFonts.oswald(
                        color: Color(0xFFD50A0A),
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Color(0xFFD50A0A),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 30),
                  _loading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.sports_football,
                              color: Colors.white,
                            ),
                            onPressed: _crearQuiniela,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD50A0A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              textStyle: GoogleFonts.oswald(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            label: Text("Crear Quiniela"),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
