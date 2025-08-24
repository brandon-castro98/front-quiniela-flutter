import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/animation_service.dart';
import 'create_quinielas.dart';
import 'detalle_quiniela_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class QuinielasScreen extends StatefulWidget {
  @override
  _QuinielasScreenState createState() => _QuinielasScreenState();
}

class _QuinielasScreenState extends State<QuinielasScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<dynamic> _quinielas = [];
  bool _loading = true;
  String? _usuarioActual;
  Timer? _sessionTimer;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'joined', 'available'
  Set<int> _deletingQuinielas = {}; // Para trackear quinielas siendo eliminadas
  
  // Animaciones
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  void _loadQuinielas() async {
    setState(() => _loading = true);
    
    try {
      // Cargar datos frescos desde la API primero
      final data = await ApiService.getQuinielas();
      
      if (mounted) {
        setState(() {
          _quinielas = data;
          _loading = false;
        });
        
        // Guardar en cache después de actualizar el estado
        await CacheService.cacheQuinielas(data);
      }
    } catch (e) {
      // Si falla la API, intentar cargar desde cache
      if (mounted) {
        final cachedData = await CacheService.getCachedQuinielas();
        setState(() {
          _quinielas = cachedData ?? [];
          _loading = false;
        });
        
        // Mostrar mensaje de error si no hay cache
        if (cachedData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar quinielas. Verifica tu conexión.'),
              backgroundColor: Color(0xFFD50A0A),
            ),
          );
        }
      }
    }
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

  List<dynamic> get _filteredQuinielas {
    var filtered = _quinielas.where((q) {
      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nombre = (q['nombre'] ?? '').toString().toLowerCase();
        final creador = (q['creada_por'] ?? '').toString().toLowerCase();
        if (!nombre.contains(query) && !creador.contains(query)) {
          return false;
        }
      }

      // Filtro por estado
      if (_filterStatus != 'all') {
        final isJoined = q['participantes'] != null &&
            _usuarioActual != null &&
            (q['participantes'] as List)
                .map((p) => p.toString().trim().toLowerCase())
                .contains(_usuarioActual!.trim().toLowerCase());

        if (_filterStatus == 'joined' && !isJoined) return false;
        if (_filterStatus == 'available' && isJoined) return false;
      }

      return true;
    }).toList();

    // Ordenar por fecha de creación (más recientes primero)
    filtered.sort((a, b) => (b['created_at'] ?? 0).compareTo(a['created_at'] ?? 0));
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _loadUsuarioActual();
    _loadQuinielas();
    _startSessionTimer();
  }
  
  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Llamar _loadQuinielas sin await ya que es void
      _loadQuinielas();
    }
  }
  
  // Método para refrescar la lista manualmente
  void _refreshQuinielas() {
    _loadQuinielas(); // No usar await ya que _loadQuinielas es void
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
              _sessionTimer?.cancel();
              final refreshed = await ApiService.refreshToken();
              if (refreshed) {
                _startSessionTimer();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Token refrescado')),
                );
              } else {
                _logout();
              }
            },
            child: Text('Refrescar token'),
          ),
        ],
      ),
    );
    _sessionTimer = Timer(Duration(seconds: 30), _logout);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF013369),
            elevation: 8,
            shadowColor: Colors.black26,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
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
                      height: 24,
                      width: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quinielas NFL',
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF013369),
                      Color(0xFF1E4A8C),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: _logout,
              ),
            ],
          ),

          // Barra de búsqueda y filtros
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      Container(
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
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Buscar quinielas...',
                            prefixIcon: Icon(Icons.search, color: Color(0xFF013369)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Filtros
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip('Todas', 'all'),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Disponibles', 'available'),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Unido', 'joined'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Lista de quinielas
          _loading
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD50A0A)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Cargando quinielas...',
                            style: TextStyle(
                              color: Color(0xFF013369),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _filteredQuinielas.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_football_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _filterStatus != 'all'
                                    ? 'No se encontraron quinielas con los filtros aplicados'
                                    : 'No hay quinielas disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty || _filterStatus != 'all')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _filterStatus = 'all';
                                    });
                                  },
                                  child: Text('Limpiar filtros'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                                     : SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                           final q = _filteredQuinielas[index];
                           return AnimatedBuilder(
                             animation: _fadeController,
                             builder: (context, child) {
                               return FadeTransition(
                                 opacity: _fadeAnimation,
                                 child: SlideTransition(
                                   position: _slideAnimation,
                                   child: _buildQuinielaCard(q),
                                 ),
                               );
                             },
                           );
                         },
                         childCount: _filteredQuinielas.length,
                       ),
                     ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
         animation: _fadeController,
         builder: (context, child) {
           return FadeTransition(
             opacity: _fadeAnimation,
             child: SlideTransition(
               position: _slideAnimation,
               child: FloatingActionButton.extended(
                 onPressed: () async {
                   final result = await Navigator.push(
                     context,
                     AnimationService.createCustomRoute(
                       child: CrearQuinielaScreen(),
                       transitionType: RouteTransitionType.slideUp,
                     ),
                   );
                   if (result == true) {
                     _loadQuinielas();
                   }
                 },
                 icon: Icon(Icons.add),
                 label: Text('Crear Quiniela'),
                 backgroundColor: Color(0xFFD50A0A),
                 foregroundColor: Colors.white,
                 elevation: 8,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(16),
                 ),
               ),
             ),
           );
         },
       ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(0xFF013369),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFFD50A0A),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildQuinielaCard(Map<String, dynamic> quiniela) {
    final isJoined = quiniela['participantes'] != null &&
        _usuarioActual != null &&
        (quiniela['participantes'] as List)
            .map((p) => p.toString().trim().toLowerCase())
            .contains(_usuarioActual!.trim().toLowerCase());

    final isOwner = _usuarioActual != null &&
        _usuarioActual!.trim().toLowerCase() ==
            (quiniela['creada_por'] ?? '').toString().trim().toLowerCase();

    final participantesCount = (quiniela['participantes'] as List?)?.length ?? 0;
    final partidosCount = (quiniela['partidos'] as List?)?.length ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isJoined
              ? [Color(0xFF4CAF50), Color(0xFF2E7D32)]
              : [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isJoined
              ? () {
                  Navigator.push(
                    context,
                    AnimationService.createCustomRoute(
                      child: DetalleQuinielaScreen(
                        quinielaId: quiniela['id'],
                      ),
                      transitionType: RouteTransitionType.slideRight,
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isJoined ? Colors.white : Color(0xFF013369),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: isJoined ? Color(0xFF4CAF50) : Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiniela['nombre'] ?? 'Quiniela NFL',
                            style: GoogleFonts.oswald(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isJoined ? Colors.white : Color(0xFF013369),
                              letterSpacing: 1.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Creada por ${quiniela['creada_por'] ?? 'N/A'}',
                            style: TextStyle(
                              color: isJoined ? Colors.white70 : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isJoined)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'UNIDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),

                // Información de la quiniela
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Apuesta',
                        '\$${quiniela['apuesta_individual']}',
                        Icons.attach_money,
                        Color(0xFF4CAF50),
                        isJoined,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Participantes',
                        '$participantesCount',
                        Icons.people,
                        Color(0xFF2196F3),
                        isJoined,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Partidos',
                        '$partidosCount',
                        Icons.sports_football,
                        Color(0xFFFF9800),
                        isJoined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Botones de acción
                Row(
                  children: [
                    if (!isJoined)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            bool joined = await ApiService.unirseQuiniela(quiniela['id']);
                            if (joined) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Te uniste a la quiniela!'),
                                  backgroundColor: Color(0xFF4CAF50),
                                ),
                              );
                              _loadQuinielas();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ya perteneces a esta quiniela'),
                                  backgroundColor: Color(0xFFFF9800),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.add, size: 18),
                          label: Text(
                            'Unirse',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD50A0A),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (isJoined)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalleQuinielaScreen(
                                  quinielaId: quiniela['id'],
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            'Ver Detalles',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF4CAF50),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (isOwner)
                      Container(
                        margin: EdgeInsets.only(left: 12),
                        child: IconButton(
                          icon: _deletingQuinielas.contains(quiniela['id'])
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                  ),
                                )
                              : Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                  size: 24,
                                ),
                          onPressed: _deletingQuinielas.contains(quiniela['id'])
                              ? null
                              : () => _showDeleteConfirmation(quiniela),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, bool isJoined) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isJoined ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isJoined ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isJoined ? Colors.white : Color(0xFF013369),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isJoined ? Colors.white70 : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> quiniela) {
    // Si ya se está eliminando, no mostrar el diálogo
    if (_deletingQuinielas.contains(quiniela['id'])) {
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Quiniela'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${quiniela['nombre']}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Marcar como eliminando
              setState(() {
                _deletingQuinielas.add(quiniela['id']);
              });
              
              bool eliminado = await ApiService.eliminarQuiniela(quiniela['id']);
              
              if (eliminado) {
                // Actualizar el estado local inmediatamente
                setState(() {
                  _quinielas.removeWhere((q) => q['id'] == quiniela['id']);
                  _deletingQuinielas.remove(quiniela['id']);
                });
                
                // Limpiar el cache para forzar recarga
                await CacheService.clearAllCache();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quiniela eliminada exitosamente'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
                
                // Recargar desde la API para asegurar sincronización
                _loadQuinielas();
              } else {
                // Remover del estado de eliminando
                setState(() {
                  _deletingQuinielas.remove(quiniela['id']);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No tienes permisos para eliminar esta quiniela'),
                    backgroundColor: Color(0xFFD50A0A),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
