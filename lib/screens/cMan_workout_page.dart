import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:trainify/screens/workout.api.dart';

class ManualWorkoutCreationPage extends StatefulWidget {
  @override
  _ManualWorkoutCreationPageState createState() => _ManualWorkoutCreationPageState();
}

class _ManualWorkoutCreationPageState extends State<ManualWorkoutCreationPage> with TickerProviderStateMixin {
  final TextEditingController _workoutNameController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Giorni della settimana con emoji
  final List<Map<String, String>> _weekDays = [
    {'key': 'lunedì', 'display': '🌟 Lunedì', 'emoji': '💪'},
    {'key': 'martedì', 'display': '🔥 Martedì', 'emoji': '⚡'},
    {'key': 'mercoledì', 'display': '⭐ Mercoledì', 'emoji': '🎯'},
    {'key': 'giovedì', 'display': '🚀 Giovedì', 'emoji': '💥'},
    {'key': 'venerdì', 'display': '🏆 Venerdì', 'emoji': '🔋'},
    {'key': 'sabato', 'display': '🎪 Sabato', 'emoji': '🎨'},
    {'key': 'domenica', 'display': '🌈 Domenica', 'emoji': '✨'},
  ];

  String _selectedWeekDay = 'lunedì';
  Map<String, WorkoutDay> _daysMap = {};
  List<Map<String, dynamic>> _allExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _daysMap[_selectedWeekDay] = WorkoutDay(name: _selectedWeekDay, exercises: []);
    _loadExercises();
    
