import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String serverUrl = 'https://trainify-server.onrender.com';

  /// Verifica se il token esiste e se è valido tramite il server
  static Future<bool> isLoggedIn() async {
    print("controllo se dover fare il login...");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print("token: $token");

    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/verifyToken'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Errore durante la verifica del token: $e');
      return false;
    }
  }
}
