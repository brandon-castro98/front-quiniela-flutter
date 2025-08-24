# Guía de Configuración del Backend Django para Notificaciones Push

## 🔍 **Problema Identificado**

Tu app Flutter SÍ está recibiendo notificaciones, pero **solo cuando TÚ haces cambios**. Esto significa que:

- ✅ Firebase está configurado correctamente
- ✅ Tu backend está enviando notificaciones
- ❌ **Las notificaciones solo van al usuario que hace el cambio**
- ❌ **No hay endpoint para registrar tokens FCM de otros usuarios**

## 🚀 **Solución: Agregar Endpoint para Tokens FCM**

### **1. Crear Modelo para Tokens FCM**

En tu `models.py`, agrega:

```python
from django.db import models
from django.contrib.auth.models import User

class FCMToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='fcm_tokens')
    token = models.CharField(max_length=500, unique=True)
    device_type = models.CharField(max_length=20, default='android')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'fcm_tokens'
        unique_together = ['user', 'token']

    def __str__(self):
        return f"{self.user.username} - {self.device_type}"
```

### **2. Crear Serializer**

En tu `serializers.py`:

```python
from rest_framework import serializers
from .models import FCMToken

class FCMTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = FCMToken
        fields = ['token', 'device_type']
        extra_kwargs = {
            'token': {'required': True},
            'device_type': {'required': False, 'default': 'android'}
        }
```

### **3. Crear View**

En tu `views.py`:

```python
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import FCMToken
from .serializers import FCMTokenSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_fcm_token(request):
    """
    Registra o actualiza el token FCM de un usuario
    """
    try:
        # Obtener o crear el token FCM
        token_data = {
            'token': request.data.get('fcm_token'),
            'device_type': request.data.get('device_type', 'android')
        }
        
        # Verificar si ya existe un token para este usuario
        existing_token = FCMToken.objects.filter(
            user=request.user,
            token=token_data['token']
        ).first()
        
        if existing_token:
            # Actualizar token existente
            serializer = FCMTokenSerializer(existing_token, data=token_data)
        else:
            # Crear nuevo token
            token_data['user'] = request.user.id
            serializer = FCMTokenSerializer(data=token_data)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Token FCM registrado exitosamente',
                'status': 'success'
            }, status=status.HTTP_200_OK)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'error': str(e),
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

### **4. Agregar URL**

En tu `urls.py`:

```python
from django.urls import path
from . import views

urlpatterns = [
    # ... tus URLs existentes ...
    path('fcm-tokens/', views.register_fcm_token, name='register_fcm_token'),
]
```

### **5. Crear Servicio para Enviar Notificaciones**

En tu `services.py` o donde manejes la lógica de negocio:

```python
import requests
from django.conf import settings
from .models import FCMToken

class FCMService:
    FCM_URL = "https://fcm.googleapis.com/fcm/send"
    
    @classmethod
    def send_notification_to_quiniela(cls, quiniela_id, title, body, data=None):
        """
        Envía notificación a todos los usuarios de una quiniela específica
        """
        try:
            # Obtener todos los tokens FCM de usuarios en esta quiniela
            # Esto depende de tu modelo de quinielas
            tokens = cls._get_tokens_for_quiniela(quiniela_id)
            
            if not tokens:
                print(f"No hay tokens FCM para la quiniela {quiniela_id}")
                return False
            
            # Enviar notificación a cada token
            for token in tokens:
                cls._send_to_token(token, title, body, data)
            
            return True
            
        except Exception as e:
            print(f"Error enviando notificación: {e}")
            return False
    
    @classmethod
    def send_notification_to_topic(cls, topic, title, body, data=None):
        """
        Envía notificación a un tema específico
        """
        try:
            payload = {
                "to": f"/topics/{topic}",
                "notification": {
                    "title": title,
                    "body": body
                }
            }
            
            if data:
                payload["data"] = data
            
            headers = {
                "Authorization": f"key={settings.FCM_SERVER_KEY}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(cls.FCM_URL, json=payload, headers=headers)
            
            if response.status_code == 200:
                print(f"Notificación enviada exitosamente al tema {topic}")
                return True
            else:
                print(f"Error enviando notificación: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"Error enviando notificación al tema: {e}")
            return False
    
    @classmethod
    def _send_to_token(cls, token, title, body, data=None):
        """
        Envía notificación a un token específico
        """
        try:
            payload = {
                "to": token,
                "notification": {
                    "title": title,
                    "body": body
                }
            }
            
            if data:
                payload["data"] = data
            
            headers = {
                "Authorization": f"key={settings.FCM_SERVER_KEY}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(cls.FCM_URL, json=payload, headers=headers)
            
            if response.status_code == 200:
                print(f"Notificación enviada exitosamente al token")
                return True
            else:
                print(f"Error enviando notificación: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"Error enviando notificación al token: {e}")
            return False
    
    @classmethod
    def _get_tokens_for_quiniela(cls, quiniela_id):
        """
        Obtiene todos los tokens FCM de usuarios en una quiniela
        Esto depende de tu modelo de quinielas
        """
        # Ejemplo: si tienes un modelo QuinielaUsuario
        # from .models import QuinielaUsuario
        # usuarios_quiniela = QuinielaUsuario.objects.filter(quiniela_id=quiniela_id)
        # user_ids = [uq.user.id for uq in usuarios_quiniela]
        # tokens = FCMToken.objects.filter(user_id__in=user_ids, is_active=True)
        # return [token.token for token in tokens]
        
        # Por ahora, devolver tokens de todos los usuarios activos
        tokens = FCMToken.objects.filter(is_active=True)
        return [token.token for token in tokens]
```

### **6. Modificar tu Vista de Resultados**

En tu vista donde manejas `ingresarResultado`, agrega:

```python
from .services import FCMService

# Después de guardar el resultado exitosamente:
if resultado_guardado:
    # Enviar notificación a todos los usuarios de la quiniela
    FCMService.send_notification_to_quiniela(
        quiniela_id=quiniela_id,
        title="🏈 Nuevo Resultado",
        body=f"Se ha actualizado el resultado de un partido en la quiniela",
        data={
            "type": "resultado_quiniela",
            "quiniela_id": str(quiniela_id),
            "partido_id": str(partido_id),
            "equipo_ganador_id": str(equipo_ganador_id)
        }
    )
```

### **7. Configuración en settings.py**

```python
# Firebase Cloud Messaging
FCM_SERVER_KEY = 'tu_server_key_de_firebase'  # Obtener de Firebase Console
```

## 🔧 **Pasos para Implementar**

1. **Crear el modelo FCMToken** y hacer migraciones
2. **Agregar el endpoint** `/api/fcm-tokens/`
3. **Implementar el servicio FCMService**
4. **Modificar tu vista de resultados** para enviar notificaciones
5. **Probar** desde la app Flutter

## 📱 **Flujo Completo**

1. **Usuario abre la app** → Se obtiene token FCM
2. **Token se envía al servidor** → Se guarda en base de datos
3. **Usuario hace cambio** → Se envía notificación a TODOS los usuarios
4. **Todos reciben notificación** → Incluyendo el usuario que no hizo el cambio

## 🧪 **Para Probar**

1. Ejecuta la app Flutter
2. Ve a la pantalla de debug (`/debug`)
3. Verifica que el token FCM se envíe al servidor
4. Haz un cambio desde otro usuario
5. Verifica que recibas la notificación

¿Necesitas ayuda con algún paso específico de la implementación en Django?
