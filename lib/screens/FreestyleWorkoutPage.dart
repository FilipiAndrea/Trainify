import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class FreestyleWorkoutPage extends StatefulWidget {
  const FreestyleWorkoutPage({Key? key}) : super(key: key);

  @override
  _FreestyleWorkoutPageState createState() => _FreestyleWorkoutPageState();
}

class _FreestyleWorkoutPageState extends State<FreestyleWorkoutPage> {
  List<WorkoutExercise> _exercises = [];
  List<Map<String, dynamic>> _allExercises = [];
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isRunning = true;
  int? _currentExerciseIndex;
  int _currentSet = 1;
  int? _setInModifica;
  final TextEditingController _ripetizioniController = TextEditingController();
  final TextEditingController _caricoController = TextEditingController();
  List<Map<String, dynamic>> _setCompletati = [];
  List<Map<String, dynamic>> _risultati = [];
  List<Map<String, dynamic>> _datiEsercizi = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _startTimer();
    _caricaDatiEsercizi();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ripetizioniController.dispose();
    _caricoController.dispose();
    for (var exercise in _exercises) {
      exercise.seriesController.dispose();
      exercise.repsController.dispose();
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _duration = _duration + const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/datiEsercizi.json');
  }

  Future<void> _caricaDatiEsercizi() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      final contenuto = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contenuto);
      setState(() {
        _datiEsercizi = jsonData.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _salvaDatiEsercizi() async {
    try {
      final file = await _getLocalFile();
      List<Map<String, dynamic>> datiEsercizi = List.from(_datiEsercizi);

      for (var risultato in _risultati) {
        final idEsercizio = risultato['id'];
        final carico = double.tryParse(risultato['carico']) ?? 0.0;
        final ripetizioni = int.tryParse(risultato['ripetizioni']) ?? 0;

        var esercizio = datiEsercizi.firstWhere(
          (e) => e['_id'] == idEsercizio,
          orElse: () => {'_id': idEsercizio, 'carico': [], 'ripetizioni': []},
        );

        if (!datiEsercizi.any((e) => e['_id'] == idEsercizio)) {
          datiEsercizi.add(esercizio);
        }

        esercizio['carico'].add(carico);
        esercizio['ripetizioni'].add(ripetizioni);
      }

      await file.writeAsString(json.encode(datiEsercizi));
      print('Dati salvati in: ${file.path}');
    } catch (e) {
      print('Errore nel salvataggio: $e');
      _showCustomSnackBar('❗ Errore nel salvataggio', Colors.red);
    }
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
                color == Colors.green ? Icons.check_circle : Icons.error,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
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

  Future<void> _addExercise() async {
    final selectedExercise = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExerciseSelectionFullScreenDialog(exercises: _allExercises),
    );

    if (selectedExercise != null) {
      setState(() {
        _exercises.add(WorkoutExercise(
          exerciseData: selectedExercise,
          seriesController: TextEditingController(),
          repsController: TextEditingController(),
          sets: [],
        ));
        _currentExerciseIndex = _exercises.length - 1;
        _setCompletati = [];
        _currentSet = 1;
      });
    }
  }

  void _salvaSet() {
    if (_currentExerciseIndex == null || _currentExerciseIndex! >= _exercises.length) {
      _showCustomSnackBar('❗ Seleziona un esercizio', Colors.orange);
      return;
    }

    final carico = _caricoController.text;
    final ripetizioni = _ripetizioniController.text;

    if (carico.isEmpty || ripetizioni.isEmpty) {
      _showCustomSnackBar('❗ Inserisci carico e ripetizioni', Colors.orange);
      return;
    }

    setState(() {
      final exercise = _exercises[_currentExerciseIndex!];
      if (_setInModifica != null) {
        final index = _setCompletati.indexWhere((s) => s['set'] == _setInModifica);
        if (index != -1) {
          _setCompletati[index] = {
            'set': _setInModifica!,
            'carico': carico,
            'ripetizioni': ripetizioni,
          };
          exercise.sets[index] = _setCompletati[index];
        }
        _setInModifica = null;
      } else {
        _setCompletati.add({
          'set': _currentSet,
          'carico': carico,
          'ripetizioni': ripetizioni,
        });
        exercise.sets.add({
          'set': _currentSet,
          'carico': carico,
          'ripetizioni': ripetizioni,
        });
        _currentSet++;
      }

      _risultati = _exercises
          .asMap()
          .entries
          .expand((entry) => entry.value.sets.map((set) => {
                'id': entry.value.exerciseData['id'] ?? entry.key.toString(),
                ...set,
              }))
          .toList();

      _caricoController.clear();
      _ripetizioniController.clear();
    });
  }

  void _modificaSet(int setNumber) {
    final set = _setCompletati.firstWhere((s) => s['set'] == setNumber);
    setState(() {
      _setInModifica = setNumber;
      _caricoController.text = set['carico'];
      _ripetizioniController.text = set['ripetizioni'];
    });
  }

  Future<void> _completaAllenamento() async {
    if (_exercises.isEmpty) {
      _showCustomSnackBar('❗ Aggiungi almeno un esercizio', Colors.orange);
      return;
    }

    _stopTimer();
    await _aggiornaStreak();
    await _salvaDatiEsercizi();

    _showCustomSnackBar('✅ Allenamento completato!', Colors.green);
    await Future.delayed(Duration(milliseconds: 1500));
    Navigator.pop(context, {
      'risultati': _risultati,
      'tempo_totale': _duration.inSeconds,
    });
  }

  Future<void> _aggiornaStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      DateTime oggi = DateTime.now();
      DateTime? ultimaDataAllenamento;

      if (userData['lastWorkoutDate'] != null) {
        ultimaDataAllenamento = DateTime.tryParse(userData['lastWorkoutDate']);
      }

      if (ultimaDataAllenamento != null) {
        Duration diff = oggi.difference(ultimaDataAllenamento);
        if (diff.inDays == 1) {
          userData['streak'] = (userData['streak'] ?? 0) + 1;
        } else if (diff.inDays == 0) {
          // Allenamento già fatto oggi
        } else {
          userData['streak'] = 1;
        }
      } else {
        userData['streak'] = 1;
      }

      userData['lastWorkoutDate'] = oggi.toIso8601String();
      await prefs.setString('user_data', json.encode(userData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(
          'Allenamento Freestyle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            // fontFamily: 'NewYork', // Attiva se configurato in pubspec.yaml
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF5C35)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '${_duration.inHours.toString().padLeft(2, '0')}:${(_duration.inMinutes % 60).toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    // fontFamily: 'NewYork',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_exercises.isEmpty)
                      Expanded(
                        child: Center(
                          child: Container(
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF2D55),
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nessun esercizio selezionato',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    // fontFamily: 'NewYork',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tocca "Aggiungi Esercizio" per iniziare!',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                    // fontFamily: 'NewYork',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _exercises[index];
                            final isSelected = _currentExerciseIndex == index;
                            final esercizioCorrente = _datiEsercizi.firstWhere(
                              (e) => e['_id'] == (exercise.exerciseData['id'] ?? index.toString()),
                              orElse: () => {'carico': [], 'ripetizioni': []},
                            );
                            final ultimeRipetizioni = esercizioCorrente['ripetizioni'] as List<dynamic>;
                            final ultimaRipetizione = ultimeRipetizioni.isNotEmpty ? ultimeRipetizioni.last.toString() : '0';
                            final ultimiCarichi = esercizioCorrente['carico'] as List<dynamic>;
                            final ultimoCarico = ultimiCarichi.isNotEmpty ? ultimiCarichi.last.toString() : '0';

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentExerciseIndex = index;
                                  _setCompletati = List.from(exercise.sets);
                                  _setInModifica = null;
                                  _caricoController.clear();
                                  _ripetizioniController.clear();
                                  _currentSet = exercise.sets.isEmpty ? 1 : exercise.sets.last['set'] + 1;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2A2D32).withOpacity(0.9),
                                      Color(0xFF1A1D22).withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Color(0xFFFF2D55).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? Color(0xFFFF2D55).withOpacity(0.3) : Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: isSelected ? 2 : 0,
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
                                                    // fontFamily: 'NewYork',
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
                                                      // fontFamily: 'NewYork',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(height: 20),
                                        if (_setCompletati.isNotEmpty) ...[
                                          Text(
                                            'SET COMPLETATI',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.6),
                                              // fontFamily: 'NewYork',
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          ..._setCompletati.map((set) => GestureDetector(
                                                onTap: () => _modificaSet(set['set']),
                                                child: Container(
                                                  margin: EdgeInsets.only(bottom: 8),
                                                  padding: EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: _setInModifica == set['set']
                                                        ? Color(0xFFFF2D55).withOpacity(0.2)
                                                        : Color(0xFF1A1D22),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _setInModifica == set['set']
                                                          ? Color(0xFFFF2D55)
                                                          : Colors.transparent,
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'SET ${set['set']}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: _setInModifica == set['set']
                                                              ? Colors.white
                                                              : Colors.white.withOpacity(0.8),
                                                          // fontFamily: 'NewYork',
                                                        ),
                                                      ),
                                                      Text(
                                                        '${set['carico']} kg',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: _setInModifica == set['set']
                                                              ? Colors.white
                                                              : Color(0xFFFF2D55),
                                                          fontWeight: FontWeight.bold,
                                                          // fontFamily: 'NewYork',
                                                        ),
                                                      ),
                                                      Text(
                                                        '${set['ripetizioni']} reps',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: _setInModifica == set['set']
                                                              ? Colors.white
                                                              : Color(0xFFFF2D55),
                                                          fontWeight: FontWeight.bold,
                                                          // fontFamily: 'NewYork',
                                                        ),
                                                      ),
                                                      if (_setInModifica != set['set'])
                                                        Icon(
                                                          Icons.edit,
                                                          size: 18,
                                                          color: Colors.white.withOpacity(0.5),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          SizedBox(height: 20),
                                        ],
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  'CARICO (kg)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white.withOpacity(0.7),
                                                    // fontFamily: 'NewYork',
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Container(
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF0A0E11),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: TextField(
                                                    controller: _caricoController,
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      // fontFamily: 'NewYork',
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: ultimoCarico,
                                                      hintStyle: TextStyle(
                                                        color: Colors.white.withOpacity(0.3),
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  'RIPETIZIONI',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white.withOpacity(0.7),
                                                    // fontFamily: 'NewYork',
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Container(
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF1A1D22),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 6,
                                                        offset: Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: TextField(
                                                    controller: _ripetizioniController,
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      // fontFamily: 'NewYork',
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: ultimaRipetizione,
                                                      hintStyle: TextStyle(
                                                        color: Colors.white.withOpacity(0.3),
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFFF2D55), Color(0xFFFF5C35)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFFFF2D55).withOpacity(0.3),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _salvaSet,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              _setInModifica != null ? 'SALVA MODIFICHE' : 'SALVA SET',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                // fontFamily: 'NewYork',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
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
                        onPressed: _addExercise,
                        icon: Icon(Icons.add_circle, color: Colors.white),
                        label: Text(
                          'Aggiungi Esercizio',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            // fontFamily: 'NewYork',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
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
                        onPressed: _completaAllenamento,
                        icon: Icon(Icons.save_rounded, color: Colors.white, size: 24),
                        label: Text(
                          'COMPLETA ALLENAMENTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            // fontFamily: 'NewYork',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class WorkoutExercise {
  Map<String, dynamic> exerciseData;
  TextEditingController seriesController;
  TextEditingController repsController;
  List<Map<String, dynamic>> sets;

  WorkoutExercise({
    required this.exerciseData,
    required this.seriesController,
    required this.repsController,
    required this.sets,
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
    _muscleGroups = widget.exercises
        .map((e) => e['gruppo_muscolare'] as String? ?? 'Altro')
        .toSet()
        .toList()
      ..sort();
    _selectedGroup = _muscleGroups.isNotEmpty ? _muscleGroups[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((ex) {
      final gruppo = ex['gruppo_muscolare'] as String? ?? 'Altro';
      final nome = ex['nome'] as String? ?? '';
      final inGroup = gruppo == _selectedGroup;
      final matchesSearch = _searchTerm.isEmpty || nome.toLowerCase().contains(_searchTerm.toLowerCase());
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
                // fontFamily: 'NewYork',
              ),
            ),
          ),
        ],
      ),
      body: Container(
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
                    color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFFFF2D55).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    SizedBox(height: 4),
                    Text(
                      group,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                        // fontFamily: 'NewYork',
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : Color(0xFFFF2D55).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$exerciseCount',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Color(0xFFFF2D55),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          // fontFamily: 'NewYork',
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
                  // fontFamily: 'NewYork',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (_searchTerm.isNotEmpty) ...[
                Text(
                  'Prova con un termine diverso o',
                  style: TextStyle(color: Colors.white54, fontSize: 14, // fontFamily: 'NewYork'
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'seleziona un altro gruppo muscolare',
                  style: TextStyle(color: Colors.white54, fontSize: 14, // fontFamily: 'NewYork'
                  ),
                ),
              ] else ...[
                Text(
                  'Questo gruppo non ha esercizi disponibili',
                  style: TextStyle(color: Colors.white54, fontSize: 14, // fontFamily: 'NewYork'
                  ),
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
                              // fontFamily: 'NewYork',
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
                                    // fontFamily: 'NewYork',
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