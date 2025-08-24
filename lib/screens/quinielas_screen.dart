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

class _QuinielasScreenState extends State<QuinielasScreen>
    with WidgetsBindingObserver {
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
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
    WidgetsBinding.instance.addObserver(this);
    _loadUsuarioActual();
    _loadQuinielas();
    _startSessionTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _loadQuinielas();
    }
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/nfl_logo.png', height: 32),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quinielas NFL',
                  style: TextStyle(
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Color(0xFFE5E5E5),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _quinielas.isEmpty
          ? Center(
              child: Text(
                'No hay quinielas disponibles.',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: ListView.builder(
                itemCount: _quinielas.length,
                itemBuilder: (context, index) {
                  final q = _quinielas[index];
                  return Card(
                    elevation: 6,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Colors.deepPurple.shade100,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.deepPurple,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q['nombre'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: const Color.fromARGB(
                                      255,
                                      240,
                                      20,
                                      20,
                                    ),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Apuesta: \$${q['apuesta_individual']}',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 223, 30, 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ElevatedButton(
                                    onPressed:
                                        (q['participantes'] != null &&
                                            _usuarioActual != null &&
                                            (q['participantes'] as List)
                                                .map(
                                                  (p) => p
                                                      .toString()
                                                      .trim()
                                                      .toLowerCase(),
                                                )
                                                .contains(
                                                  _usuarioActual!
                                                      .trim()
                                                      .toLowerCase(),
                                                ))
                                        ? null
                                        : () async {
                                            bool joined =
                                                await ApiService.unirseQuiniela(
                                                  q['id'],
                                                );
                                            if (joined) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Te uniste a la quiniela',
                                                  ),
                                                ),
                                              );
                                              _loadQuinielas(); // Refresca la lista desde el backend
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Ya perteneces a esta quiniela',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFD50A0A),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Unirse",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.arrow_forward, size: 18),
                                    label: Text(
                                      'Detalles',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        13,
                                        10,
                                        213,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed:
                                        (q['participantes'] != null &&
                                            _usuarioActual != null &&
                                            (q['participantes'] as List)
                                                .map(
                                                  (p) => p
                                                      .toString()
                                                      .trim()
                                                      .toLowerCase(),
                                                )
                                                .contains(
                                                  _usuarioActual!
                                                      .trim()
                                                      .toLowerCase(),
                                                ))
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetalleQuinielaScreen(
                                                      quinielaId: q['id'],
                                                    ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool eliminado =
                                      await ApiService.eliminarQuiniela(
                                        q['id'],
                                      );
                                  if (eliminado) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Quiniela eliminada'),
                                      ),
                                    );
                                    _loadQuinielas();
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CrearQuinielaScreen()),
          );
          if (result == true) {
            _loadQuinielas();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Crear Quiniela'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
