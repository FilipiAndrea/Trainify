import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainify/screens/today_workout_page.dart';
import 'package:trainify/utils/quote_manager.dart';

// Funzione per recuperare i dati dell'utente tramite API
Future<Map<String, dynamic>> fetchUserData(String token) async {
  print(token);
  final response = await http.get(
    Uri.parse('https://trainify-server.onrender.com/user'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    print("letsgosky");
    return json.decode(response.body); // Restituisci i dati dell'utente
  } else {
    print('Errore nel recupero dei dati: ${response.statusCode}');
    throw Exception('Failed to load user data');
  }
}

Future<void> saveUserDataLocally(Map<String, dynamic> userData) async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = json.encode(userData);
  await prefs.setString('user_data', userJson);
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
  }

  Future<Map<String, dynamic>?> _getSelectedWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('https://trainify-server.onrender.com/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print("Allenamenti recuperati con successo");
      final data = json.decode(response.body);
      final workouts = List<Map<String, dynamic>>.from(data['allenamenti_salvati'] ?? []);
      final selected = workouts.where((w) => w['selected'] == true).toList();
      return selected.isNotEmpty ? selected.first : null;
    }
    return null;
  }


  // Carica i dati dell'utente
  /*Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      setState(() {
        _userData = fetchUserData(token);
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }*/

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      // Prova a caricare da SharedPreferences
      final localData = await loadUserDataFromPrefs();
      if (localData != null) {
        setState(() {
          _userData = Future.value(localData);
        });
      } else {
        // Se non trovato localmente, fetch remoto
        final fetchedData = await fetchUserData(token);
        await saveUserDataLocally(fetchedData);
        setState(() {
          _userData = Future.value(fetchedData);
        });
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }


  Future<Map<String, dynamic>?> loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

   Future<Map<String, dynamic>> fetchQuote() async {
    // Prima controlla se ne abbiamo una salvata
    final savedQuote = await QuoteManager.getSavedQuote();
    if (savedQuote != null) {
      return savedQuote;
    }

    // Altrimenti fetcha una nuova
    final response = await http.get(
      Uri.parse('https://zenquotes.io/api/today'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final quote = {'quote': data[0]['q'], 'author': data[0]['a']};
      
      // Salva la nuova citazione
      await QuoteManager.saveQuote(quote['quote'], quote['author']);
      
      return quote;
    } else {
      throw Exception('Failed to load quote');
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E11),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: _userData, // La futura chiamata che recupera i dati dell'utente
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostra un caricamento durante la richiesta
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Gestisci eventuali errori
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(child: Text('Errore nel recupero dei dati')),
          );
        } else if (snapshot.hasData) {
          // Recupera i dati dell'utente dalla risposta
          final user = snapshot.data!;
          final nomeUtente = user['nome']?.split(' ').first ?? 'Atleta';
          final streakCount = user['stk_settimanale'] ?? 5;

          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A1D22).withOpacity(0.8),
                        const Color(0xFF0A0E11).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome and streak counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bentornato,',
                                style: TextStyle(
                                  fontFamily: 'NewYork',
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nomeUtente,
                                style: const TextStyle(
                                  fontFamily: 'NewYork',
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Streak counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2D55), Color(0xFFFF5C35)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF2D55,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$streakCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Today's workout card
                      
                      // Dentro il Column che contiene gli elementi dell'header (dopo la Today's workout card)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Allenamento di oggi',
                                    style: TextStyle(
                                      fontFamily: 'NewYork',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Completa il tuo workout per mantenere la streak!',
                                    style: TextStyle(
                                      fontFamily: 'NewYork',
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.fitness_center,
                              color: Color(0xFFFF2D55),
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12), // Spacing tra le card
                      // Motivational quote card
                      FutureBuilder<Map<String, dynamic>>(
                        future: fetchQuote(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D22).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF2D55),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D22).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Impossibile caricare la citazione',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          } else {
                            final quote = snapshot.data!;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '"${quote['quote']}"',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '- ${quote['author']}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.format_quote,
                                    color: Color(0xFFFF2D55),
                                    size: 32,
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      
                      // Your other widgets here...
                    ],
                  ),
                ),
                // Main buttons section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Primo pulsante con gradient e shadow
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF2D55).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: WorkoutButton(
                            title: "ALLENATI OGGI",
                            subtitle: "Inizia il workout programmato",
                            icon: Icons.play_arrow_rounded,
                            color: Colors.transparent,
                            textColor: Colors.white,
                            onPressed: () async {
                              final selectedWorkout = await _getSelectedWorkout();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TodayWorkoutPage(selectedWorkout: selectedWorkout),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Secondo pulsante con bordo e trasparenza
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFF2D55),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF2D55).withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: WorkoutButton(
                            title: "FREESTYLE",
                            subtitle: "Crea il tuo allenamento",
                            icon: Icons.tune,
                            color: Colors.transparent,
                            borderColor: Colors.transparent, // Il bordo è gestito dal Container
                            textColor: Colors.white,
                            onPressed: () {
                              // Navigator.push per freestyle
                              Navigator.pushNamed(
                                context,
                                '/freestyleWorkout',
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Terzo pulsante per selezione allenamento
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF2D55).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: WorkoutButton(
                            title: "SELEZIONA ALLENAMENTO",
                            subtitle: "Scegli il tuo workout preferito",
                            icon: Icons.fitness_center,
                            color: Colors.transparent,
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/workoutSelection',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomBottomNavBar(
                  currentIndex:
                      1, // Imposta a 1 per evidenziare il bottone centrale
                  onItemSelected: (index) {
                    if (index == 0) {
                      // Bottone Crea - Apri la pagina per creare un nuovo allenamento
                      Navigator.pushNamed(
                        context,
                        '/allenamento',
                        arguments: {'user': user},
                      );
                    } else if (index == 1) {
                      // Bottone Workout - Se siamo già nella home, non fare nulla
                      if (ModalRoute.of(context)?.settings.name != '/home') {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                          arguments: {'user': user},
                        );
                      }
                    } else if (index == 2) {
                      // Bottone Profilo
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: {'user': user},
                      );
                    }
                  },
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(child: Text('Nessun dato trovato')),
          );
        }
      },
    );
  }
}

// Workout Button Component
class WorkoutButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  const WorkoutButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.borderColor = Colors.transparent,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: color,
      elevation: color == Colors.transparent ? 0 : 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      color == Colors.transparent
                          ? const Color(0xFFFF2D55).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textColor.withOpacity(0.7),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1215), // Sfondo più scuro
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            icon: Icons.add,
            label: 'Crea',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.fitness_center,
            label: 'Workout',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profilo',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive
                ? const Color(0xFFFF2D55)
                : Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFFFF2D55)
                  : Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (isActive)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}