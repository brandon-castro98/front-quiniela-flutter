import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimationService {
  // Transiciones personalizadas entre pantallas
  static PageRouteBuilder<T> createCustomRoute<T>({
    required Widget child,
    RouteTransitionType transitionType = RouteTransitionType.slideRight,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(animation, child, transitionType, curve);
      },
    );
  }

  // Construir la transición según el tipo
  static Widget _buildTransition(
    Animation<double> animation,
    Widget child,
    RouteTransitionType transitionType,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (transitionType) {
      case RouteTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case RouteTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.5,
            end: 0.0,
          ).animate(curvedAnimation),
          child: child,
        );

      case RouteTransitionType.hero:
        return Hero(
          tag: 'screen_transition',
          child: child,
        );

      case RouteTransitionType.elastic:
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: Curves.elasticOut.transform(curvedAnimation.value),
              child: child,
            );
          },
          child: child,
        );

      case RouteTransitionType.bounce:
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: Curves.bounceOut.transform(curvedAnimation.value),
              child: child,
            );
          },
          child: child,
        );
    }
  }

  // Animación de entrada para widgets
  static Widget fadeInWidget({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOut,
    double beginOpacity = 0.0,
    double endOpacity = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: beginOpacity, end: endOpacity),
      curve: curve,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animación de escala para widgets
  static Widget scaleInWidget({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticOut,
    double beginScale = 0.0,
    double endScale = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: beginScale, end: endScale),
      curve: curve,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animación de deslizamiento para widgets
  static Widget slideInWidget({
    required Widget child,
    Duration duration = const Duration(milliseconds: 700),
    Curve curve = Curves.easeOutBack,
    Offset beginOffset = const Offset(0.0, 1.0),
    Offset endOffset = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      duration: duration,
      tween: Tween(begin: beginOffset, end: endOffset),
      curve: curve,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animación de rotación para widgets
  static Widget rotateInWidget({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    Curve curve = Curves.easeInOut,
    double beginRotation = 0.0,
    double endRotation = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: beginRotation, end: endRotation),
      curve: curve,
      builder: (context, rotation, child) {
        return Transform.rotate(
          angle: rotation * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animación de lista con delay escalonado
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration itemDelay = const Duration(milliseconds: 100),
    Duration animationDuration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutBack,
  }) {
    return children.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return TweenAnimationBuilder<double>(
        duration: animationDuration + (itemDelay * index),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: curve,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: child,
      );
    }).toList();
  }

  // Widget de carga animado con Lottie
  static Widget lottieLoader({
    String? assetPath,
    String? networkUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
  }) {
    if (assetPath != null) {
      return Lottie.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat,
      );
    } else if (networkUrl != null) {
      return Lottie.network(
        networkUrl,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat,
      );
    } else {
      // Fallback a CircularProgressIndicator
      return SizedBox(
        width: width ?? 50,
        height: height ?? 50,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD50A0A)),
          strokeWidth: 3,
        ),
      );
    }
  }

  // Animación de pulso para botones
  static Widget pulseButton({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    bool isAnimating = true,
  }) {
    if (!isAnimating) return child;
    
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 1.0, end: 1.05),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animación de rebote para notificaciones
  static Widget bounceNotification({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.bounceOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}

// Tipos de transiciones disponibles
enum RouteTransitionType {
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  fade,
  scale,
  rotation,
  hero,
  elastic,
  bounce,
}
