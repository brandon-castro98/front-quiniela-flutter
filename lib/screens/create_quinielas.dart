import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrearQuinielaScreen extends StatefulWidget {
  @override
  _CrearQuinielaScreenState createState() => _CrearQuinielaScreenState();
}

class _CrearQuinielaScreenState extends State<CrearQuinielaScreen> {
  final _nombreQController = TextEditingController();
  final _apuestaController = TextEditingController();
  bool _loading = false;

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
          Icon(Icons.add_circle, color: Colors.amber.shade700),
          SizedBox(width: 8),
          Text("Crear Quiniela"),
        ],
      ),
      backgroundColor: Colors.deepPurple,
    ),
    backgroundColor: Colors.amber.shade50,
    body: Center(
      child: SingleChildScrollView(
        child: Card(
          elevation: 10,
          margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.deepPurple),
                SizedBox(height: 16),
                Text(
                  "Llena los datos para agregar una nueva quiniela",
                  style: TextStyle(fontSize: 20, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                TextField(
                  controller: _nombreQController,
                  decoration: InputDecoration(
                    labelText: "Nombre Quiniela",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _apuestaController,
                  decoration: InputDecoration(
                    labelText: "Apuesta Individual",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 30),
                _loading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _crearQuiniela,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Crear Quiniela"),
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