import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetalleQuinielaScreen extends StatefulWidget {
  final int quinielaId;
  DetalleQuinielaScreen({required this.quinielaId});

  @override
  _DetalleQuinielaScreenState createState() => _DetalleQuinielaScreenState();
}

class _DetalleQuinielaScreenState extends State<DetalleQuinielaScreen> {
  Map<String, dynamic>? _quiniela;
  bool _loading = true;
  String? _usuarioActual;
  final _localController = TextEditingController();
  final _visitanteController = TextEditingController();
  List<dynamic> _elecciones = [];
  List<dynamic> _ranking = [];

  Future<void> _loadDetalle() async {
    setState(() => _loading = true);
    final data = await ApiService.getQuinielaDetalle(widget.quinielaId);
    setState(() {
      _quiniela = data;
      _loading = false;
    });
  }

  Future<void> _loadRanking() async {
    final data = await ApiService.getRanking(widget.quinielaId);
    setState(() {
      _ranking = data;
    });
  }

  Future<void> _agregarPartido() async {
    final local = _localController.text;
    final visitante = _visitanteController.text;
    if (local.isEmpty || visitante.isEmpty) return;
    final ok = await ApiService.agregarPartido(
      widget.quinielaId,
      local,
      visitante,
    );
    if (ok) {
      _localController.clear();
      _visitanteController.clear();
      await _loadDetalle(); // Recarga partidos
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Partido agregado')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agregar partido')));
    }
  }

  Future<void> _loadUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioActual = prefs.getString('username');
    });
  }

  Future<void> _loadElecciones() async {
    final data = await ApiService.getElecciones(widget.quinielaId);
    setState(() {
      _elecciones = data;
    });
  }

  Future<void> _ingresarResultado(int partidoId) async {
    final resultadoController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar resultado'),
        content: TextField(
          controller: resultadoController,
          decoration: InputDecoration(labelText: 'Resultado real'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final resultado = resultadoController.text;
              if (resultado.isNotEmpty) {
                final resp = await ApiService.ingresarResultado(
                  partidoId,
                  resultado,
                );
                Navigator.pop(context, resp);
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _loadDetalle();
      await _loadElecciones(); // <-- recarga elecciones
      await _loadRanking();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resultado guardado')));
    }
  }

  Future<void> _elegirEquipo() async {
    final elecciones = <Map<String, dynamic>>[];
    final partidos = _quiniela!['partidos'] as List;
    final elegido = <int, String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Elegir equipo por partido'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: partidos.map<Widget>((partido) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${partido['equipo_local']} vs ${partido['equipo_visitante']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        title: Text(partido['equipo_local']),
                        value: partido['equipo_local'],
                        groupValue: elegido[partido['id']],
                        activeColor:
                            Colors.deepPurple, // <-- color de selección
                        onChanged: (val) {
                          setState(() {
                            elegido[partido['id']] = val!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(partido['equipo_visitante']),
                        value: partido['equipo_visitante'],
                        groupValue: elegido[partido['id']],
                        activeColor:
                            Colors.deepPurple, // <-- color de selección
                        onChanged: (val) {
                          setState(() {
                            elegido[partido['id']] = val!;
                          });
                        },
                      ),
                      Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirmar elecciones'),
                    content: Text(
                      '¿Estás seguro? Una vez confirmes tus equipos ya no podrás editarlos.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Confirmar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  partidos.forEach((partido) {
                    if (elegido[partido['id']] != null) {
                      elecciones.add({
                        'partido_id': partido['id'],
                        'equipo_elegido': elegido[partido['id']],
                      });
                    }
                  });
                  await _setEleccionesConfirmadas();
                  Navigator.pop(context, true);
                }
              },
              child: Text('Guardar elecciones'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && elecciones.isNotEmpty) {
      final resp = await ApiService.elegirEquipo(widget.quinielaId, elecciones);
      if (resp) {
        await _loadElecciones();
        await _loadRanking();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Elecciones guardadas')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar elecciones')));
      }
    }
  }

  Future<void> _setEleccionesConfirmadas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'elecciones_confirmadas_${widget.quinielaId}_${_usuarioActual}',
      true,
    );
  }

  Future<bool> _getEleccionesConfirmadas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          'elecciones_confirmadas_${widget.quinielaId}_${_usuarioActual}',
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _loadUsuarioActual();
    _loadDetalle();
    _loadElecciones();
    _loadRanking();
  }

  @override
  void dispose() {
    _localController.dispose();
    _visitanteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Wrap(
          spacing: 10,
          children: [
            if (_usuarioActual != null &&
                _quiniela != null &&
                _usuarioActual!.trim().toLowerCase() ==
                    _quiniela!['creada_por'].toString().trim().toLowerCase())
              FloatingActionButton(
                heroTag: 'resultado',
                mini: true,
                onPressed: () {
                  final partidos = _quiniela!['partidos'] as List;
                  int? partidoId;
                  showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text(
                              'Selecciona partido para ingresar resultado',
                            ),
                            content: DropdownButton<int>(
                              isExpanded: true,
                              value: partidoId,
                              items: partidos.map<DropdownMenuItem<int>>((p) {
                                return DropdownMenuItem<int>(
                                  value: p['id'],
                                  child: Text(
                                    '${p['equipo_local']} vs ${p['equipo_visitante']}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  partidoId = val;
                                });
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: partidoId != null
                                    ? () {
                                        Navigator.pop(context);
                                        _ingresarResultado(partidoId!);
                                      }
                                    : null,
                                child: Text('Ingresar resultado'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: Icon(Icons.edit, size: 20),
                backgroundColor: Colors.amber,
                tooltip: 'Ingresar resultado',
              ),
            FloatingActionButton(
              heroTag: 'eleccion',
              mini: true,
              onPressed: () async {
                final confirmado = await _getEleccionesConfirmadas();
                if (confirmado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ya confirmaste tus elecciones. No puedes editarlas.',
                      ),
                    ),
                  );
                  return;
                }
                await _elegirEquipo();
              },
              child: Icon(Icons.sports_soccer, size: 20),
              backgroundColor: Colors.deepPurple,
              tooltip: 'Elegir equipo',
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text('Detalle Quiniela')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _quiniela == null
          ? Center(child: Text('No se encontró la quiniela'))
          : Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre: ${_quiniela!['nombre']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Apuesta: \$${_quiniela!['apuesta_individual']}'),
                    Text(
                      'Dueño: ${_quiniela!['creada_por']}',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    if (_usuarioActual != null)
                      Builder(
                        builder: (context) {
                          final userRank = _ranking.firstWhere(
                            (r) => r['usuario'] == _usuarioActual,
                            orElse: () => null,
                          );
                          if (userRank != null) {
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tus aciertos: ${userRank['aciertos']}   |   Porcentaje: ${userRank['porcentaje']}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    SizedBox(height: 16),
                    if (_usuarioActual != null &&
                        _quiniela != null &&
                        _usuarioActual!.trim().toLowerCase() !=
                            _quiniela!['creada_por']
                                .toString()
                                .trim()
                                .toLowerCase())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'No puedes agregar partidos si no eres el creador de la quiniela.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      'Agregar Partido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _localController,
                            decoration: InputDecoration(
                              labelText: 'Equipo Local',
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _visitanteController,
                            decoration: InputDecoration(
                              labelText: 'Equipo Visitante',
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              (_usuarioActual != null &&
                                  _quiniela != null &&
                                  _usuarioActual!.trim().toLowerCase() ==
                                      _quiniela!['creada_por']
                                          .toString()
                                          .trim()
                                          .toLowerCase())
                              ? _agregarPartido
                              : null,
                          child: Text('Agregar'),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ExpansionTile(
                      title: Text(
                        'Participantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: (_quiniela!['participantes'] as List).map<Widget>((
                        p,
                      ) {
                        final eleccionesParticipante = _elecciones.firstWhere(
                          (e) => e['participante'] == p,
                          orElse: () => null,
                        );
                        return ExpansionTile(
                          title: Row(
                            children: [
                              Text(p.toString()),
                              SizedBox(width: 8),
                              Builder(
                                builder: (context) {
                                  final rank = _ranking.firstWhere(
                                    (r) => r['usuario'] == p,
                                    orElse: () => null,
                                  );
                                  if (rank != null) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Aciertos: ${rank['aciertos']} | %: ${rank['porcentaje']}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          children: eleccionesParticipante != null
                              ? (eleccionesParticipante['elecciones'] as List).map<
                                  Widget
                                >((el) {
                                  return ListTile(
                                    title: Text(
                                      '${el['equipo_local']} vs ${el['equipo_visitante']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Elegido: ${el['equipo_elegido']}',
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    trailing: el['resultado_real'] != null
                                        ? Text(
                                            'Resultado: ${el['resultado_real']}',
                                          )
                                        : null,
                                  );
                                }).toList()
                              : [
                                  ListTile(
                                    title: Text('Sin elecciones registradas'),
                                  ),
                                ],
                        );
                      }).toList(),
                    ),
                    Text(
                      'Partidos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 300, // Ajusta la altura según tu preferencia
                      child: ListView.builder(
                        itemCount: (_quiniela!['partidos'] as List).length,
                        itemBuilder: (context, idx) {
                          final partido = _quiniela!['partidos'][idx];
                          return ListTile(
                            title: Text(
                              '${partido['equipo_local']} vs ${partido['equipo_visitante']}',
                            ),
                            subtitle: Text(
                              'Resultado: ${partido['resultado_real'] ?? "Sin resultado"}',
                            ),
                            trailing:
                                (_usuarioActual != null &&
                                    _usuarioActual!.trim().toLowerCase() ==
                                        _quiniela!['creada_por']
                                            .toString()
                                            .trim()
                                            .toLowerCase())
                                ? IconButton(
                                    icon: Icon(Icons.edit, color: Colors.amber),
                                    tooltip: 'Ingresar resultado',
                                    onPressed: () =>
                                        _ingresarResultado(partido['id']),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
