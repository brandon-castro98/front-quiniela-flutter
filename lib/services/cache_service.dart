import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _cacheKey = 'quiniela_cache';
  static const Duration _cacheExpiration = Duration(hours: 24);

  // Cache de imágenes con CachedNetworkImage
  static Widget getCachedImage({
    required String? imageUrl,
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    // Para imágenes SVG
    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholderBuilder: (context) => placeholder ?? 
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Icon(Icons.image, color: Colors.grey[600]),
            ),
      );
    }

    // Para imágenes normales con cache
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, url) => placeholder ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF013369)),
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          ),
      memCacheWidth: (width ?? 100).toInt(),
      memCacheHeight: (height ?? 100).toInt(),
      maxWidthDiskCache: (width ?? 100).toInt(),
      maxHeightDiskCache: (height ?? 100).toInt(),
    );
  }

  // Cache de datos de quinielas
  static Future<void> cacheQuinielas(List<dynamic> quinielas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': quinielas,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching quinielas: $e');
    }
  }

  static Future<List<dynamic>?> getCachedQuinielas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      
      if (cachedString != null) {
        final cacheData = jsonDecode(cachedString);
        final timestamp = cacheData['timestamp'] as int;
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        // Verificar si el cache no ha expirado
        if (DateTime.now().difference(cachedTime) < _cacheExpiration) {
          return List<dynamic>.from(cacheData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting cached quinielas: $e');
      return null;
    }
  }

  // Cache de equipos
  static Future<void> cacheEquipos(List<dynamic> equipos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': equipos,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('equipos_cache', jsonEncode(cacheData));
    } catch (e) {
      print('Error caching equipos: $e');
    }
  }

  static Future<List<dynamic>?> getCachedEquipos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('equipos_cache');
      
      if (cachedString != null) {
        final cacheData = jsonDecode(cachedString);
        final timestamp = cacheData['timestamp'] as int;
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        // Cache de equipos por más tiempo (1 semana)
        if (DateTime.now().difference(cachedTime) < Duration(days: 7)) {
          return List<dynamic>.from(cacheData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting cached equipos: $e');
      return null;
    }
  }

  // Limpiar cache expirado
  static Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.endsWith('_cache')) {
          final cachedString = prefs.getString(key);
          if (cachedString != null) {
            try {
              final cacheData = jsonDecode(cachedString);
              final timestamp = cacheData['timestamp'] as int;
              final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              
              if (DateTime.now().difference(cachedTime) > _cacheExpiration) {
                await prefs.remove(key);
              }
            } catch (e) {
              // Si hay error al decodificar, eliminar el cache corrupto
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  // Limpiar todo el cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.endsWith('_cache')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  // Preload de imágenes importantes
  static Future<void> preloadImportantImages(BuildContext context, List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        if (url.isNotEmpty) {
          // Preload con CachedNetworkImage
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          );
        }
      }
    } catch (e) {
      print('Error preloading images: $e');
    }
  }
}
