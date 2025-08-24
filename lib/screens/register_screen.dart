import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/animation_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _setupAnimations();
    _startAnimations();
    
    // Validar formulario en tiempo real
    _userController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passController.addListener(_validateForm);
    _confirmPassController.addListener(_validateForm);
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
    final isValid = _userController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passController.text.isNotEmpty &&
        _confirmPassController.text.isNotEmpty &&
        _passController.text == _confirmPassController.text &&
        _passController.text.length >= 6 &&
        _isValidEmail(_emailController.text);
    
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      bool ok = await ApiService.registrarUsuario(
        _userController.text.trim(),
        _emailController.text.trim(),
        _passController.text,
      );
      
      if (ok) {
        _showSnack("¡Usuario registrado exitosamente! 🎉", true);
        
        // Animación de éxito antes de regresar
        await _buttonController.animateTo(1.2, duration: Duration(milliseconds: 200));
        await _buttonController.animateTo(1.0, duration: Duration(milliseconds: 200));
        
        Future.delayed(Duration(milliseconds: 800), () {
          Navigator.pop(context);
        });
      } else {
        _showSnack("Error al registrar usuario. Intenta de nuevo.", false);
      }
    } catch (e) {
      _showSnack("Error de conexión. Verifica tu internet.", false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF013369),
              Color(0xFF1E4A8C),
              Color(0xFFD50A0A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
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
                    SizedBox(height: 40),
                    
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
                          'Registro de Usuario',
                          textStyle: GoogleFonts.oswald(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          speed: Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                      displayFullTextOnTap: true,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Subtítulo
                    Text(
                      'Únete a la comunidad de quinielas NFL',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 40),
                    
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
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    // Campo usuario
                                    _buildTextField(
                                      controller: _userController,
                                      label: "Nombre de Usuario",
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El usuario es requerido';
                                        }
                                        if (value.trim().length < 3) {
                                          return 'El usuario debe tener al menos 3 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Campo email
                                    _buildTextField(
                                      controller: _emailController,
                                      label: "Correo Electrónico",
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El email es requerido';
                                        }
                                        if (!_isValidEmail(value.trim())) {
                                          return 'Ingresa un email válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Campo contraseña
                                    _buildTextField(
                                      controller: _passController,
                                      label: "Contraseña",
                                      icon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: Color(0xFF013369),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La contraseña es requerida';
                                        }
                                        if (value.length < 6) {
                                          return 'La contraseña debe tener al menos 6 caracteres';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Campo confirmar contraseña
                                    _buildTextField(
                                      controller: _confirmPassController,
                                      label: "Confirmar Contraseña",
                                      icon: Icons.lock_outline,
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                          color: Color(0xFF013369),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirma tu contraseña';
                                        }
                                        if (value != _passController.text) {
                                          return 'Las contraseñas no coinciden';
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
                                          'Registrando...',
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
                                      Icons.person_add,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: _isFormValid ? _registrarUsuario : null,
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
                                      "Registrar Usuario",
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
                    
                    SizedBox(height: 24),
                    
                    // Enlace para ir al login
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
        suffixIcon: suffixIcon,
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
