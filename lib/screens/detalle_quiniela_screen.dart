import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget networkImageWithSvg(String? url, {double? height, double? width}) {
  if (url == null || url.isEmpty) {
    return SizedBox(width: width, height: height);
  }
  if (url.toLowerCase().endsWith('.svg')) {
    return SvgPicture.network(
      url,
      height: height,
      width: width,
      placeholderBuilder: (context) => SizedBox(width: width, height: height),
      fit: BoxFit.contain,
      // Manejo de error para SVG inválido
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.broken_image, size: height ?? 24),
    );
  }
  return Image.network(
    url,
    height: height,
    width: width,
    errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: height ?? 24),
  );
}

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
  List<dynamic> _equipos = [];
  int? _equipoLocalId;
  int? _equipoVisitanteId;
  DateTime? _fechaPartido;
  List<dynamic> _partidos = [];

  Future<void> _loadEquipos() async {
    _equipos = await ApiService.getEquipos();
    setState(() {});
  }

  Future<void> _loadDetalle() async {
    setState(() => _loading = true);
    final data = await ApiService.getQuinielaDetalle(widget.quinielaId);
    final partidos = await ApiService.getPartidos(widget.quinielaId);
    partidos.sort(
      (a, b) => a['id'].compareTo(b['id']),
    ); // <-- Asegura orden de creación
    setState(() {
      _quiniela = data;
      _partidos = partidos;
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
    if (_equipoLocalId == null ||
        _equipoVisitanteId == null ||
        _equipoLocalId == _equipoVisitanteId ||
        _fechaPartido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona equipos y fecha válidos')),
      );
      return;
    }
    final ok = await ApiService.agregarPartido(
      widget.quinielaId,
      _equipoLocalId!,
      _equipoVisitanteId!,
      _fechaPartido!,
    );
    if (ok) {
      _equipoLocalId = null;
      _equipoVisitanteId = null;
      _fechaPartido = null;
      await _loadDetalle();
      setState(() {});
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
    final partido = _partidos.firstWhere((p) => p['id'] == partidoId);
    final local = partido['equipo_local'];
    final visitante = partido['equipo_visitante'];
    int? equipoGanadorId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Selecciona el equipo ganador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                title: Row(
                  children: [
                    networkImageWithSvg(
                      local['logo_url'],
                      height: 28,
                      width: 28,
                    ),
                    SizedBox(width: 8),
                    Text(local['nombre'] ?? ''),
                  ],
                ),
                value: local['id'],
                groupValue: equipoGanadorId,
                onChanged: (val) {
                  setState(() {
                    equipoGanadorId = val;
                  });
                },
              ),
              RadioListTile<int>(
                title: Row(
                  children: [
                    networkImageWithSvg(
                      visitante['logo_url'],
                      height: 28,
                      width: 28,
                    ),
                    SizedBox(width: 8),
                    Text(visitante['nombre'] ?? ''),
                  ],
                ),
                value: visitante['id'],
                groupValue: equipoGanadorId,
                onChanged: (val) {
                  setState(() {
                    equipoGanadorId = val;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: equipoGanadorId != null
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text('Aceptar'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && equipoGanadorId != null) {
      final resp = await ApiService.ingresarResultado(
        widget.quinielaId,
        partidoId,
        equipoGanadorId!,
      );
      if (resp) {
        await _loadDetalle();
        await _loadElecciones();
        await _loadRanking();
        if (mounted) setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Resultado guardado')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar resultado')));
      }
    }
  }

  Future<void> _elegirEquipo(List<int> partidosYaElegidos) async {
    final partidos = (_quiniela!['partidos'] as List)
        .where((p) => !partidosYaElegidos.contains(p['id']))
        .toList();
    final elegido = <int, int>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Elegir equipo por partido'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: partidos.map<Widget>((partido) {
                  dynamic local = partido['equipo_local'];
                  if (local is! Map) {
                    local = _equipos.firstWhere(
                      (e) => e['id'] == local,
                      orElse: () => {
                        'nombre': 'Desconocido',
                        'logo_url': '',
                        'id': -1,
                      },
                    );
                  }
                  dynamic visitante = partido['equipo_visitante'];
                  if (visitante is! Map) {
                    visitante = _equipos.firstWhere(
                      (e) => e['id'] == visitante,
                      orElse: () => {
                        'nombre': 'Desconocido',
                        'logo_url': '',
                        'id': -1,
                      },
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${local['nombre']} vs ${visitante['nombre']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<int>(
                        title: Row(
                          children: [
                            networkImageWithSvg(
                              local['logo_url'],
                              height: 28,
                              width: 28,
                            ),
                            SizedBox(width: 6),
                            Text(local['nombre'] ?? ''),
                          ],
                        ),
                        value: local['id'],
                        groupValue: elegido[partido['id']],
                        activeColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() {
                            elegido[partido['id']] = val!;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: Row(
                          children: [
                            networkImageWithSvg(
                              visitante['logo_url'],
                              height: 28,
                              width: 28,
                            ),
                            SizedBox(width: 6),
                            Text(visitante['nombre'] ?? ''),
                          ],
                        ),
                        value: visitante['id'],
                        groupValue: elegido[partido['id']],
                        activeColor: Colors.deepPurple,
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
                  final elecciones = <Map<String, dynamic>>[];
                  partidos.forEach((partido) {
                    if (elegido[partido['id']] != null) {
                      elecciones.add({
                        'partido_id': partido['id'],
                        'equipo_elegido': elegido[partido['id']],
                      });
                    }
                  });

                  // Solo confirma si ya eligió todos los partidos
                  if ((partidosYaElegidos.length + elecciones.length) ==
                      _partidos.length) {
                    await _setEleccionesConfirmadas();
                  }

                  Navigator.pop(context, true);

                  // Guardar elecciones en backend
                  if (elecciones.isNotEmpty) {
                    final resp = await ApiService.elegirEquipo(
                      widget.quinielaId,
                      elecciones,
                    );
                    if (resp) {
                      await _loadElecciones();
                      await _loadRanking();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Elecciones guardadas')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar elecciones')),
                      );
                    }
                  }
                }
              },
              child: Text('Guardar elecciones'),
            ),
          ],
        ),
      ),
    );
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
    _loadEquipos();
  }

  @override
  void dispose() {
    _localController.dispose();
    _visitanteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Lógica para picks faltantes ---
    final eleccionesUsuario = _elecciones.firstWhere(
      (e) =>
          e['participante'].toString().trim().toLowerCase() ==
          (_usuarioActual ?? '').trim().toLowerCase(),
      orElse: () => null,
    );
    final List<int> partidosYaElegidos = eleccionesUsuario != null
        ? (eleccionesUsuario['elecciones'] as List)
              .map<int>((el) => el['partido_id'] as int)
              .toList()
        : [];
    final int totalPartidos = _partidos.length;
    final int picksHechos = partidosYaElegidos.length;
    final bool yaCompletoTodos =
        picksHechos == totalPartidos && totalPartidos > 0;
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
                  'Informacion de la quniela',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_usuarioActual != null)
                  Text(
                    ' $_usuarioActual',
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
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFE5E5E5),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _quiniela == null
          ? Center(child: Text('No se encontró la quiniela'))
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_quiniela != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Center(
                              child: Text(
                                _quiniela!['nombre'] ?? '',
                                style: GoogleFonts.oswald(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD50A0A),
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Text(
                              'Mostrar picks de todos:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: _quiniela!['mostrar_elecciones'] ?? false,
                              activeColor: Color(0xFFD50A0A),
                              onChanged:
                                  (_usuarioActual != null &&
                                      _quiniela != null &&
                                      _usuarioActual!.trim().toLowerCase() ==
                                          _quiniela!['creada_por']
                                              .toString()
                                              .trim()
                                              .toLowerCase())
                                  ? (val) async {
                                      final ok =
                                          await ApiService.setMostrarElecciones(
                                            widget.quinielaId,
                                            val,
                                          );
                                      if (ok) {
                                        await _loadDetalle();
                                        setState(() {});
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error al actualizar visibilidad',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null, // <-- Solo el admin puede cambiar el switch
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Apuesta: \$${_quiniela!['apuesta_individual']}',
                          style: TextStyle(
                            color: Color(0xFFD50A0A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Dueño: ${_quiniela!['creada_por']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF013369),
                          ),
                        ),
                        SizedBox(height: 12),
                        if (_usuarioActual != null &&
                            _quiniela != null &&
                            _usuarioActual!.trim().toLowerCase() ==
                                _quiniela!['creada_por']
                                    .toString()
                                    .trim()
                                    .toLowerCase())
                          SizedBox(height: 12),
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
                                  color: Color(0xFFD50A0A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/nfl_logo.png',
                                      height: 24,
                                    ),
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
                        if (_quiniela!['mostrar_elecciones'] != true)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Los picks de los participantes están ocultos.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        SizedBox(height: 20),
                        Card(
                          color: Color(0xFF013369).withOpacity(0.07),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Participantes',
                                  style: GoogleFonts.oswald(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD50A0A),
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2,
                                        color: Colors.black26,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                ...(_quiniela!['participantes'] as List).map<
                                  Widget
                                >((p) {
                                  final eleccionesParticipante = _elecciones
                                      .firstWhere(
                                        (e) =>
                                            e['participante']
                                                .toString()
                                                .trim()
                                                .toLowerCase() ==
                                            p.toString().trim().toLowerCase(),
                                        orElse: () => null,
                                      );
                                  return ExpansionTile(
                                    backgroundColor: Color(
                                      0xFF013369,
                                    ).withOpacity(0.06),
                                    collapsedBackgroundColor: Color(
                                      0xFF013369,
                                    ).withOpacity(0.03),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.toString().toUpperCase(),
                                            style: GoogleFonts.oswald(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF013369),
                                              letterSpacing: 1.1,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 1,
                                                  color: Colors.black12,
                                                  offset: Offset(1, 1),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Flexible(
                                          child: Builder(
                                            builder: (context) {
                                              final userRank = _ranking
                                                  .firstWhere(
                                                    (r) =>
                                                        r['usuario']
                                                            .toString()
                                                            .trim()
                                                            .toLowerCase() ==
                                                        p
                                                            .toString()
                                                            .trim()
                                                            .toLowerCase(),
                                                    orElse: () => null,
                                                  );
                                              if (userRank != null) {
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                    left: 6,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFD50A0A),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Aciertos: ${userRank['aciertos']} | %: ${userRank['porcentaje']}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }
                                              return SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    children:
                                        (_quiniela!['mostrar_elecciones'] ==
                                                true ||
                                            p == _usuarioActual)
                                        ? (eleccionesParticipante != null
                                              ? (eleccionesParticipante['elecciones']
                                                        as List)
                                                    .map<Widget>((el) {
                                                      final local =
                                                          el['equipo_local'];
                                                      final visitante =
                                                          el['equipo_visitante'];
                                                      final elegido =
                                                          el['equipo_elegido']
                                                              is Map
                                                          ? el['equipo_elegido']
                                                          : null;
                                                      final resultado =
                                                          el['resultado_real']
                                                              is Map
                                                          ? el['resultado_real']
                                                          : null;
                                                      return ListTile(
                                                        title: Text(
                                                          '${local['nombre'] ?? ''} vs ${visitante['nombre'] ?? ''}',
                                                          style:
                                                              GoogleFonts.bebasNeue(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFF013369,
                                                                ),
                                                                letterSpacing:
                                                                    1.5,
                                                                shadows: [
                                                                  Shadow(
                                                                    blurRadius:
                                                                        2,
                                                                    color: Colors
                                                                        .black12,
                                                                    offset:
                                                                        Offset(
                                                                          1,
                                                                          1,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                        ),
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (elegido != null)
                                                              Row(
                                                                children: [
                                                                  // Logo de la elección
                                                                  if (elegido !=
                                                                      null)
                                                                    Column(
                                                                      children: [
                                                                        networkImageWithSvg(
                                                                          elegido['logo_url'],
                                                                          height:
                                                                              28,
                                                                          width:
                                                                              28,
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              2,
                                                                        ),
                                                                        Text(
                                                                          'Elegido',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            color: Color(
                                                                              0xFFD50A0A,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  SizedBox(
                                                                    width: 12,
                                                                  ),
                                                                  // Logo del ganador, más grande y con borde/fondo
                                                                  if (resultado !=
                                                                      null)
                                                                    Column(
                                                                      children: [
                                                                        Container(
                                                                          decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border: Border.all(
                                                                              color: Color(
                                                                                0xFFD50A0A,
                                                                              ),
                                                                              width: 3,
                                                                            ),
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                color: Colors.black12,
                                                                                blurRadius: 6,
                                                                                offset: Offset(
                                                                                  0,
                                                                                  2,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          child: networkImageWithSvg(
                                                                            resultado['logo_url'],
                                                                            height:
                                                                                38,
                                                                            width:
                                                                                38,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              2,
                                                                        ),
                                                                        Text(
                                                                          'Ganador',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            color: Color(
                                                                              0xFF013369,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  // Nombre del equipo ganador
                                                                  if (resultado !=
                                                                      null)
                                                                    Text(
                                                                      resultado['nombre'] ??
                                                                          '',
                                                                      style: TextStyle(
                                                                        color: Color(
                                                                          0xFF013369,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    })
                                                    .toList()
                                              : [
                                                  ListTile(
                                                    title: Text(
                                                      'Sin picks registrados',
                                                    ),
                                                  ),
                                                ])
                                        : [
                                            ListTile(
                                              title: Text(
                                                p == _usuarioActual
                                                    ? 'Tus picks están ocultos para los demás.'
                                                    : 'Los picks de este participante están ocultos.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Partidos:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD50A0A),
                          ),
                        ),
                        SizedBox(height: 10),
                        Card(
                          color: Color(0xFFD50A0A).withOpacity(0.07),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _partidos.length,
                            itemBuilder: (context, idx) {
                              final partido = _partidos[idx];
                              final local = partido['equipo_local'];
                              final visitante = partido['equipo_visitante'];
                              final resultado = partido['resultado_real'];

                              return Card(
                                margin: EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                child: ListTile(
                                  leading: networkImageWithSvg(
                                    local['logo_url'],
                                    height: 28,
                                    width: 28,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${local['nombre']} vs ${visitante['nombre']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha: ${partido['fecha'] != null ? DateTime.parse(partido['fecha']).toLocal().toString().split(".")[0] : "Sin fecha"}',
                                        style: TextStyle(
                                          color: Color(0xFF013369),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (resultado != null)
                                        Row(
                                          children: [
                                            networkImageWithSvg(
                                              resultado['logo_url'],
                                              height: 28,
                                              width: 28,
                                            ),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Ganador: ${resultado['nombre'] ?? ''}',
                                                style: TextStyle(
                                                  color: Color(0xFFD50A0A),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: networkImageWithSvg(
                                    visitante['logo_url'],
                                    height: 28,
                                    width: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 24),
                        if (_usuarioActual != null &&
                            _quiniela != null &&
                            _usuarioActual!.trim().toLowerCase() ==
                                _quiniela!['creada_por']
                                    .toString()
                                    .trim()
                                    .toLowerCase()) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'No puedes agregar partidos si no eres el dueño de la quniela.',
                              style: TextStyle(
                                color: Color(0xFFD50A0A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Agregar Partido NFL',
                            style: GoogleFonts.oswald(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD50A0A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _equipoLocalId,
                                  decoration: InputDecoration(
                                    labelText: 'Equipo Local',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _equipos.map<DropdownMenuItem<int>>((
                                    equipo,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: equipo['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize
                                            .min, // <-- Esto es clave
                                        children: [
                                          networkImageWithSvg(
                                            equipo['logo_url'],
                                            height: 28,
                                            width: 28,
                                          ),
                                          SizedBox(width: 6),
                                          // NO Flexible ni Expanded aquí
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: 120,
                                            ), // Ajusta el ancho máximo
                                            child: Text(
                                              '${equipo['abreviatura']} - ${equipo['nombre']}',
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.bebasNeue(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF013369),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _equipoLocalId = val;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _equipoVisitanteId,
                                  decoration: InputDecoration(
                                    labelText: 'Equipo Visitante',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _equipos.map<DropdownMenuItem<int>>((
                                    equipo,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: equipo['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          networkImageWithSvg(
                                            equipo['logo_url'],
                                            height: 28,
                                            width: 28,
                                          ),
                                          SizedBox(width: 6),
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: 110,
                                            ), // Ajusta según tu diseño
                                            child: Text(
                                              '${equipo['abreviatura']} - ${equipo['nombre']}',
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.bebasNeue(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF013369),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _equipoVisitanteId = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                        Duration(days: 1),
                                      ),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _fechaPartido = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Fecha y hora',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      _fechaPartido != null
                                          ? '${_fechaPartido!.toLocal()}'.split(
                                              '.',
                                            )[0]
                                          : 'Selecciona fecha y hora',
                                      style: GoogleFonts.oswald(
                                        color: Color(0xFF013369),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: Icon(Icons.add, color: Colors.white),
                                label: Text('Agregar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFD50A0A),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed:
                                    (_equipoLocalId != null &&
                                        _equipoVisitanteId != null &&
                                        _equipoLocalId != _equipoVisitanteId &&
                                        _fechaPartido != null)
                                    ? () async {
                                        final ok =
                                            await ApiService.agregarPartido(
                                              widget.quinielaId,
                                              _equipoLocalId!,
                                              _equipoVisitanteId!,
                                              _fechaPartido!,
                                            );
                                        if (ok) {
                                          _equipoLocalId = null;
                                          _equipoVisitanteId = null;
                                          _fechaPartido = null;
                                          await _loadDetalle();
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Partido agregado'),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error al agregar partido',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                                dynamic local = p['equipo_local'];
                                if (local is! Map) {
                                  local = _equipos.firstWhere(
                                    (e) => e['id'] == local,
                                    orElse: () => {'nombre': 'Desconocido'},
                                  );
                                }
                                dynamic visitante = p['equipo_visitante'];
                                if (visitante is! Map) {
                                  visitante = _equipos.firstWhere(
                                    (e) => e['id'] == visitante,
                                    orElse: () => {'nombre': 'Desconocido'},
                                  );
                                }
                                return DropdownMenuItem<int>(
                                  value: p['id'],
                                  child: Text(
                                    '${local['nombre']} vs ${visitante['nombre']}',
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFD50A0A),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: Icon(Icons.edit, size: 20),
                backgroundColor: Color(0xFFD50A0A),
                tooltip: 'Ingresar resultado',
              ),
            FloatingActionButton(
              heroTag: 'eleccion',
              mini: true,
              onPressed: yaCompletoTodos
                  ? null
                  : () async {
                      final confirmado = await _getEleccionesConfirmadas();
                      if (confirmado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ya confirmaste tus picks. No puedes editarlos.',
                            ),
                          ),
                        );
                        return;
                      }
                      await _elegirEquipo(partidosYaElegidos);
                    },
              child: Icon(Icons.sports_football, size: 20),
              backgroundColor: Color(0xFF013369),
              tooltip: 'Elegir equipo',
            ),
          ],
        ),
      ),
    );
  }
}
