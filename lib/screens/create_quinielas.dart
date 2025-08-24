import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/animation_service.dart';
import '../services/cache_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class CrearQuinielaScreen extends StatefulWidget {
  @override
  _CrearQuinielaScreenState createState() => _CrearQuinielaScreenState();
}

class _CrearQuinielaScreenState extends State<CrearQuinielaScreen>
    with TickerProviderStateMixin {
  final _nombreQController = TextEditingController();
  final _apuestaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = false;
  String? _usuarioActual;
  bool _isFormValid = false;
  
  // Animaciones
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _loadUsuarioActual();
    _setupAnimations();
    _startAnimations();
    
    // Validar formulario en tiempo real
    _nombreQController.addListener(_validateForm);
    _apuestaController.addListener(_validateForm);
  }

  void _setupAnimations() {
    // Controlador para el logo
    _logoController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Controlador para el formulario
    _formController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Controlador para el botón
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Animaciones del logo
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Animaciones del formulario
    _formOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeInOut,
    ));
    
    _formSlide = Tween<Offset>(
      begin: Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutBack,
    ));

    // Animaciones del botón
    _buttonScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    
    Future.delayed(Duration(milliseconds: 800), () {
      _formController.forward();
    });
    
    Future.delayed(Duration(milliseconds: 1500), () {
      _buttonController.forward();
    });
  }

  void _validateForm() {
    final isValid = _nombreQController.text.isNotEmpty &&
        _apuestaController.text.isNotEmpty &&
        double.tryParse(_apuestaController.text) != null &&
        double.tryParse(_apuestaController.text)! > 0;
    
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _showSnack(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isSuccess ? Color(0xFF4CAF50) : Color(0xFFD50A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _crearQuiniela() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      bool ok = await ApiService.agregarQuiniela(
        _nombreQController.text.trim(),
        double.tryParse(_apuestaController.text) ?? 0.0,
      );
      
      if (ok) {
        _showSnack("¡Quiniela creada exitosamente! 🏈", true);
        
        // Animación de éxito antes de regresar
        await _buttonController.animateTo(1.2, duration: Duration(milliseconds: 200));
        await _buttonController.animateTo(1.0, duration: Duration(milliseconds: 200));
        
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.pop(context, true);
        });
      } else {
        _showSnack("Error al crear quiniela. Intenta de nuevo.", false);
      }
    } catch (e) {
      _showSnack("Error de conexión. Verifica tu internet.", false);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioActual = prefs.getString('username');
    });
  }

  @override
  void dispose() {
    _nombreQController.dispose();
    _apuestaController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              child: Image.asset('assets/nfl_logo.png', height: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Crear Quiniela NFL",
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_usuarioActual != null)
                    Text(
                      '$_usuarioActual',
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
        flexibleSpace: Container(
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
      backgroundColor: Color(0xFFF5F7FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo animado
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value * 2 * 3.14159,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFD50A0A),
                                    Color(0xFFB71C1C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFD50A0A).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/nfl_logo.png',
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Título animado
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          '¡Crea tu Quiniela NFL!',
                          textStyle: GoogleFonts.oswald(
                            fontSize: 28,
                            color: Color(0xFF013369),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          speed: Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Descripción
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        "Llena los datos para agregar una nueva quiniela y reta a tus amigos a predecir los partidos de la NFL. ¡Que comience la competencia! 🏈",
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          color: Color(0xFF013369),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Formulario animado
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _formOpacity,
                          child: SlideTransition(
                            position: _formSlide,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    // Campo nombre
                                    _buildTextField(
                                      controller: _nombreQController,
                                      label: "Nombre de la Quiniela",
                                      icon: Icons.title,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El nombre es requerido';
                                        }
                                        if (value.trim().length < 3) {
                                          return 'El nombre debe tener al menos 3 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    SizedBox(height: 24),
                                    
                                    // Campo apuesta
                                    _buildTextField(
                                      controller: _apuestaController,
                                      label: "Apuesta Individual (\$)",
                                      icon: Icons.attach_money,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'La apuesta es requerida';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null || amount <= 0) {
                                          return 'Ingresa un monto válido mayor a 0';
                                        }
                                        if (amount > 10000) {
                                          return 'La apuesta no puede ser mayor a \$10,000';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Botón animado
                    AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScale.value,
                          child: _loading
                              ? Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFD50A0A),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Creando Quiniela...',
                                          style: GoogleFonts.oswald(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.sports_football,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: _isFormValid ? _crearQuiniela : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFormValid 
                                          ? Color(0xFFD50A0A) 
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      elevation: _isFormValid ? 8 : 2,
                                      shadowColor: _isFormValid 
                                          ? Color(0xFFD50A0A).withOpacity(0.4)
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    label: Text(
                                      "Crear Quiniela",
                                      style: GoogleFonts.oswald(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.oswald(
        fontSize: 18,
        color: Color(0xFF013369),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.oswald(
          color: Color(0xFFD50A0A),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFD50A0A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Color(0xFFD50A0A)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD50A0A).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD50A0A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD50A0A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
