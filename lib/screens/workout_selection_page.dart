import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'today_workout_page.dart';

class WorkoutSelectionPage extends StatefulWidget {
  const WorkoutSelectionPage({Key? key}) : super(key: key);

  @override
  _WorkoutSelectionPageState createState() => _WorkoutSelectionPageState();
}

class _WorkoutSelectionPageState extends State<WorkoutSelectionPage> with TickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? _workoutsFuture;
  String? _selectedWorkoutId;
  bool _isSelecting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final Map<String, bool> _expandedCards = {};

  static const String _baseUrl = 'https://trainify-server.onrender.com';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadWorkouts();
    _animationController.forward();
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _navigateToLogin();
        return;
      }

      setState(() {
        _workoutsFuture = _fetchUserWorkouts(token);
        print("ok ecco l'allenamento attivo: $_selectedWorkoutId");
      });
    } catch (e) {
      setState(() {
        _workoutsFuture = Future.error(e);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserWorkouts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('=== RAW RESPONSE FROM SERVER ===');
        print(json.encode(data));

        final workouts = List<Map<String, dynamic>>.from(data['allenamenti_salvati'] ?? []);
        print('=== FETCHED ${workouts.length} WORKOUTS ===');

        final selected = workouts.where((w) => w['selected'] == true).toList();
        if (selected.isNotEmpty && selected.first['id_workout'] != null) {
          _selectedWorkoutId = selected.first['id_workout'].toString();
          print('Selected workout ID: $_selectedWorkoutId');
        }

        return workouts;
      } else if (response.statusCode == 404) {
        throw Exception('Utente non trovato');
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user workouts: $e');
      throw Exception('Error fetching workouts: $e');
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _navigateToLogin();
        return;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/workouts/$workoutId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Workout deleted: $workoutId');
        setState(() {
          _workoutsFuture = _workoutsFuture?.then((workouts) => workouts
              .where((w) => w['id_workout'] != workoutId)
              .map((w) => _normalizeWorkout(w))
              .toList());
          if (_selectedWorkoutId == workoutId) {
            _selectedWorkoutId = null;
          }
        });
        _showSuccessSnackbar('Allenamento eliminato con successo');
      } else {
        print('Failed to delete workout: $workoutId, status: ${response.statusCode}');
        _showErrorSnackbar('Errore durante l\'eliminazione dell\'allenamento');
      }
    } catch (e) {
      print('Error deleting workout: $e');
      _showErrorSnackbar('Errore: ${e.toString()}');
    }
  }

  Map<String, dynamic> _normalizeWorkout(Map<String, dynamic> workout) {
    final normalized = Map<String, dynamic>.from(workout);

    normalized['id_workout'] = normalized['id_workout']?.toString() ?? '';
    normalized['titolo'] = normalized['titolo'] ?? 'Allenamento senza nome';
    normalized['descrizione'] = normalized['descrizione'] ?? 'Nessuna descrizione';
    normalized['creato_da_ai'] = normalized['creato_da_ai'] is bool
        ? normalized['creato_da_ai']
        : (normalized['creato_da_ai']?.toString().toLowerCase() == 'true' ||
            normalized['creato_da_ai'] == 1);
    normalized['selected'] = normalized['selected'] is bool
        ? normalized['selected']
        : (normalized['selected']?.toString().toLowerCase() == 'true' ||
            normalized['selected'] == 1);
    normalized['settimana'] = normalized['settimana'] is List
        ? normalized['settimana']
        : [];

    normalized['settimana'] = (normalized['settimana'] as List).asMap().entries.map((entry) {
      final index = entry.key;
      final day = Map<String, dynamic>.from(entry.value);
      day['giorno'] = day['giorno'] ?? 'Giorno ${index + 1}';
      day['gruppi_muscolari'] = day['gruppi_muscolari'] is List ? day['gruppi_muscolari'] : [];
      day['esercizi'] = day['esercizi'] is List
          ? (day['esercizi'] as List).map((e) {
              final exercise = Map<String, dynamic>.from(e);
              exercise['id_esercizio'] = exercise['id_esercizio']?.toString() ?? '';
              exercise['serie'] = exercise['serie'] is int
                  ? exercise['serie']
                  : (int.tryParse(exercise['serie']?.toString() ?? '0') ?? 0);
              exercise['ripetizioni'] = exercise['ripetizioni'] is int
                  ? exercise['ripetizioni']
                  : (int.tryParse(exercise['ripetizioni']?.toString() ?? '0') ?? 0);
              exercise['riposo_sec'] = exercise['riposo_sec'] is int
                  ? exercise['riposo_sec']
                  : (int.tryParse(exercise['riposo_sec']?.toString() ?? '0') ?? 0);
              return exercise;
            }).toList()
          : [];
      return day;
    }).toList();

    return normalized;
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout, int index) {
  final normalizedWorkout = _normalizeWorkout(workout);
  final workoutId = normalizedWorkout['id_workout'];
  final isSelected = _selectedWorkoutId == workoutId || normalizedWorkout['selected'] == true;
  final isAiGenerated = normalizedWorkout['creato_da_ai'] == true;
  final settimana = normalizedWorkout['settimana'] as List<dynamic>;
  final isExpanded = _expandedCards[workoutId] ?? false;

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    decoration: BoxDecoration(
      color: Color(0xFF1A1D22),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: isSelected
              ? Color(0xFFFF2D55).withOpacity(0.3) // Ombra rossa per card selezionata
              : Colors.black.withOpacity(0.3), // Ombra standard per card non selezionata
          blurRadius: 10,
          spreadRadius: isSelected ? 2 : 0, // Leggero spread per card selezionata
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: workoutId != null
                ? () => _selectWorkout(workoutId, normalizedWorkout['titolo'])
                : null,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFFFF2D55).withOpacity(0.2)
                          : Color(0xFFFF2D55).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: isSelected ? Colors.white : Color(0xFFFF2D55),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                normalizedWorkout['titolo'],
                                style: TextStyle(
                                  fontFamily: 'NewYork',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isAiGenerated) _buildAiBadge(),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          normalizedWorkout['descrizione'],
                          style: TextStyle(
                            fontFamily: 'NewYork',
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _expandedCards[workoutId] = !isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white.withOpacity(0.2), height: 1),
                  SizedBox(height: 12),
                  Text(
                    'Settimana',
                    style: TextStyle(
                      fontFamily: 'NewYork',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...settimana.map((day) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 8),
                            Text(
                              day['giorno'],
                              style: TextStyle(
                                fontFamily: 'NewYork',
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '(${day['gruppi_muscolari'].join(', ')})',
                                style: TextStyle(
                                  fontFamily: 'NewYork',
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          print('Modifica allenamento: $workoutId');
                          _showErrorSnackbar('Funzionalità di modifica non implementata');
                        },
                        icon: Icon(Icons.edit, size: 16, color: Colors.white),
                        label: Text(
                          'Modifica',
                          style: TextStyle(
                            fontFamily: 'NewYork',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFF2D55).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteWorkout(workoutId),
                        icon: Icon(Icons.delete, size: 16, color: Colors.white),
                        label: Text(
                          'Elimina',
                          style: TextStyle(
                            fontFamily: 'NewYork',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    ),
  );
  }


  Widget _buildAiBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              fontFamily: 'NewYork',
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectWorkout(String workoutId, String workoutName) async {
    if (_isSelecting) {
      print('Selection already in progress, ignoring');
      return;
    }

    print('Selecting workout: $workoutId ($workoutName)');
    setState(() => _isSelecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _navigateToLogin();
        return;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/workouts/$workoutId/select'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'selected': true,
          'previousWorkoutId': _selectedWorkoutId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Selection successful, updating local state...');
        setState(() {
          _selectedWorkoutId = workoutId;
          _workoutsFuture = _workoutsFuture?.then((workouts) {
            Map<String, dynamic>? selectedNormalized;
            final updatedWorkouts = workouts.map((w) {
              final normalized = _normalizeWorkout(w);
              normalized['selected'] = normalized['id_workout'] == workoutId;
              if (normalized['id_workout'] == workoutId) {
                selectedNormalized = normalized;
              }
              return normalized;
            }).toList();
            if (selectedNormalized != null && mounted) {
              Future.microtask(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodayWorkoutPage(selectedWorkout: selectedNormalized!),
                  ),
                );
              });
            }
            return updatedWorkouts;
          });
        });
        if (mounted) {
          _showSuccessSnackbar(workoutName);
          print('UI updated with selected workout: $workoutId');
        }
      } else {
        print('Selection failed from server: ${response.statusCode}');
        if (mounted) {
          _showErrorSnackbar('Errore nella selezione dell\'allenamento: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error during selection: $e');
      if (mounted) {
        _showErrorSnackbar('Errore: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSelecting = false);
        print('Selection process completed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E11),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
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
                    Color(0xFF1A1D22).withOpacity(0.8),
                    Color(0xFF0A0E11).withOpacity(0.1),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  'Seleziona Allenamento',
                  style: TextStyle(
                    fontFamily: 'NewYork',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1D22).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _workoutsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }
                  final workouts = snapshot.data!;
                  return _buildWorkoutsList(workouts);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/allenamento');
          } else if (index == 1) {
            if (ModalRoute.of(context)?.settings.name != '/home') {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildWorkoutsList(List<Map<String, dynamic>> workouts) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: workouts.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(workout, index);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1D22),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Caricamento allenamenti...',
              style: TextStyle(
                fontFamily: 'NewYork',
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1D22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFF2D55).withOpacity(0.3)),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFFF2D55),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: TextStyle(
                fontFamily: 'NewYork',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Controlla la connessione e riprova',
              style: TextStyle(
                fontFamily: 'NewYork',
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWorkouts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF2D55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Riprova',
                    style: TextStyle(
                      fontFamily: 'NewYork',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1D22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Nessun allenamento disponibile',
              style: TextStyle(
                fontFamily: 'NewYork',
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea il tuo primo allenamento!',
              style: TextStyle(
                fontFamily: 'NewYork',
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'NewYork',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.green.shade600,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'NewYork',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Reutilizzo del CustomBottomNavBar dalla HomePage
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
        color: const Color(0xFF0E1215),
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