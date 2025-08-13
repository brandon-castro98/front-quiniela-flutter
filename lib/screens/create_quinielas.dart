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
      appBar: AppBar(title: Text("Crear Quiniela")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Llena los datos para agregar una nueva quiniela",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _nombreQController,
              decoration: InputDecoration(labelText: "Nombre Quiniela"),
            ),
            TextField(
              controller: _apuestaController,
              decoration: InputDecoration(labelText: "Apuesta Individual"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _crearQuiniela,
                    child: Text("Crear Quiniela"),
                  ),
          ],
        ),
      ),
    );
  }
}