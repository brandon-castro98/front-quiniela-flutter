import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Pon aquí tu URL de ngrok (actualízala cuando ngrok cambie)
  static const String baseUrl = 'https://api-quiniela-phiv.onrender.com';
  // LOGIN -> usa /api/login/
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/'), // <- CORRECCIÓN AQUÍ
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', data['access']);
      await prefs.setString('refresh', data['refresh']);
      await prefs.setString('username', username); // <-- Agrega esto

      final parts = data['access'].split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final payloadMap = jsonDecode(payload);
        if (payloadMap is Map && payloadMap.containsKey('exp')) {
          await prefs.setInt('access_exp', payloadMap['exp']);
        }
      }
      return true;
    }
    return false;
  }

  static Future<List<dynamic>> getPartidos(int quinielaId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/partidos/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error al obtener partidos: $e');
      return [];
    }
  }

  // Refrescar access token usando el refresh token
  static Future<bool> refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh') ?? '';
    if (refresh.isEmpty) return false;

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        await prefs.setString('access', d['access']);
        // Si el backend también regresa un nuevo refresh, actualízalo:
        if (d.containsKey('refresh')) {
          await prefs.setString('refresh', d['refresh']);
        }
        // Actualiza el tiempo de expiración
        final parts = d['access'].split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final payloadMap = jsonDecode(payload);
          if (payloadMap is Map && payloadMap.containsKey('exp')) {
            await prefs.setInt('access_exp', payloadMap['exp']);
          }
        }
        return true;
      } else if (resp.statusCode == 401) {
        // Solo si el refresh es inválido, cierra sesión
        await prefs.remove('access');
        await prefs.remove('refresh');
        return false;
      } else {
        // Si es un error temporal, no borres los tokens
        return false;
      }
    } catch (e) {
      print('Error al refrescar token: $e');
      return false;
    }
  }

  // Helper que devuelve headers con Authorization si existe token
  static Future<Map<String, String>> getAuthHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access') ?? '';
    final headers = {'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<List<dynamic>> getEquipos() async {
    final response = await http.get(Uri.parse('$baseUrl/api/equipos/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Obtener quinielas con retry si el access expiró
  static Future<List<dynamic>> getQuinielas() async {
    try {
      Map<String, String> headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/quinielas/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Intentar refrescar token y reintentar una vez
        final refreshed = await refreshToken();
        if (refreshed) {
          headers = await getAuthHeaders();
          final retry = await http.get(
            Uri.parse('$baseUrl/api/quinielas/'),
            headers: headers,
          );
          if (retry.statusCode == 200) return jsonDecode(retry.body);
        }
      }
      // Si falla, devolver lista vacía (o lanzar excepción según prefieras)
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> unirseQuiniela(int quinielaId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access');

      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/unirse/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error al unirse a la quiniela: $e");
      return false;
    }
  }

  static Future<bool> setMostrarElecciones(int quinielaId, bool mostrar) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/mostrar-elecciones/'),
        headers: headers,
        body: jsonEncode({'mostrar_elecciones': mostrar}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al cambiar mostrar_elecciones: $e');
      return false;
    }
  }

  static Future<bool> registrarUsuario(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      print('Registro usuario status: ${response.statusCode}');
      print('Registro usuario body: ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return false;
    }
  }

  static Future<bool> agregarQuiniela(String nombre, double apuesta) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access');

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/quinielas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nombre': nombre, 'apuesta_individual': apuesta}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error al agregar quiniela: $e");
      return false;
    }
  }

  static Future<bool> eliminarQuiniela(int quinielaId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error al eliminar quiniela: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getQuinielaDetalle(
    int quinielaId,
  ) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error al obtener detalle de quiniela: $e');
      return null;
    }
  }

  static Future<bool> agregarPartido(
    int quinielaId,
    int localId,
    int visitanteId,
    DateTime fecha,
  ) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/partidos/'),
        headers: headers,
        body: jsonEncode({
          'equipo_local_id': localId,
          'equipo_visitante_id': visitanteId,
          'fecha': fecha.toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('No tienes permisos para agregar partido: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getElecciones(int quinielaId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/elecciones/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error al obtener elecciones: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getRanking(int quinielaId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/quinielas/$quinielaId/ranking/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error al obtener ranking: $e');
      return [];
    }
  }

  static Future<bool> ingresarResultado(
    int quinielaId,
    int partidoId,
    int equipoGanadorId,
  ) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/quinielas/$quinielaId/partidos/$partidoId/resultado/',
        ),
        headers: headers,
        body: jsonEncode({'resultado_equipo_id': equipoGanadorId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al ingresar resultado: $e');
      return false;
    }
  }

  static Future<bool> elegirEquipo(
    int quinielaId,
    List<Map<String, dynamic>> elecciones,
  ) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/elecciones/'),
        headers: headers,
        body: jsonEncode({'quiniela_id': quinielaId, 'elecciones': elecciones}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al elegir equipo: $e');
      return false;
    }
  }

  // Cerrar sesión
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access');
    await prefs.remove('refresh');
    await prefs.remove('username');
    await prefs.remove('access_exp');
  }

  // Enviar token FCM al servidor
  static Future<bool> sendFcmToken(String fcmToken) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/fcm-tokens/'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken, 'device_type': 'android'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token FCM enviado exitosamente al servidor');
        return true;
      } else {
        print(
          'Error enviando token FCM: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error enviando token FCM al servidor: $e');
      return false;
    }
  }

  // Obtener usuario actual
  static Future<String?> getCurrentUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}
