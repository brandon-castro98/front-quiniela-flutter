import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_quinielas.dart';
import 'detalle_quiniela_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class QuinielasScreen extends StatefulWidget {
  @override
  _QuinielasScreenState createState() => _QuinielasScreenState();
}

class _QuinielasScreenState extends State<QuinielasScreen> {
  List<dynamic> _quinielas = [];
  bool _loading = true;
  String? _usuarioActual;
  Timer? _sessionTimer;

  void _loadQuinielas() async {
    setState(() => _loading = true);
    final data = await ApiService.getQuinielas();
    setState(() {
      _quinielas = data;
      _loading = false;
    });
  }

  void _logout() async {
    await ApiService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _loadUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioActual = prefs.getString('username');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUsuarioActual();
    _loadQuinielas();
    _startSessionTimer();
  }

  void _startSessionTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final exp = prefs.getInt('access_exp');
    if (exp == null) return;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final secondsLeft = exp - now;
    if (secondsLeft <= 0) {
      _logout();
      return;
    }

    _sessionTimer?.cancel();
    if (secondsLeft > 30) {
      _sessionTimer = Timer(
        Duration(seconds: secondsLeft - 30),
        _showSessionWarning,
      );
    } else {
      _showSessionWarning();
    }
  }

  void _showSessionWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Sesión por expirar'),
        content: Text(
          'Tu sesión está a punto de expirar. ¿Deseas refrescar el token?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Cerrar sesión'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _sessionTimer?.cancel(); // <-- Esto cierra el aviso
              final refreshed = await ApiService.refreshToken();
              if (refreshed) {
                _startSessionTimer();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Token refrescado')));
              } else {
                _logout();
              }
            },
            child: Text('Refrescar token'),
          ),
        ],
      ),
    );
    // Timer para cerrar sesión si no refresca en 30 segundos
    _sessionTimer = Timer(Duration(seconds: 30), _logout);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Lista de Quinielas'),
            if (_usuarioActual != null) ...[
              SizedBox(width: 12),
              Text(
                '($_usuarioActual)',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ],
        ),
        actions: [IconButton(onPressed: _logout, icon: Icon(Icons.logout))],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _quinielas.length,
              itemBuilder: (context, index) {
                final q = _quinielas[index];
                return ListTile(
                  title: Text(
                    q['nombre'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2, // Permite hasta 2 líneas
                    overflow:
                        TextOverflow.ellipsis, // Muestra "..." si es muy largo
                  ),
                  subtitle: Text('Apuesta: \$${q['apuesta_individual']}'),
                  trailing: SizedBox(
                    width: 190, // Limita el ancho total de los botones
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ElevatedButton(
                              onPressed: () async {
                                bool joined = await ApiService.unirseQuiniela(
                                  q['id'],
                                );
                                if (joined) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Te uniste a la quiniela'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Ya perteneces a esta quiniela',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                "Unirse",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.arrow_forward, size: 16),
                              label: Text(
                                'Detalles',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleQuinielaScreen(
                                      quinielaId: q['id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool eliminado = await ApiService.eliminarQuiniela(
                              q['id'],
                            );
                            if (eliminado) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Quiniela eliminada')),
                              );
                              _loadQuinielas(); // Recarga la lista
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No tienes permisos para eliminar la quiniela',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CrearQuinielaScreen()),
          );
          if (result == true) {
            _loadQuinielas(); // Recarga la lista
          }
        },
        icon: Icon(Icons.add),
        label: Text('Crear Quiniela'),
      ),
    );
  }
}
