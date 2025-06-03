/*import 'package:flutter/material.dart';
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
    return json.decode(response.body);
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Future<Map<String, dynamic>>? _userData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      final localData = await loadUserDataFromPrefs();
      if (localData != null) {
        setState(() {
          _userData = Future.value(localData);
        });
      } else {
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
    final savedQuote = await QuoteManager.getSavedQuote();
    if (savedQuote != null) {
      return savedQuote;
    }

    final response = await http.get(
      Uri.parse('https://zenquotes.io/api/today'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final quote = {'quote': data[0]['q'], 'author': data[0]['a']};
      
      await QuoteManager.saveQuote(quote['quote'], quote['author']);
      
      return quote;
    } else {
      throw Exception('Failed to load quote');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E11),
        body: Center(child: CircularProgressIndicator(
          color: Color(0xFFFF2D55),
        )),
      );
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(child: CircularProgressIndicator(
              color: Color(0xFFFF2D55),
            )),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(
              child: Text(
                'Errore nel recupero dei dati',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          final nomeUtente = user['nome']?.split(' ').first ?? 'Atleta';
          final streakCount = user['stk_settimanale'] ?? 5;

          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: CustomScrollView(
              slivers: [
                // Modern Header
                _buildModernHeader(nomeUtente, streakCount),
                
                // Cards Section
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildTodayWorkoutCard(),
                            const SizedBox(height: 16),
                            _buildQuoteCard(),
                            const SizedBox(height: 32),
                            _buildActionButtons(user),
                            const SizedBox(height: 100), // Space for bottom nav
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 1,
              onItemSelected: (index) => _handleNavigation(index, user),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E11),
            body: Center(
              child: Text(
                'Nessun dato trovato',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      },
    );
  }

  void _handleNavigation(int index, Map<String, dynamic> user) {
    if (index == 0) {
      Navigator.pushNamed(
        context,
        '/allenamento',
        arguments: {'user': user},
      );
    } else if (index == 1) {
      if (ModalRoute.of(context)?.settings.name != '/home') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'user': user},
        );
      }
    } else if (index == 2) {
      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {'user': user},
      );
    }
  }
}
// Continuazione della classe _HomePageState - Metodi per i widget

  Widget _buildModernHeader(String nomeUtente, int streakCount) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1D22),
              Color(0xFF0A0E11).withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bentornato,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      nomeUtente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStreakCounter(streakCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCounter(int streakCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D55).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streakCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1D22),
            Color(0xFF252932),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF2D55).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allenamento di oggi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completa il tuo workout per mantenere la streak!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchQuote(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1D22).withOpacity(0.5),
                  Color(0xFF252932).withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF2D55),
                strokeWidth: 2,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1D22).withOpacity(0.5),
                  Color(0xFF252932).withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF2D55),
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Impossibile caricare la citazione',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          final quote = snapshot.data!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1D22),
                  Color(0xFF252932),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.format_quote,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${quote['quote']}"',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '— ${quote['author']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> user) {
    return Column(
      children: [
        // Primary Button - Allenati Oggi
        _buildPrimaryButton(
          title: "ALLENATI OGGI",
          subtitle: "Inizia il workout programmato",
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TodayWorkoutPage(user: user),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Secondary Button - Freestyle
        _buildSecondaryButton(
          title: "FREESTYLE",
          subtitle: "Crea il tuo allenamento",
          icon: Icons.tune,
          onPressed: () {
            // Navigator.push per freestyle
          },
        ),
        
        const SizedBox(height: 20),
        
        // Primary Button - Seleziona Allenamento
        _buildPrimaryButton(
          title: "SELEZIONA ALLENAMENTO",
          subtitle: "Scegli il tuo workout preferito",
          icon: Icons.fitness_center,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/workoutSelection',
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF2D55).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF2D55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF2D55).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF2D55).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Color(0xFFFF2D55), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// CustomBottomNavBar Component - Versione migliorata

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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1D22),
            Color(0xFF0E1215),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFFFF2D55).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              label: 'Crea',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.fitness_center_outlined,
              activeIcon: Icons.fitness_center,
              label: 'Workout',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profilo',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Color(0xFFFF2D55).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.6),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Alternative Minimal Bottom Navigation Bar
class MinimalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const MinimalBottomNavBar({
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: Color(0xFF1A1D22).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMinimalNavItem(
            icon: Icons.add,
            index: 0,
          ),
          _buildMinimalNavItem(
            icon: Icons.fitness_center,
            index: 1,
          ),
          _buildMinimalNavItem(
            icon: Icons.person,
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalNavItem({
    required IconData icon,
    required int index,
  }) {
    final bool isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF2D55).withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}*/