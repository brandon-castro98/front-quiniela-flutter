import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import '../services/animation_service.dart';
import 'register_screen.dart';
import 'quinielas_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;
  
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    
    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Form animations
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
    );
    
    _formSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOutBack));

    // Button animations
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    // Background animations
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _formController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _buttonController.forward();
    
    _backgroundController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    // Simulate API delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    final success = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _loading = false;
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text.trim());
      
      // Navigate with custom animation
      Navigator.pushAndRemoveUntil(
        context,
        AnimationService.createCustomRoute(
          child: QuinielasScreen(),
          transitionType: RouteTransitionType.slideRight,
          duration: Duration(milliseconds: 800),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _error = 'Usuario o contraseña incorrectos';
      });
      
      // Shake animation for error
      _formController.animateTo(0.0, duration: Duration(milliseconds: 100))
          .then((_) => _formController.forward());
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        return Transform.translate(
          offset: _formSlide.value * 20,
          child: Opacity(
            opacity: _formOpacity.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword ? _obscurePassword : false,
                validator: validator ?? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es requerido';
                  }
                  if (isPassword && value.length < 5) {
                    return 'La contraseña debe tener al menos 5 caracteres';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: Color(0xFF013369)),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Color(0xFF013369),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF013369)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF013369).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFD50A0A), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF013369).withOpacity(_backgroundOpacity.value),
                  Color(0xFFD50A0A).withOpacity(_backgroundOpacity.value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Animated background elements
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                
                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo section
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Transform.rotate(
                                angle: _logoRotation.value * 0.1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/nfl_logo.png',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Title with animated text
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              '¡Bienvenido a la Quiniela NFL!',
                              textStyle: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              speed: Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Subtitle
                        Text(
                          'Compite, predice y gana como un verdadero fan de la NFL',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Login form
                        AnimatedBuilder(
                          animation: _formController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: _formSlide.value * 50,
                              child: Opacity(
                                opacity: _formOpacity.value,
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(maxWidth: 400),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          // Username field
                                          _buildTextField(
                                            controller: _usernameController,
                                            label: 'Usuario',
                                            icon: Icons.person,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Ingresa tu nombre de usuario';
                                              }
                                              if (value.trim().length < 3) {
                                                return 'El usuario debe tener al menos 3 caracteres';
                                              }
                                              return null;
                                            },
                                          ),
                                          
                                          // Password field
                                          _buildTextField(
                                            controller: _passwordController,
                                            label: 'Contraseña',
                                            icon: Icons.lock,
                                            isPassword: true,
                                          ),
                                          
                                          // Remember me checkbox
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                                activeColor: Color(0xFFD50A0A),
                                              ),
                                              Text(
                                                'Recordar sesión',
                                                style: TextStyle(
                                                  color: Color(0xFF013369),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(height: 24),
                                          
                                          // Login button
                                          AnimatedBuilder(
                                            animation: _buttonController,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _buttonScale.value,
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  height: 56,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Color(0xFFD50A0A),
                                                      foregroundColor: Colors.white,
                                                      elevation: 8,
                                                      shadowColor: Color(0xFFD50A0A).withOpacity(0.4),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                    ),
                                                    onPressed: _loading ? null : _login,
                                                    child: _loading
                                                        ? Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                                ),
                                                              ),
                                                              SizedBox(width: 12),
                                                              Text(
                                                                'Iniciando sesión...',
                                                                style: TextStyle(fontSize: 16),
                                                              ),
                                                            ],
                                                          )
                                                        : Text(
                                                            'Iniciar Sesión',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1.0,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          
                                          // Error message
                                          if (_error != null) ...[
                                            SizedBox(height: 16),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color: Colors.red.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          
                                          SizedBox(height: 24),
                                          
                                          // Register link
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '¿No tienes cuenta? ',
                                                style: TextStyle(
                                                  color: Color(0xFF013369).withOpacity(0.7),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    AnimationService.createCustomRoute(
                                                      child: RegisterScreen(),
                                                      transitionType: RouteTransitionType.slideUp,
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Regístrate',
                                                  style: TextStyle(
                                                    color: Color(0xFFD50A0A),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    decoration: TextDecoration.underline,
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
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Footer
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            'NFL Official App developed for Jonathan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
