import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TodayWorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? selectedWorkout; // Nullable selected workout

  const TodayWorkoutPage({Key? key, this.selectedWorkout}) : super(key: key);

  @override
  _TodayWorkoutPageState createState() => _TodayWorkoutPageState();
}

class _TodayWorkoutPageState extends State<TodayWorkoutPage> {
  late Future<Map<String, dynamic>> _eserciziCompleti;
  Future<Map<String, dynamic>?>? _workoutFuture;
  bool _isLoading = false;
  bool allenamentoCompletato = false;
  static const String _baseUrl = 'https://trainify-server.onrender.com/api';

  @override
  void initState() {
    super.initState();
    _eserciziCompleti = _loadEserciziDaAssets();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadWorkout();
    await controllaSeCompletato();
  }

  Future<void> _loadWorkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _navigateToLogin();
        return;
      }

      setState(() {
        if (widget.selectedWorkout != null) {
          // Use passed workout if available
          _workoutFuture = Future.value(_normalizeWorkout(widget.selectedWorkout!));
        } else {
          // Fetch from /user endpoint
          _workoutFuture = _fetchSelectedWorkout(token);
        }
      });
    } catch (e) {
      print('Error loading workout: $e');
      setState(() {
        _workoutFuture = Future.error(e);
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchSelectedWorkout(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('=== HTTP RESPONSE STATUS: ${response.statusCode} ===');
      print('=== RESPONSE BODY: ${response.body} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final workouts = List<Map<String, dynamic>>.from(data['allenamenti_salvati'] ?? []);
        print('=== FETCHED ${workouts.length} WORKOUTS ===');

        final selected = workouts.where((w) => w['selected'] == true).toList();
        if (selected.isNotEmpty) {
          final normalized = _normalizeWorkout(selected.first);
          print('Selected workout: ${normalized['titolo']}');
          return normalized;
        }
        print('No selected workout found');
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        print('=== ${response.statusCode == 401 ? 'Unauthorized' : 'User not found'} ===');
        _navigateToLogin();
        throw Exception(response.statusCode == 401 ? 'Non autenticato' : 'Utente non trovato');
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching selected workout: $e');
      throw Exception('Error fetching workout: $e');
    }
  }

  Future<Map<String, dynamic>> _loadEserciziDaAssets() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/esercizi.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return {for (var esercizio in jsonList) esercizio['_id']: esercizio};
    } catch (e) {
      throw Exception('Errore nel caricamento degli esercizi');
    }
  }

  Map<String, dynamic> _normalizeWorkout(Map<String, dynamic> workout) {
    final normalized = Map<String, dynamic>.from(workout);
    normalized['id_workout'] = normalized['id_workout']?.toString() ?? '';
    normalized['titolo'] = normalized['titolo'] ?? 'Allenamento senza nome';
    normalized['descrizione'] = normalized['descrizione'] ?? 'Nessuna descrizione';
    normalized['creato_da_ai'] = normalized['creato_da_ai'] is bool
        ? normalized['creato_da_ai']
        : (normalized['creato_da_ai']?.toString().toLowerCase() == 'true' || normalized['creato_da_ai'] == 1);
    normalized['selected'] = normalized['selected'] is bool
        ? normalized['selected']
        : (normalized['selected']?.toString().toLowerCase() == 'true' || normalized['selected'] == 1);
    normalized['settimana'] = normalized['settimana'] is List ? normalized['settimana'] : [];
    print('Settimana normalizzata: ${normalized['settimana']}');

    normalized['settimana'] = (normalized['settimana'] as List).asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value is Map ? Map<String, dynamic>.from(entry.value) : <String, dynamic>{};
      day['giorno'] = day['giorno']?.toString().toLowerCase() ?? 'giorno ${index + 1}';
      day['gruppi_muscolari'] = day['gruppi_muscolari'] is List ? day['gruppi_muscolari'] : [];
      day['esercizi'] = day['esercizi'] is List
          ? (day['esercizi'] as List).map((e) {
              final exercise = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
              exercise['id_esercizio'] = exercise['id_esercizio']?.toString() ?? '';
              exercise['serie'] = exercise['serie'] is int ? exercise['serie'] : (int.tryParse(exercise['serie']?.toString() ?? '0') ?? 0);
              exercise['ripetizioni'] = exercise['ripetizioni'] is int ? exercise['ripetizioni'] : (int.tryParse(exercise['ripetizioni']?.toString() ?? '0') ?? 0);
              exercise['riposo_sec'] = exercise['riposo_sec'] is int ? exercise['riposo_sec'] : (int.tryParse(exercise['riposo_sec']?.toString() ?? '0') ?? 0);
              return exercise;
            }).toList()
          : [];
      day['riposo'] = day['riposo'] is bool ? day['riposo'] : false;
      return day;
    }).toList();

    return normalized;
  }

  Future<bool> isAllenamentoCompletato() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('allenamento_today') ?? false;
  }

  Future<void> controllaSeCompletato() async {
    final completato = await isAllenamentoCompletato();
    setState(() {
      allenamentoCompletato = completato;
      print('Allenamento completato: $allenamentoCompletato');
    });
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE', 'it_IT').format(DateTime.now()).toLowerCase();
    final todayCapitalized = today[0].toUpperCase() + today.substring(1);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _workoutFuture,
      builder: (context, workoutSnapshot) {
        if (workoutSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(todayCapitalized);
        }

        if (workoutSnapshot.hasError) {
          return _buildEmptyState(todayCapitalized, "Errore nel caricamento dell'allenamento");
        }

        if (!workoutSnapshot.hasData || workoutSnapshot.data == null) {
          return _buildNoSelectionState(todayCapitalized);
        }

        final workout = workoutSnapshot.data!;
        return _buildWorkoutContent(workout, today, todayCapitalized);
      },
    );
  }

  Widget _buildWorkoutContent(Map<String, dynamic> workout, String today, String todayCapitalized) {
    print('Workout structure: $workout');
    final settimana = workout['settimana'] as List<dynamic>;
    print('Settimana ricevuta: $settimana');

    if (settimana.isEmpty) {
      print('Errore: settimana è vuota');
      return _buildEmptyState(todayCapitalized, "Allenamento non ha una programmazione settimanale");
    }

    print('Giorni disponibili nella settimana:');
    for (var giorno in settimana) {
      print('Giorno: ${giorno['giorno']}, Riposo: ${giorno['riposo']}');
    }

    final giornoOggi = settimana.where((g) {
      final giorno = g['giorno']?.toString().toLowerCase();
      print('Confrontando: $giorno con $today');
      return giorno == today;
    }).toList();

    print('Giorno trovato per oggi: ${giornoOggi.length} elementi');
    if (giornoOggi.isEmpty) {
      print('Errore: nessun giorno trovato per oggi');
      return _buildEmptyState(todayCapitalized, "Nessun workout previsto per oggi");
    }

    final dayData = giornoOggi.first;
    print('Dati del giorno: $dayData');

    if (dayData['riposo'] == true) {
      print('Giorno di riposo');
      return _buildRestDay(todayCapitalized);
    }

    final eserciziGiorno = dayData['esercizi'] as List<dynamic>;
    print('Esercizi del giorno: $eserciziGiorno');

    if (eserciziGiorno.isEmpty) {
      print('Errore: nessun esercizio programmato');
      return _buildEmptyState(todayCapitalized, "Nessun esercizio programmato per oggi");
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _eserciziCompleti,
      builder: (context, exerciseSnapshot) {
        if (exerciseSnapshot.connectionState != ConnectionState.done) {
          return _buildLoadingState(todayCapitalized);
        }

        if (exerciseSnapshot.hasError || !exerciseSnapshot.hasData || exerciseSnapshot.data!.isEmpty) {
          return _buildEmptyState(todayCapitalized, "Errore nel caricamento degli esercizi");
        }

        final eserciziCompleti = exerciseSnapshot.data!;
        final muscleGroups = _getMuscleGroups(dayData);

        return _buildWorkoutScaffold(
          todayCapitalized,
          workout,
          dayData,
          eserciziGiorno,
          eserciziCompleti,
          muscleGroups,
        );
      },
    );
  }

  Widget _buildWorkoutScaffold(
    String todayCapitalized,
    Map<String, dynamic> workout,
    dynamic giornoOggi,
    List<dynamic> eserciziGiorno,
    Map<String, dynamic> eserciziCompleti,
    List<String> muscleGroups,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(todayCapitalized),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con info workout
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0E11),
                  const Color(0xFF2D343C),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workout['titolo']?.toUpperCase() ?? 'ALLENAMENTO',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  workout['descrizione'] ?? 'Sessione di allenamento personalizzata',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: muscleGroups
                        .map(
                          (group) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2D55).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF2D55).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              group.toUpperCase(),
                              style: TextStyle(
                                color: const Color(0xFFFF2D55),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          // Lista esercizi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: eserciziGiorno.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final esercizioGiorno = eserciziGiorno[index];
                final id = esercizioGiorno['id_esercizio'];
                final esercizioDettagli = eserciziCompleti[id];

                if (esercizioDettagli == null) {
                  return _buildErrorCard(id);
                }

                return _buildExerciseCard(
                  esercizioDettagli,
                  esercizioGiorno,
                  index + 1,
                );
              },
            ),
          ),
          // Bottone inizia allenamento
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || allenamentoCompletato)
                    ? null
                    : () => _startWorkout(
                          context,
                          eserciziGiorno,
                          eserciziCompleti,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isLoading || allenamentoCompletato)
                      ? Colors.grey
                      : const Color(0xFFFF2D55),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        allenamentoCompletato
                            ? 'ALLENAMENTO COMPLETATO'
                            : 'INIZIA ALLENAMENTO',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoSelectionState(String title) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  size: 48,
                  color: const Color(0xFFFF2D55),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nessun allenamento selezionato',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vai alla selezione allenamenti per scegliere quale programma seguire',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/workoutSelection');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'SELEZIONA ALLENAMENTO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getMuscleGroups(dynamic giornoOggi) {
    try {
      final groups = giornoOggi['gruppi_muscolari'] as List<dynamic>?;
      return groups?.map((e) => e.toString()).toList() ?? ['Full Body'];
    } catch (e) {
      return ['Full Body'];
    }
  }

  Widget _buildExerciseCard(
    Map<String, dynamic> esercizio,
    Map<String, dynamic> esercizioGiorno,
    int index,
  ) {
    final nome = esercizio['nome'] ?? 'Esercizio sconosciuto';
    final serie = esercizioGiorno['serie']?.toString() ?? '-';
    final ripetizioni = esercizioGiorno['ripetizioni']?.toString() ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF2D55).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildExerciseDetail('Serie', serie),
                      _buildExerciseDetail('Ripetizioni', ripetizioni),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String id) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esercizio non trovato',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: $id',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkout(
    BuildContext context,
    List<dynamic> eserciziGiorno,
    Map<String, dynamic> eserciziCompleti,
  ) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    Navigator.pushNamed(
      context,
      '/activeWorkout',
      arguments: {
        'eserciziGiorno': eserciziGiorno,
        'eserciziCompleti': eserciziCompleti,
      },
    ).then((_) => setState(() => _isLoading = false));
  }

  Scaffold _buildLoadingState(String title) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF2D55)),
      ),
    );
  }

  Scaffold _buildEmptyState(String title, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildRestDay(String title) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.self_improvement,
                size: 48,
                color: Colors.greenAccent.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Oggi è il tuo giorno di riposo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lascia che i tuoi muscoli si riprendano per la prossima sessione',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}