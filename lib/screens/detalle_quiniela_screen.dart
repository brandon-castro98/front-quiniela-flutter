import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget networkImageWithSvg(String? url, {double? height, double? width}) {
  return CacheService.getCachedImage(
    imageUrl: url,
    height: height,
    width: width,
    fit: BoxFit.contain,
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
    // Intentar cargar desde cache primero
    final cachedEquipos = await CacheService.getCachedEquipos();
    if (cachedEquipos != null) {
      _equipos = cachedEquipos;
      setState(() {});
    }
    
    // Cargar datos frescos desde la API
    try {
      final data = await ApiService.getEquipos();
      _equipos = data;
      setState(() {});
      
      // Guardar en cache
      await CacheService.cacheEquipos(data);
    } catch (e) {
      // Si falla la API, mantener los datos del cache si existen
      if (cachedEquipos == null) {
        setState(() {});
      }
    }
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
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con gradiente
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD50A0A),
                        Color(0xFFB71C1C),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Color(0xFFD50A0A),
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resultado del Partido',
                              style: GoogleFonts.oswald(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Selecciona el equipo ganador',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido del diálogo
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Información del partido
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF013369),
                                Color(0xFF1E4A8C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF013369).withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'VS',
                                style: GoogleFonts.oswald(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              SizedBox(height: 20),
                              
                              // Equipos enfrentados
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTeamPreview(local, 'Local'),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: _buildTeamPreview(visitante, 'Visitante'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Selección de ganador
                        Text(
                          '¿Quién ganó el partido?',
                          style: GoogleFonts.oswald(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF013369),
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Opciones de equipos
                        Column(
                          children: [
                            // Equipo Local
                            _buildTeamSelectionCard(
                              local,
                              'Local',
                              equipoGanadorId == local['id'],
                              () {
                                setState(() {
                                  equipoGanadorId = local['id'];
                                });
                              },
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Equipo Visitante
                            _buildTeamSelectionCard(
                              visitante,
                              'Visitante',
                              equipoGanadorId == visitante['id'],
                              () {
                                setState(() {
                                  equipoGanadorId = visitante['id'];
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Botones de acción
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Color(0xFF013369)),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.oswald(
                              color: Color(0xFF013369),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: equipoGanadorId != null
                              ? () => Navigator.pop(context, true)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: equipoGanadorId != null 
                                ? Color(0xFF4CAF50) 
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: equipoGanadorId != null ? 8 : 2,
                            shadowColor: equipoGanadorId != null 
                                ? Color(0xFF4CAF50).withOpacity(0.4)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Guardar',
                                style: GoogleFonts.oswald(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && equipoGanadorId != null) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
                SizedBox(height: 16),
                Text(
                  'Guardando resultado...',
                  style: TextStyle(
                    color: Color(0xFF013369),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final resp = await ApiService.ingresarResultado(
        widget.quinielaId,
        partidoId,
        equipoGanadorId!,
      );
      
      // Cerrar loading
      Navigator.pop(context);
      
             if (resp) {
         await _loadDetalle();
         await _loadElecciones();
         await _loadRanking();
         if (mounted) setState(() {});
         
         // Mostrar notificación push para todos los participantes
         if (_quiniela != null) {
           final equipoGanador = equipoGanadorId == local['id'] ? local : visitante;
           final equipoPerdedor = equipoGanadorId == local['id'] ? visitante : local;
           
           await NotificationService.showResultNotification(
             quinielaName: _quiniela!['nombre'] ?? 'Quiniela NFL',
             equipoGanador: equipoGanador['nombre'] ?? '',
             equipoPerdedor: equipoPerdedor['nombre'] ?? '',
             quinielaId: widget.quinielaId,
           );
         }
         
         // Mostrar confirmación
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Row(
               children: [
                 Icon(Icons.check_circle, color: Colors.white),
                 SizedBox(width: 12),
                 Text('Resultado guardado exitosamente'),
               ],
             ),
             backgroundColor: Color(0xFF4CAF50),
             duration: Duration(seconds: 3),
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(12),
             ),
           ),
         );
       } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Error al guardar resultado'),
              ],
            ),
            backgroundColor: Color(0xFFD50A0A),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
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
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de la Quiniela',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_usuarioActual != null)
                    Text(
                      _usuarioActual!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF013369),
        elevation: 8,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFF5F7FA),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD50A0A)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando quiniela...',
                    style: TextStyle(
                      color: Color(0xFF013369),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _quiniela == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFD50A0A),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No se encontró la quiniela',
                        style: TextStyle(
                          color: Color(0xFF013369),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header principal con información de la quiniela
                        _buildQuinielaHeader(),
                        SizedBox(height: 20),
                        
                        // Estadísticas del usuario actual
                        if (_usuarioActual != null) _buildUserStats(),
                        SizedBox(height: 20),
                        
                        // Control de visibilidad de picks
                        _buildVisibilityControl(),
                        SizedBox(height: 20),
                        
                        // Lista de participantes
                        _buildParticipantsSection(),
                        SizedBox(height: 20),
                        
                        // Sección de partidos
                        _buildPartidosSection(),
                        SizedBox(height: 20),
                        
                        // Formulario para agregar partidos (solo para dueños)
                        if (_usuarioActual != null &&
                            _quiniela != null &&
                            _usuarioActual!.trim().toLowerCase() ==
                                _quiniela!['creada_por'].toString().trim().toLowerCase())
                          _buildAddPartidoSection(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildQuinielaHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF013369),
            Color(0xFF1E4A8C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo NFL y título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/nfl_logo.png',
                    height: 40,
                    width: 40,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _quiniela!['nombre'] ?? 'Quiniela NFL',
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Información de apuesta y dueño
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Apuesta',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${_quiniela!['apuesta_individual']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dueño',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _quiniela!['creada_por'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    final userRank = _ranking.firstWhere(
      (r) => r['usuario'] == _usuarioActual,
      orElse: () => null,
    );
    
    if (userRank == null) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD50A0A),
            Color(0xFFB71C1C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD50A0A).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/nfl_logo.png',
                    height: 24,
                    width: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'TUS ESTADÍSTICAS',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aciertos',
                    '${userRank['aciertos']}',
                    Icons.check_circle,
                    Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Porcentaje',
                    '${userRank['porcentaje']}%',
                    Icons.percent,
                    Color(0xFF2196F3),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Partidos',
                    '${_partidos.length}',
                    Icons.sports_football,
                    Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityControl() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility,
            color: Color(0xFF013369),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mostrar picks de todos:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF013369),
              ),
            ),
          ),
          Switch(
            value: _quiniela!['mostrar_elecciones'] ?? false,
            activeColor: Color(0xFFD50A0A),
            activeTrackColor: Color(0xFFD50A0A).withOpacity(0.3),
            onChanged: (_usuarioActual != null &&
                    _quiniela != null &&
                    _usuarioActual!.trim().toLowerCase() ==
                        _quiniela!['creada_por'].toString().trim().toLowerCase())
                ? (val) async {
                    final ok = await ApiService.setMostrarElecciones(
                      widget.quinielaId,
                      val,
                    );
                    if (ok) {
                      await _loadDetalle();
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar visibilidad'),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD50A0A),
                  Color(0xFFB71C1C),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Participantes',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_quiniela!['participantes'].length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de participantes
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: (_quiniela!['participantes'] as List).map<Widget>((p) {
                final eleccionesParticipante = _elecciones.firstWhere(
                  (e) =>
                      e['participante'].toString().trim().toLowerCase() ==
                      p.toString().trim().toLowerCase(),
                  orElse: () => null,
                );
                
                final userRank = _ranking.firstWhere(
                  (r) =>
                      r['usuario'].toString().trim().toLowerCase() ==
                      p.toString().trim().toLowerCase(),
                  orElse: () => null,
                );
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: p == _usuarioActual 
                        ? Color(0xFFE3F2FD) 
                        : Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: p == _usuarioActual 
                        ? Border.all(color: Color(0xFF2196F3), width: 2)
                        : null,
                  ),
                  child: ExpansionTile(
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                    title: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: p == _usuarioActual 
                                ? Color(0xFF2196F3) 
                                : Color(0xFF013369),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p == _usuarioActual ? Icons.person : Icons.person_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.toString().toUpperCase(),
                                style: GoogleFonts.oswald(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF013369),
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p == _usuarioActual)
                                Text(
                                  'Tú',
                                  style: TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (userRank != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD50A0A), Color(0xFFB71C1C)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFD50A0A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${userRank['aciertos']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Aciertos',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF013369).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${userRank?['porcentaje'] ?? 0}%',
                            style: TextStyle(
                              color: Color(0xFF013369),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: (_quiniela!['mostrar_elecciones'] == true || p == _usuarioActual)
                        ? (eleccionesParticipante != null
                              ? (eleccionesParticipante['elecciones'] as List).map<Widget>((el) {
                                  final local = el['equipo_local'];
                                  final visitante = el['equipo_visitante'];
                                  final elegido = el['equipo_elegido'] is Map ? el['equipo_elegido'] : null;
                                  final resultado = el['resultado_real'] is Map ? el['resultado_real'] : null;
                                  
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${local['nombre'] ?? ''} vs ${visitante['nombre'] ?? ''}',
                                          style: GoogleFonts.bebasNeue(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF013369),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (elegido != null) ...[
                                              _buildTeamChoice(
                                                elegido,
                                                'Elegido',
                                                Color(0xFFD50A0A),
                                                true,
                                              ),
                                              SizedBox(width: 16),
                                            ],
                                            if (resultado != null) ...[
                                              _buildTeamChoice(
                                                resultado,
                                                'Ganador',
                                                Color(0xFF4CAF50),
                                                false,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()
                              : [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Sin picks registrados',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ])
                        : [
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                p == _usuarioActual
                                    ? 'Tus picks están ocultos para los demás.'
                                    : 'Los picks de este participante están ocultos.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamChoice(Map<String, dynamic> team, String label, Color color, bool isSelected) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: networkImageWithSvg(
              team['logo_url'],
              height: 24,
              width: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            team['nombre'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF013369),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPartidosSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF013369),
                  Color(0xFF1E4A8C),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_football,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Partidos',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_partidos.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de partidos
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: _partidos.asMap().entries.map<Widget>((entry) {
                final idx = entry.key;
                final partido = entry.value;
                final local = partido['equipo_local'];
                final visitante = partido['equipo_visitante'];
                final resultado = partido['resultado_real'];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Número de partido
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF013369),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Partido ${idx + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Equipos
                        Row(
                          children: [
                            Expanded(
                              child: _buildTeamDisplay(local, 'Local'),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFFD50A0A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildTeamDisplay(visitante, 'Visitante'),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Fecha
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF013369).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Color(0xFF013369),
                              ),
                              SizedBox(width: 6),
                              Text(
                                partido['fecha'] != null 
                                    ? DateTime.parse(partido['fecha']).toLocal().toString().split(".")[0]
                                    : "Sin fecha",
                                style: TextStyle(
                                  color: Color(0xFF013369),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Resultado si existe
                        if (resultado != null) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF4CAF50),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                networkImageWithSvg(
                                  resultado['logo_url'],
                                  height: 20,
                                  width: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ganador: ${resultado['nombre'] ?? ''}',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(Map<String, dynamic> team, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: networkImageWithSvg(
            team['logo_url'],
            height: 32,
            width: 32,
          ),
        ),
        SizedBox(height: 8),
        Text(
          team['nombre'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF013369),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget para mostrar preview del equipo en el diálogo de resultados
  Widget _buildTeamPreview(Map<String, dynamic> team, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: networkImageWithSvg(
              team['logo_url'],
              height: 56,
              width: 56,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          team['nombre'] ?? '',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para la selección de equipo ganador
  Widget _buildTeamSelectionCard(
    Map<String, dynamic> team,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4CAF50).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF4CAF50) : Colors.grey.withOpacity(0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF4CAF50) : Color(0xFF013369),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? Color(0xFF4CAF50) : Color(0xFF013369)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: networkImageWithSvg(
                team['logo_url'],
                height: 40,
                width: 40,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team['nombre'] ?? '',
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF013369),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Equipo $label',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPartidoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con gradiente
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD50A0A),
                  Color(0xFFB71C1C),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_circle,
                    color: Color(0xFFD50A0A),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Agregar Partido NFL',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido del formulario
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de ayuda
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF2196F3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Agrega nuevos partidos a tu quiniela. Los participantes podrán hacer sus picks una vez que se agreguen.',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Selección de equipos
                Text(
                  'Selecciona los equipos',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013369),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTeamDropdown(
                        'Equipo Local',
                        _equipoLocalId,
                        (val) => setState(() => _equipoLocalId = val),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFD50A0A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTeamDropdown(
                        'Equipo Visitante',
                        _equipoVisitanteId,
                        (val) => setState(() => _equipoVisitanteId = val),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Selección de fecha y hora
                Text(
                  'Fecha y hora del partido',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013369),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTimePicker(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Validaciones
                if (_equipoLocalId != null && _equipoVisitanteId != null && _equipoLocalId == _equipoVisitanteId)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE53935),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los equipos local y visitante no pueden ser iguales',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 20),
                
                // Botón de agregar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text(
                      'Agregar Partido',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD50A0A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: (_equipoLocalId != null &&
                            _equipoVisitanteId != null &&
                            _equipoLocalId != _equipoVisitanteId &&
                            _fechaPartido != null)
                        ? _agregarPartido
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDropdown(String label, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _equipos.map<DropdownMenuItem<int>>((equipo) {
        return DropdownMenuItem<int>(
          value: equipo['id'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              networkImageWithSvg(
                equipo['logo_url'],
                height: 24,
                width: 24,
              ),
              SizedBox(width: 8),
              Flexible(
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
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 1)),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          final currentTime = _fechaPartido ?? DateTime.now();
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(currentTime),
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
          labelText: 'Fecha',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF013369)),
        ),
        child: Text(
          _fechaPartido != null
              ? '${_fechaPartido!.day}/${_fechaPartido!.month}/${_fechaPartido!.year}'
              : 'Selecciona fecha',
          style: GoogleFonts.oswald(
            color: Color(0xFF013369),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final currentTime = _fechaPartido ?? DateTime.now();
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(currentTime),
        );
        if (time != null) {
          setState(() {
            if (_fechaPartido != null) {
              _fechaPartido = DateTime(
                _fechaPartido!.year,
                _fechaPartido!.month,
                _fechaPartido!.day,
                time.hour,
                time.minute,
              );
            } else {
              final now = DateTime.now();
              _fechaPartido = DateTime(
                now.year,
                now.month,
                now.day,
                time.hour,
                time.minute,
              );
            }
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.access_time, color: Color(0xFF013369)),
        ),
        child: Text(
          _fechaPartido != null
              ? '${_fechaPartido!.hour.toString().padLeft(2, '0')}:${_fechaPartido!.minute.toString().padLeft(2, '0')}'
              : 'Selecciona hora',
          style: GoogleFonts.oswald(
            color: Color(0xFF013369),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
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
        
    return Align(
      alignment: Alignment.bottomRight,
      child: Wrap(
        spacing: 12,
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
                          title: Text('Selecciona partido para ingresar resultado'),
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
                                child: Text('${local['nombre']} vs ${visitante['nombre']}'),
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
                          content: Text('Ya confirmaste tus picks. No puedes editarlos.'),
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
    );
  }
}
