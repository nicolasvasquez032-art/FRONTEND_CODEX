import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'http://18.191.162.235:8000';

void main() async {
  print('==================================================');
  print('🚀 INICIANDO PRUEBA END-TO-END (AWS EC2)');
  print('==================================================\n');

  final String testEmail = 'candidato_e2e_${DateTime.now().millisecondsSinceEpoch}@test.com';
  const String testPassword = 'Password123!';
  String token = '';

  try {
    // 1. HEALTH CHECK
    print('1️⃣  Verificando conexión con el servidor Amazon EC2...');
    final healthRes = await http.get(Uri.parse(kBaseUrl + '/health')).timeout(const Duration(seconds: 10));
    if (healthRes.statusCode != 200) throw Exception('Servidor caído');
    print('✅ Servidor EC2 Respondiendo OK: ' + healthRes.body + '\n');

    // 2. REGISTRO (SIGN UP)
    print('2️⃣  Registrando nuevo usuario (Candidato)...');
    final regRes = await http.post(
      Uri.parse(kBaseUrl + '/auth/registro/candidato'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': testEmail,
        'password': testPassword,
        'full_name': 'Juan Perez Test',
        'skills': ['Dart', 'Flutter'],
        'experience_years': 2,
        'location': 'Bogota',
        'education': 'Ingeniero',
      }),
    );
    if (regRes.statusCode == 201 || regRes.statusCode == 200) {
      print('✅ Usuario creado exitosamente: ' + testEmail + '\n');
    } else {
      throw Exception('Fallo en el registro: ' + regRes.body);
    }

    // 3. LOGIN (TOKEN JWT)
    print('3️⃣  Iniciando sesión y solicitando Token JWT...');
    final loginRes = await http.post(
      Uri.parse(kBaseUrl + '/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': testEmail,
        'password': testPassword,
      }),
    );
    
    if (loginRes.statusCode == 200) {
      final data = jsonDecode(loginRes.body);
      token = data['access_token'];
      print('✅ Token JWT recibido correctamente: ' + token.substring(0, 15) + '...\n');
    } else {
      throw Exception('Fallo en el login: ' + loginRes.body);
    }

    // 4. PETICIÓN AUTENTICADA (GET VACANTES)
    print('4️⃣  Realizando petición privada (Leyendo vacantes)...');
    final vacantesRes = await http.get(
      Uri.parse(kBaseUrl + '/vacantes/'),
      headers: {
        'Authorization': 'Bearer ' + token,
      },
    );
    
    if (vacantesRes.statusCode == 200) {
      final List vacantes = jsonDecode(vacantesRes.body);
      print('✅ Acceso autorizado. Se leyeron ' + vacantes.length.toString() + ' vacantes de la base de datos.\n');
    } else {
      throw Exception('Fallo al leer vacantes: ' + vacantesRes.body);
    }

    print('==================================================');
    print('🎉 ¡TODAS LAS PRUEBAS END-TO-END PASARON CON ÉXITO! 🎉');
    print('Tu Frontend y tu Backend están perfectamente conectados.');
    print('==================================================');

  } catch (e) {
    print('❌ ERROR CRÍTICO EN LA PRUEBA: ' + e.toString());
  }
}
