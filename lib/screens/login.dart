import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Compila tutti i campi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = isLogin ? 'login' : 'register';
      final response = await http.post(
        Uri.parse('$server/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (isLogin) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'user': data['user']},
          );
        } else {
          _showSuccessDialog('Registrazione completata!');
          toggleForms();
        }
      } else {
        _showErrorDialog(jsonDecode(response.body)['message'] ?? 'Errore sconosciuto');
      }
    } catch (e) {
      _showErrorDialog('Errore di connessione');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D22),
        title: const Text('Errore', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF2D55))),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D22),
        title: const Text('Successo', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF2D55))),
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
                const SizedBox(height: 10),
                Text(
                  isLogin ? 'Accedi al tuo account' : 'Crea un nuovo account',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

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
                                backgroundColor: isLogin ? const Color(0xFFFF2D55) : Colors.transparent,
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: isLogin ? Colors.white : Colors.white.withOpacity(0.6),
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
                                backgroundColor: !isLogin ? const Color(0xFFFF2D55) : Colors.transparent,
                              ),
                              child: Text(
                                'Registrati',
                                style: TextStyle(
                                  color: !isLogin ? Colors.white : Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: const Color(0xFF0A0E11).withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.white.withOpacity(0.7)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: const Color(0xFF0A0E11).withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.7)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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