    // Animazioni
    _fadeController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut)
    );
    
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _workoutNameController.dispose();
    for (var day in _daysMap.values) {
      for (var ex in day.exercises) {
        ex.seriesController.dispose();
        ex.repsController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final jsonString = await rootBundle.loadString('assets/esercizi.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _allExercises = jsonList.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento degli esercizi: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> buildWorkoutJson() {
    final settimana = _daysMap.entries
        .where((entry) => entry.value.exercises.isNotEmpty)
        .map((entry) {
      return {
        "giorno": entry.key,
        "gruppi_muscolari": entry.value.exercises
            .map((ex) => ex.exerciseData['gruppo_muscolare'] as String)
            .toSet()
            .toList(),
        "esercizi": entry.value.exercises.map((ex) {
          return {
            "nome": ex.exerciseData['nome'],
            "gruppo_muscolare": ex.exerciseData['gruppo_muscolare'],
            "serie": int.tryParse(ex.seriesController.text) ?? 0,
            "ripetizioni": int.tryParse(ex.repsController.text) ?? 0,
          };
        }).toList(),
      };
    }).toList();

    return {
      "titolo": _workoutNameController.text,
      "creato_da_ai": false,
      "data_creazione": DateTime.now().millisecondsSinceEpoch,
      "settimana": settimana,
    };
  }

  bool _validateWorkout() {
    if (_workoutNameController.text.trim().isEmpty) {
      _showCustomSnackBar('❗ Inserisci un nome per l\'allenamento', Colors.orange);
      return false;
    }

    final hasExercises = _daysMap.values.any((day) => day.exercises.isNotEmpty);
    if (!hasExercises) {
      _showCustomSnackBar('❗ Aggiungi almeno un esercizio', Colors.orange);
      return false;
    }

    return true;
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                color == Colors.green ? Icons.check_circle : 
                color == Colors.red ? Icons.error : Icons.warning,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2A2D32),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (!_validateWorkout()) return;

    // Animazione di caricamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF2A2D32),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF2D55)),
              SizedBox(height: 16),
              Text('Salvando allenamento...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      final workoutJson = buildWorkoutJson();
      final success = await WorkoutApi.saveWorkout(workoutJson);

      Navigator.pop(context); // Chiudi dialog caricamento

      if (success) {
        _showCustomSnackBar('✅ Allenamento salvato con successo', Colors.green);
        await Future.delayed(Duration(milliseconds: 1500));
        Navigator.pop(context);
      } else {
        _showCustomSnackBar('❌ Errore nel salvataggio', Colors.red);
      }
    } catch (e) {
      Navigator.pop(context);
      _showCustomSnackBar('❗ Errore imprevisto: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _daysMap[_selectedWeekDay] ?? WorkoutDay(name: _selectedWeekDay, exercises: []);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crea il tuo Workout', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF060E15).withOpacity(0.9),
                Color(0xFF1A1D22).withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Caricando esercizi...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0E11),
                        Color(0xFF1A1D22).withOpacity(0.3),
                        Color(0xFF0A0E11),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWorkoutNameSection(),
                          SizedBox(height: 24),
                          _buildWeekDaySelector(),
                          SizedBox(height: 24),
                          Expanded(child: _buildExerciseList(currentDay)),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWorkoutNameSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2D32).withOpacity(0.8),
            Color(0xFF1A1D22).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Text(
                'Nome Allenamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _workoutNameController,
            decoration: InputDecoration(
              hintText: 'Es: Allenamento Upper Body',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Color(0xFF0A0E11).withOpacity(0.7),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: Icon(Icons.edit, color: Color(0xFFFF2D55)),
            ),
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2D32).withOpacity(0.8),
            Color(0xFF1A1D22).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today, color: Colors.white, size: 20),
              ),
              SizedBox(width: 16),
              Text(
                'Seleziona Giorno',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final day = _weekDays[index];
                final isSelected = day['key'] == _selectedWeekDay;
                final hasExercises = _daysMap[day['key']]?.exercises.isNotEmpty ?? false;
                
                return Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWeekDay = day['key']!;
                        _daysMap.putIfAbsent(day['key']!, () => WorkoutDay(name: day['key']!, exercises: []));
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)])
                            : LinearGradient(colors: [Color(0xFF1A1D22), Color(0xFF2A2D32)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasExercises ? Color(0xFFFF2D55).withOpacity(0.5) : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(0xFFFF2D55).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['emoji']!,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            day['key']!.substring(0, 3).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(WorkoutDay day) {
    if (day.exercises.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A2D32).withOpacity(0.3),
              Color(0xFF1A1D22).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFF2D55).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: Color(0xFFFF2D55),
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Nessun esercizio per ${_weekDays.firstWhere((d) => d['key'] == _selectedWeekDay)['display']}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tocca "Aggiungi Esercizio" per iniziare!',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: day.exercises.length,
      itemBuilder: (context, index) {
        final exercise = day.exercises[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A2D32).withOpacity(0.9),
                Color(0xFF1A1D22).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exerciseData['nome'] ?? 'Esercizio sconosciuto',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF2D55).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              exercise.exerciseData['gruppo_muscolare'] ?? 'N/A',
                              style: TextStyle(
                                color: Color(0xFFFF2D55),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete, color: Colors.red, size: 20),
                      ),
                      onPressed: () => _removeExercise(_selectedWeekDay, index),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF0A0E11).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: exercise.seriesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Serie',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            prefixIcon: Icon(Icons.repeat, color: Color(0xFFFF2D55), size: 20),
                          ),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF0A0E11).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: exercise.repsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Ripetizioni',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            prefixIcon: Icon(Icons.format_list_numbered, color: Color(0xFFFF2D55), size: 20),
                          ),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(height: 20),
        // Bottone Aggiungi Esercizio
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF2D55).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _addExerciseToDay(_selectedWeekDay),
            icon: Icon(Icons.add_circle, color: Colors.white),
            label: Text(
              'Aggiungi Esercizio',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        // Bottone Salva Allenamento
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF00D4AA).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _saveWorkout,
            icon: Icon(Icons.save_rounded, color: Colors.white, size: 24),
            label: Text(
              'SALVA ALLENAMENTO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Future<void> _addExerciseToDay(String dayName) async {
    final selectedExercise = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExerciseSelectionFullScreenDialog(exercises: _allExercises),
    );

    if (selectedExercise != null) {
      setState(() {
        if (_daysMap[dayName] == null) {
          _daysMap[dayName] = WorkoutDay(name: dayName, exercises: []);
        }
        _daysMap[dayName]!.exercises.add(WorkoutExercise(
              exerciseData: selectedExercise,
              seriesController: TextEditingController(text: '3'),
              repsController: TextEditingController(text: '10'),
            ));
      });
    }
  }

  void _removeExercise(String dayName, int exerciseIndex) {
    setState(() {
      if (_daysMap[dayName] != null && 
          exerciseIndex >= 0 && 
          exerciseIndex < _daysMap[dayName]!.exercises.length) {
        final exercise = _daysMap[dayName]!.exercises[exerciseIndex];
        exercise.seriesController.dispose();
        exercise.repsController.dispose();
        _daysMap[dayName]!.exercises.removeAt(exerciseIndex);
      }
    });
  }
}

// Classi helper (invariate)
class WorkoutDay {
  String name;
  List<WorkoutExercise> exercises;
  WorkoutDay({required this.name, required this.exercises});
}

class WorkoutExercise {
  Map<String, dynamic> exerciseData;
  TextEditingController seriesController;
  TextEditingController repsController;
  WorkoutExercise({
    required this.exerciseData,
    required this.seriesController,
    required this.repsController,
  });
}

class ExerciseSelectionFullScreenDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;

  const ExerciseSelectionFullScreenDialog({Key? key, required this.exercises}) : super(key: key);

  @override
  _ExerciseSelectionFullScreenDialogState createState() => _ExerciseSelectionFullScreenDialogState();
}

class _ExerciseSelectionFullScreenDialogState extends State<ExerciseSelectionFullScreenDialog> 
    with TickerProviderStateMixin {
  late List<String> _muscleGroups;
  String _selectedGroup = '';
  String _searchTerm = '';
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mappa emoji per gruppi muscolari
  final Map<String, String> _muscleGroupEmojis = {
    'Petto': '💪',
    'Schiena': '🔥',
    'Spalle': '⭐',
    'Braccia': '💥',
    'Gambe': '🦵',
    'Addominali': '🎯',
    'Glutei': '🍑',
    'Cardio': '❤️',
    'Full Body': '🏋️',
    'Altro': '⚡',
  };

  @override
  void initState() {
    super.initState();
    
    // Animazioni
    _fadeController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _slideController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut)
    );
    
    _muscleGroups = widget.exercises
        .map((e) => e['gruppo_muscolare'] as String? ?? 'Altro')
        .toSet()
        .toList()
      ..sort();
    _selectedGroup = _muscleGroups.isNotEmpty ? _muscleGroups[0] : '';
    
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200), () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((ex) {
      final gruppo = ex['gruppo_muscolare'] as String? ?? 'Altro';
      final nome = ex['nome'] as String? ?? '';
      
      final inGroup = gruppo == _selectedGroup;
      final matchesSearch = _searchTerm.isEmpty ||
          nome.toLowerCase().contains(_searchTerm.toLowerCase());
      return inGroup && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF060E15).withOpacity(0.95),
                Color(0xFF1A1D22).withOpacity(0.9),
              ],
            ),
          ),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Color(0xFF2A2D32).withOpacity(0.8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '🔍 Cerca il tuo esercizio...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF2D55).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.clear, color: Color(0xFFFF2D55), size: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _searchTerm = '';
                        });
                      },
                    )
                  : Icon(Icons.search, color: Colors.white38),
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFF2D55).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFF2D55).withOpacity(0.3)),
            ),
            child: Text(
              '${filteredExercises.length} esercizi',
              style: TextStyle(
                color: Color(0xFFFF2D55),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0E11),
                  Color(0xFF1A1D22).withOpacity(0.3),
                  Color(0xFF0A0E11),
                ],
              ),
            ),
            child: Column(
              children: [
                SafeArea(child: SizedBox(height: 10)),
                _buildMuscleGroupFilter(),
                Expanded(child: _buildExercisesList(filteredExercises)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupFilter() {
    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _muscleGroups.length,
        itemBuilder: (context, index) {
          final group = _muscleGroups[index];
          final isSelected = group == _selectedGroup;
          final emoji = _muscleGroupEmojis[group] ?? '⚡';
          final exerciseCount = widget.exercises
              .where((e) => (e['gruppo_muscolare'] as String? ?? 'Altro') == group)
              .length;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup = group;
                  _searchTerm = '';
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)])
                      : LinearGradient(colors: [
                          Color(0xFF2A2D32).withOpacity(0.8),
                          Color(0xFF1A1D22).withOpacity(0.6),
                        ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: Color(0xFFFF2D55).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 4),
                    Text(
                      group,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.2)
                            : Color(0xFFFF2D55).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$exerciseCount',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Color(0xFFFF2D55),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExercisesList(List<Map<String, dynamic>> filteredExercises) {
    if (filteredExercises.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(40),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A2D32).withOpacity(0.3),
                Color(0xFF1A1D22).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFFF2D55).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.search_off,
                  color: Color(0xFFFF2D55),
                  size: 48,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '🔍 Nessun esercizio trovato',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (_searchTerm.isNotEmpty) ...[
                Text(
                  'Prova con un termine diverso o',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'seleziona un altro gruppo muscolare',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ] else ...[
                Text(
                  'Questo gruppo non ha esercizi disponibili',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A2D32).withOpacity(0.9),
                Color(0xFF1A1D22).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context, exercise),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center,
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
                            exercise['nome'] ?? 'Esercizio sconosciuto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF2D55).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_muscleGroupEmojis[exercise['gruppo_muscolare']] ?? '⚡'} ${exercise['gruppo_muscolare'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: Color(0xFFFF2D55),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}