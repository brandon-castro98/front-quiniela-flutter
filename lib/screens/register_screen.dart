import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _registrarUsuario() async {
    setState(() => _loading = true);
    bool ok = await ApiService.registrarUsuario(
      _userController.text,
      _emailController.text,
      _passController.text,
    );
    setState(() => _loading = false);
    _showSnack(ok ? "Usuario registrado" : "Error al registrar usuario");
    if (ok) Navigator.pop(context); // Regresa al login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro Usuario")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: "Usuario"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registrarUsuario,
                    child: Text("Registrar Usuario"),
                  ),
          ],
        ),
      ),
    );
  }
}