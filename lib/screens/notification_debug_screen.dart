import 'package:flutter/material.dart';
import '../services/notification_debug_service.dart';
import '../services/notification_service.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  Map<String, dynamic> _diagnosis = {};
  bool _isLoading = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diagnosis = await NotificationDebugService.diagnoseNotifications();
      setState(() {
        _diagnosis = diagnosis;
        _fcmToken = diagnosis['fcm_token'];
      });

      // Imprimir diagnóstico en consola
      NotificationDebugService.printDiagnosis(diagnosis);
    } catch (e) {
      print('Error en diagnóstico: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      await NotificationService.showResultNotification(
        quinielaName: 'Test Quiniela',
        equipoGanador: 'Patriots',
        equipoPerdedor: 'Jets',
        quinielaId: 999,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación local enviada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendTokenToServer() async {
    if (_fcmToken != null) {
      final success = await NotificationDebugService.sendTokenToServer(
        _fcmToken!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Token enviado al servidor' : 'Error enviando token',
          ),
        ),
      );
    }
  }

  Future<void> _subscribeToTestTopics() async {
    try {
      await NotificationDebugService.subscribeToTestTopics();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suscrito a temas de prueba')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug de Notificaciones'),
        backgroundColor: const Color(0xFF013369),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _runDiagnosis),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones de prueba
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pruebas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _testLocalNotification,
                                  child: const Text(
                                    'Probar Notificación Local',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _sendTokenToServer,
                                  child: const Text('Enviar Token al Servidor'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _subscribeToTestTopics,
                              child: const Text(
                                'Suscribirse a Temas de Prueba',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información del diagnóstico
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnóstico',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDiagnosisItem(
                            'Firebase inicializado',
                            _diagnosis['firebase_initialized'],
                          ),
                          _buildDiagnosisItem(
                            'Token FCM',
                            _diagnosis['fcm_token'] != null
                                ? '${_diagnosis['fcm_token'].toString().substring(0, 20)}...'
                                : 'No disponible',
                          ),
                          _buildDiagnosisItem(
                            'Longitud del token',
                            _diagnosis['fcm_token_length'],
                          ),
                          _buildDiagnosisItem(
                            'Estado de permisos',
                            _diagnosis['permission_status'],
                          ),
                          _buildDiagnosisItem(
                            'Alertas habilitadas',
                            _diagnosis['alert_enabled'],
                          ),
                          _buildDiagnosisItem(
                            'Badges habilitados',
                            _diagnosis['badge_enabled'],
                          ),
                          _buildDiagnosisItem(
                            'Sonidos habilitados',
                            _diagnosis['sound_enabled'],
                          ),
                          _buildDiagnosisItem(
                            'Package name',
                            _diagnosis['package_name'],
                          ),
                          _buildDiagnosisItem('App ID', _diagnosis['app_id']),
                          _buildDiagnosisItem(
                            'Token enviado al servidor',
                            _diagnosis['token_sent_to_server'],
                          ),
                          _buildDiagnosisItem(
                            'Min SDK',
                            _diagnosis['android_min_sdk'],
                          ),
                          _buildDiagnosisItem(
                            'Notificaciones locales',
                            _diagnosis['local_notifications_working'],
                          ),

                          if (_diagnosis.containsKey('error')) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Error detectado:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _diagnosis['error'].toString(),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información del token FCM
                  if (_fcmToken != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Token FCM Completo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: SelectableText(
                                _fcmToken!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Este token debe enviarse a tu servidor para poder recibir notificaciones push.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDiagnosisItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'No disponible',
              style: TextStyle(
                color: value != null
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
