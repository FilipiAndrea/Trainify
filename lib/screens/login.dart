import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String server = "https://trainify-server.onrender.com";

  void toggleForms() => setState(() => isLogin = !isLogin);

  Future<void> _authAction() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Inserisci la tua email');
      return;
    }

    // Se siamo in registrazione, richiedi solo l'email
    if (!isLogin) {
      _handleEmailRegistration();
      return;
    }

    // Altrimenti procedi con il login normale
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Inserisci la password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$server/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Risposta del server: $data');
        print('Navigating to Home con token: ${data['token']} e userId: ${data['userId']}');
        // Salva il token nel SharedPreferences
        final prefs = await SharedPreferences.getInstance();
      
        // Salva il token
        await prefs.setString('jwt_token', data['token']);

        // Vai alla home, dove chiederai i dati utente
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'token': data['token'],
          },
        );

      } else {
        _showErrorDialog(
          jsonDecode(response.body)['error'] ?? 'Errore sconosciuto',
        );
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailRegistration() async {
    setState(() => _isLoading = true);

    try {
      // Simulazione invio email (sostituisci con la tua API reale)
      await Future.delayed(const Duration(seconds: 2));

      _showSuccessDialog(
        'Abbiamo inviato un link di registrazione alla tua email!\n'
        'Controlla la tua casella di posta per completare la registrazione.',
      );
    } catch (e) {
      _showErrorDialog('Errore durante l\'invio dell\'email');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D22),
            title: const Text('Errore', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFFF2D55)),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D22),
            title: const Text(
              'Successo',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              message,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFFF2D55)),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                const SizedBox(height: 20),
                const Text(
                  'Trainify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Simplifies your way of training',
                  style: TextStyle(
                    color: Color(0xFFFF2D55),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isLogin ? 'Accedi al tuo account' : 'Crea un nuovo account',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),

                const SizedBox(height: 30),

                // Auth Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D22),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Toggle Buttons
                      Stack(
                        children: [
                          // Animated background
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            alignment:
                                isLogin
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                            curve: Curves.easeInOut,
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width / 2 -
                                  48, // Calcolato tenendo conto del padding esterno
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF2D55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isLogin ? null : toggleForms,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color:
                                          isLogin
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: !isLogin ? null : toggleForms,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    'Registrati',
                                    style: TextStyle(
                                      color:
                                          !isLogin
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Email Field (sempre visibile)
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E11).withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // Password Field (solo per login)
                      if (isLogin)
                        Column(
                          children: [
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                filled: true,
                                fillColor: const Color(
                                  0xFF0A0E11,
                                ).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2D55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    isLogin ? 'ACCEDI' : 'INVIA EMAIL',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                const SizedBox(height: 40),
                if (isLogin)
                  TextButton(
                    onPressed: () {
                      // Password dimenticata
                    },
                    child: Text(
                      'Password dimenticata?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
