import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // Aggiunto super.key per best practice

  @override
  LoginPageState createState() => LoginPageState(); // Rinominato per conformità
}

class LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final String server = "https://trainify-server.onrender.com";

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void toggleForms() => setState(() => isLogin = !isLogin);

  Future<void> _authAction() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Inserisci la tua email');
      return;
    }

    if (isLogin) {
      if (_passwordController.text.isEmpty) {
        _showErrorDialog('Inserisci la password');
        return;
      }
      await _handleLogin();
    } else {
      if (_usernameController.text.trim().isEmpty) {
        _showErrorDialog('Inserisci il tuo nome utente');
        return;
      }
      if (_passwordController.text.isEmpty) {
        _showErrorDialog('Inserisci la password');
        return;
      }
      await _handleRegistration();
    }
  }

  Future<void> _handleRegistration() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$server/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password_hash': _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Email inviata. In attesa di verifica...');
        if (mounted) {
          _showVerificationDialog();
        }
      } else {
        final json = jsonDecode(response.body);
        _showErrorDialog(json['error'] ?? 'Errore durante la registrazione');
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerification() async {
    if (_codeController.text.trim().isEmpty) {
      _showErrorDialog('Inserisci il codice di verifica');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$server/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'codice': _codeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Verifica completata. Utente attivato!');
        await _performLoginAfterVerification();
      } else {
        final json = jsonDecode(response.body);
        _showErrorDialog(json['error'] ?? 'Codice di verifica non valido');
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performLoginAfterVerification() async {
    try {
      final response = await http.post(
        Uri.parse('$server/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password_hash': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Login effettuato con token: ${data['token']}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'token': data['token']},
          );
        }
      } else {
        final json = jsonDecode(response.body);
        _showErrorDialog(json['error'] ?? 'Errore durante il login');
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione durante il login');
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$server/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Login effettuato con token: ${data['token']}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'token': data['token']},
          );
        }
      } else {
        final json = jsonDecode(response.body);
        _showErrorDialog(json['error'] ?? 'Errore durante il login');
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D22),
        title: const Text('Errore', style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.8)), // Usato Color.fromRGBO
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF2D55))),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    _codeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D22),
        title: const Text(
          'Verifica Email',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inserisci il codice di verifica inviato a ${_emailController.text.trim()}',
              style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.8)), // Usato Color.fromRGBO
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Codice',
                labelStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.7)), // Usato Color.fromRGBO
                filled: true,
                fillColor: const Color.fromRGBO(10, 14, 17, 0.5), // Usato Color.fromRGBO per 0xFF0A0E11
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => isLogin = true);
            },
          ),
          TextButton(
            child: Text(
              _isLoading ? 'Verifica...' : 'Verifica',
              style: const TextStyle(color: Color(0xFFFF2D55)),
            ),
            onPressed: _isLoading ? null : () async {
              await _handleVerification();
              if (mounted) Navigator.pop(ctx);
            },
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
                  style: const TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),

                // Auth Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D22),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.3), // Usato Color.fromRGBO
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
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
                            curve: Curves.easeInOut,
                            child: Container(
                              width: MediaQuery.of(context).size.width / 2 - 48,
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
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      color: isLogin
                                          ? Colors.white
                                          : const Color.fromRGBO(255, 255, 255, 0.6), // Usato Color.fromRGBO
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: !isLogin ? null : toggleForms,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      color: !isLogin
                                          ? Colors.white
                                          : const Color.fromRGBO(255, 255, 255, 0.6), // Usato Color.fromRGBO
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

                      // Username Field (solo per registrazione)
                      if (!isLogin)
                        Column(
                          children: [
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Nome utente',
                                labelStyle: const TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                                ),
                                filled: true,
                                fillColor: const Color.fromRGBO(10, 14, 17, 0.5), // Usato Color.fromRGBO per 0xFF0A0E11
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
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

                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(10, 14, 17, 0.5), // Usato Color.fromRGBO per 0xFF0A0E11
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(10, 14, 17, 0.5), // Usato Color.fromRGBO per 0xFF0A0E11
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),

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
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin ? 'ACCEDI' : 'REGISTRATI',
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
                      _showErrorDialog('Funzione di recupero password non implementata');
                    },
                    child: Text(
                      'Password dimenticata?',
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.7), // Usato Color.fromRGBO
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