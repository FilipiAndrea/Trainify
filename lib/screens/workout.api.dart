import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutApi {
  static const String baseUrl = 'https://trainify-server.onrender.com/api';

  // Funzione aggiornata per salvare l'allenamento SENZA userId nel body
  static Future<bool> saveWorkout(Map<String, dynamic> workoutJson) async {
    final url = Uri.parse('$baseUrl/allenamenti_salvati');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      print('❌ Token mancante');
      return false;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(workoutJson),
      );

      if (response.statusCode == 201) {
        print('✅ Allenamento salvato correttamente');
        return true;
      } else {
        print('❌ Errore salvataggio workout: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Eccezione salvataggio workout: $e');
      return false;
    }
  }
}
