# Guía de Conexión: Depuración USB (Celular Físico)

Para probar la aplicación TalentMatch directamente en un celular físico (Android) y que se pueda comunicar correctamente con el backend local de la computadora, sigue los pasos a continuación.

## 1. Activar las Opciones de Desarrollador en el Celular
1. Ve a los **Ajustes** o **Configuración** de tu celular.
2. Desplázate hasta abajo y entra en **Acerca del teléfono** (o Información del teléfono).
3. Busca **Número de compilación** (a veces dentro de "Información de software").
4. **Toca 7 veces seguidas** sobre "Número de compilación" hasta que aparezca el mensaje "¡Ya eres un desarrollador!".

## 2. Activar la Depuración USB
1. Regresa al menú principal de Ajustes.
2. Entra al nuevo menú llamado **Opciones de desarrollador** (suele estar al final o dentro de "Sistema").
3. Busca la opción **Depuración USB** y actívala.

## 3. Conectar el celular a la Computadora
1. Conecta tu celular a la PC usando un cable USB.
2. En la pantalla del celular aparecerá un aviso preguntando: **"¿Permitir depuración por USB?"**. 
3. Marca la casilla "Permitir siempre desde esta computadora" y dale a **Aceptar**.
4. *(Opcional)*: Para verificar que la PC reconoce tu dispositivo, puedes correr en tu terminal de la PC:
   ```bash
   flutter devices
   ```

## 4. Configurar la Conexión al Backend (IP Local)
Dado que el celular y la PC son dispositivos distintos, no puedes usar `localhost` ni `127.0.0.1`. Debes usar la IP real de tu PC.

1. Asegúrate de que **ambos dispositivos estén conectados a la misma red Wi-Fi**.
2. Averigua la IP local de tu PC ejecutando en la terminal:
   ```bash
   hostname -I
   ```
   *(Ejemplo: 172.18.5.8 o 192.168.1.5)*
3. Ve al archivo `lib/core/network/api_client.dart` en el proyecto de Flutter.
4. Actualiza la variable `kBaseUrl` con esa IP:
   ```dart
   const String kBaseUrl = 'http://TU_IP_LOCAL:8000'; 
   // Ejemplo: const String kBaseUrl = 'http://172.18.5.8:8000';
   ```

## 5. Ejecutar la Aplicación
1. En la terminal de la computadora (dentro de la carpeta del frontend), detén cualquier proceso previo (presionando `q`).
2. Ejecuta el comando:
   ```bash
   flutter run
   ```
3. Si la terminal te da varias opciones (Chrome, Linux, tu teléfono), escribe el **número** que corresponde a tu celular.
4. Espera a que termine de compilar. La aplicación se abrirá sola en tu celular y ¡tendrá acceso a internet y al backend!
