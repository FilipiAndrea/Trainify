import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainify/utils/workout_utils.dart';

class WorkoutSelectionPage extends StatefulWidget {
  @override
  _WorkoutSelectionPageState createState() => _WorkoutSelectionPageState();
}

class _WorkoutSelectionPageState extends State<WorkoutSelectionPage> with TickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? _workoutsFuture;
  String? _selectedWorkoutId;
  bool _isSelecting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadWorkouts();
    await _loadSelectedWorkout();
    _animationController.forward();
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
        _workoutsFuture = _fetchWorkoutsWithCache(token);
      });
    } catch (e) {
      setState(() {
        _workoutsFuture = Future.error(e);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWorkoutsWithCache(String token) async {
    try {
      // Try to load from cache first
      final cachedWorkouts = await WorkoutUtils.loadWorkoutsFromPrefs();
      if (cachedWorkouts != null && cachedWorkouts.isNotEmpty) {
        print('Loading workouts from cache');
        return cachedWorkouts;
      }

      // If no cache, fetch from network
      print('Fetching workouts from network');
      final fetchedWorkouts = await WorkoutUtils.fetchWorkouts(token);
      await WorkoutUtils.saveWorkoutsLocally(fetchedWorkouts);
      return fetchedWorkouts;
    } catch (e) {
      print('Error in _fetchWorkoutsWithCache: $e');
      // If network fails, try to return cached data even if empty
      final cachedWorkouts = await WorkoutUtils.loadWorkoutsFromPrefs();
      if (cachedWorkouts != null) {
        return cachedWorkouts;
      }
      throw e;
    }
  }

  Future<void> _loadSelectedWorkout() async {
    try {
      // Prima carica dalle SharedPreferences
      final prefId = await WorkoutUtils.getSelectedWorkout();
      if (prefId != null && mounted) {
        setState(() {
          _selectedWorkoutId = prefId;
        });
        print('Selected workout ID from prefs: $prefId');
      }

      // Poi verifica nei dati degli allenamenti
      final workouts = await _workoutsFuture;
      if (workouts != null && workouts.isNotEmpty) {
        print('=== CHECKING WORKOUTS FOR SELECTION ===');
        
        // Debug: stampa tutti i workout per vedere la struttura
        for (var workout in workouts) {
          print('Workout: ${workout['titolo']}');
          print('ID: ${workout['id_workout']}');
          print('Selected: ${workout['selected']} (Type: ${workout['selected'].runtimeType})');
          print('Creato da AI: ${workout['creato_da_ai']} (Type: ${workout['creato_da_ai'].runtimeType})');
          
          // Debug completo della struttura
          WorkoutUtils.debugWorkoutStructure(workout);
          print('---');
        }
        
        // Cerca l'allenamento con selected = true
        final selected = workouts.where((w) => w['selected'] == true).toList();
        
        if (selected.isNotEmpty && selected.first['id_workout'] != null) {
          final selectedId = selected.first['id_workout'].toString();
          
          // Aggiorna solo se diverso da quello già salvato
          if (_selectedWorkoutId != selectedId && mounted) {
            setState(() {
              _selectedWorkoutId = selectedId;
            });
            // Salva nelle preferences per sincronizzare
            await WorkoutUtils.saveSelectedWorkout(selectedId);
            print('Updated selected workout ID from data: $selectedId');
          }
        } else {
          print('No workout found with selected=true in the data');
          
          // Se non c'è nessun workout selezionato nei dati ma c'è uno nelle preferences,
          // aggiorna i dati locali
          if (_selectedWorkoutId != null) {
            final matchingWorkout = workouts.where((w) => 
                w['id_workout']?.toString() == _selectedWorkoutId).toList();
            
            if (matchingWorkout.isNotEmpty) {
              print('Updating local data to reflect preference selection');
              // Aggiorna i dati locali
              for (var workout in workouts) {
                workout['selected'] = workout['id_workout']?.toString() == _selectedWorkoutId;
              }
              await WorkoutUtils.saveWorkoutsLocally(workouts);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading selected workout: $e');
    }
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout, int index) {
    final workoutId = workout['id_workout']?.toString();
    final isSelected = _selectedWorkoutId == workoutId || workout['selected'] == true;
    final isAiGenerated = workout['creato_da_ai'] == true;

    // Debug per questo specifico workout
    print('Rendering workout ${workout['titolo']}: ID=$workoutId, selected=${workout['selected']}, isSelected=$isSelected, AI=${workout['creato_da_ai']}, isAI=$isAiGenerated');

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Color(0xFFFF2D55),
                  Color(0xFFFF6B35),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [
                  Color(0xFF1D1E33),
                  Color(0xFF0A0E21),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Color(0xFFFF2D55).withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 15 : 10,
            offset: Offset(0, isSelected ? 8 : 4),
          ),
        ],
        border: isSelected 
            ? null 
            : Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: workoutId != null 
              ? () => _selectWorkout(workoutId, workout['titolo'] ?? 'Allenamento')
              : null,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Leading Icon with AI Badge
                _buildWorkoutIcon(isSelected, isAiGenerated),
                
                SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with AI Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workout['titolo'] ?? 'Allenamento senza nome',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isAiGenerated) _buildAiBadge(),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Description
                      Text(
                        workout['descrizione'] ?? 'Nessuna descrizione disponibile',
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Debug info (rimuovi in produzione)
                      if (true) ...[  // Cambia in false per rimuovere il debug
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DEBUG: selected=${workout['selected']}, ai=${workout['creato_da_ai']}',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                      
                      if (workout['data_creazione'] != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isSelected ? Colors.white : Color(0xFFFF2D55)).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Creato: ${_formatDate(workout['data_creazione'])}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Color(0xFFFF2D55),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Trailing
                _buildTrailingWidget(isSelected, workoutId),
              ],
            ),
          ),
        ),
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

      print('Calling selectWorkout API...');
      final success = await WorkoutUtils.selectWorkout(token, workoutId);
      
      if (success) {
        print('Selection successful, updating local state...');
        
        // Aggiorna immediatamente lo stato locale
        setState(() => _selectedWorkoutId = workoutId);
        
        // Salva nelle preferences
        await WorkoutUtils.saveSelectedWorkout(workoutId);
        
        // Aggiorna la cache dei workout
        final currentWorkouts = await _workoutsFuture;
        if (currentWorkouts != null) {
          final updatedWorkouts = currentWorkouts.map((workout) {
            workout['selected'] = workout['id_workout']?.toString() == workoutId;
            return workout;
          }).toList();
          
          await WorkoutUtils.saveWorkoutsLocally(updatedWorkouts);
          
          // Forza il refresh della UI
          setState(() {
            _workoutsFuture = Future.value(updatedWorkouts);
          });
        }
        
        if (mounted) {
          _showSuccessSnackbar(workoutName);
          print('UI updated with selected workout: $workoutId');
        }
      } else {
        print('Selection failed from server');
        if (mounted) {
          _showErrorSnackbar('Errore nella selezione dell\'allenamento');
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

  // Resto del codice rimane uguale...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E11),
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1D22),
                    Color(0xFF0A0E11).withOpacity(0.8),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  'Seleziona Allenamento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1D1E33),
                    Color(0xFF0A0E21),
                  ],
                ),
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(List<Map<String, dynamic>> workouts) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(20),
      itemCount: workouts.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(workout, index);
      },
    );
  }

  Widget _buildWorkoutIcon(bool isSelected, bool isAiGenerated) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.2)
            : Color(0xFFFF2D55).withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? Colors.white.withOpacity(0.3) : Color(0xFFFF2D55).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            color: isSelected ? Colors.white : Color(0xFFFF2D55),
            size: 28,
          ),
          if (isAiGenerated)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(bool isSelected, String? workoutId) {
    if (_isSelecting && isSelected) {
      return Container(
        width: 32,
        height: 32,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.2)
            : Color(0xFFFF2D55).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? Colors.white : Color(0xFFFF2D55),
        size: 24,
      ),
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Caricamento allenamenti...',
              style: TextStyle(
                color: Colors.white70,
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
      padding: EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFFFF2D55).withOpacity(0.3)),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFFF2D55),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Errore nel caricamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Controlla la connessione e riprova',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadWorkouts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF2D55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                elevation: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Riprova',
                    style: TextStyle(
                      fontSize: 16,
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 60,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Nessun allenamento disponibile',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Crea il tuo primo allenamento!',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Data non valida';
      }
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Data non valida';
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showSuccessSnackbar(String workoutName) {
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
                '"$workoutName" selezionato con successo!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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