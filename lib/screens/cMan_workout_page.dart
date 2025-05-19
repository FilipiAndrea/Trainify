import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:trainify/screens/workout.api.dart';

class ManualWorkoutCreationPage extends StatefulWidget {
  @override
  _ManualWorkoutCreationPageState createState() => _ManualWorkoutCreationPageState();
}

class _ManualWorkoutCreationPageState extends State<ManualWorkoutCreationPage> {
  final TextEditingController _workoutNameController = TextEditingController();

  // Giorni della settimana
  final List<String> _weekDays = ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'];

  // Giorno selezionato
  String _selectedWeekDay = 'Lun';

  // Mappa giorno -> esercizi (WorkoutDay)
  Map<String, WorkoutDay> _daysMap = {};

  List<Map<String, dynamic>> _allExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _daysMap[_selectedWeekDay] = WorkoutDay(name: _selectedWeekDay, exercises: []);
    _loadExercises();
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
    // Costruiamo la lista settimana a partire da _daysMap
    final settimana = _daysMap.entries.map((entry) {
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

  Future<void> _saveWorkout() async {
    try {
      final workoutJson = buildWorkoutJson();
      final success = await WorkoutApi.saveWorkout(workoutJson);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Allenamento salvato con successo')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Errore nel salvataggio')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ Errore imprevisto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _daysMap[_selectedWeekDay] ?? WorkoutDay(name: _selectedWeekDay, exercises: []);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: const Text('Crea Allenamento Manuale'),
        backgroundColor: const Color(0xFF060E15),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome allenamento
                  TextField(
                    controller: _workoutNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome Allenamento',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1D22),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Selezione giorno della settimana Dropdown
                  _buildWeekDaySelector(),
                  const SizedBox(height: 20),

                  // Lista esercizi giorno selezionato
                  Expanded(child: _buildExerciseList(currentDay)),

                  // Bottone aggiungi esercizio
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _addExerciseToDay(_selectedWeekDay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Aggiungi Esercizio'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottone SALVA ALLENAMENTO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveWorkout,
                      icon: const Icon(Icons.save),
                      label: const Text('SALVA ALLENAMENTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeekDaySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedWeekDay,
      decoration: InputDecoration(
        labelText: 'Seleziona Giorno',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1D22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dropdownColor: const Color(0xFF1A1D22),
      iconEnabledColor: Colors.white70,
      style: const TextStyle(color: Colors.white),
      items: _weekDays
          .map(
            (day) => DropdownMenuItem(
              value: day,
              child: Text(day),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedWeekDay = value;
          _daysMap.putIfAbsent(value, () => WorkoutDay(name: value, exercises: []));
        });
      },
    );
  }

  Widget _buildExerciseList(WorkoutDay day) {
    if (day.exercises.isEmpty) {
      return const Center(
        child: Text(
          'Nessun esercizio aggiunto',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: day.exercises.length,
      itemBuilder: (context, index) {
        final exercise = day.exercises[index];
        return Card(
          color: const Color(0xFF1A1D22),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exercise.exerciseData['nome'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeExercise(_selectedWeekDay, index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gruppo muscolare: ${exercise.exerciseData['gruppo_muscolare']}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: exercise.seriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Serie',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E11).withOpacity(0.5),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: exercise.repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ripetizioni',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E11).withOpacity(0.5),
                        ),
                        style: const TextStyle(color: Colors.white),
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

  Future<void> _addExerciseToDay(String dayName) async {
    final selectedExercise = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExerciseSelectionFullScreenDialog(exercises: _allExercises),
    );

    if (selectedExercise != null) {
      setState(() {
        _daysMap[dayName]?.exercises.add(WorkoutExercise(
              exerciseData: selectedExercise,
              seriesController: TextEditingController(text: '3'),
              repsController: TextEditingController(text: '10'),
            ));
      });
    }
  }

  void _removeExercise(String dayName, int exerciseIndex) {
    setState(() {
      _daysMap[dayName]?.exercises.removeAt(exerciseIndex);
    });
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    for (var day in _daysMap.values) {
      for (var ex in day.exercises) {
        ex.seriesController.dispose();
        ex.repsController.dispose();
      }
    }
    super.dispose();
  }
}

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

class _ExerciseSelectionFullScreenDialogState extends State<ExerciseSelectionFullScreenDialog> {
  late List<String> _muscleGroups;
  String _selectedGroup = '';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _muscleGroups = widget.exercises
        .map((e) => e['gruppo_muscolare'] as String)
        .toSet()
        .toList()
      ..sort();
    _selectedGroup = _muscleGroups.isNotEmpty ? _muscleGroups[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((ex) {
      final inGroup = ex['gruppo_muscolare'] == _selectedGroup;
      final matchesSearch = _searchTerm.isEmpty ||
          (ex['nome'] as String).toLowerCase().contains(_searchTerm.toLowerCase());
      return inGroup && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060E15),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Cerca esercizio...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _searchTerm = '';
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            color: const Color(0xFF060E15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = group == _selectedGroup;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedGroup = group;
                        _searchTerm = '';
                      });
                    },
                    selectedColor: const Color(0xFFFF2D55),
                    backgroundColor: const Color(0xFF1A1D22),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredExercises.isEmpty
                ? const Center(
                    child: Text('Nessun esercizio trovato', style: TextStyle(color: Colors.white70)),
                  )
                : ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return ListTile(
                        title: Text(
                          exercise['nome'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          exercise['gruppo_muscolare'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () => Navigator.pop(context, exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
