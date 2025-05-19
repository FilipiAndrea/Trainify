import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TodayWorkoutPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const TodayWorkoutPage({Key? key, required this.user}) : super(key: key);

  @override
  _TodayWorkoutPageState createState() => _TodayWorkoutPageState();
}

class _TodayWorkoutPageState extends State<TodayWorkoutPage> {
  late Future<Map<String, dynamic>> _eserciziCompleti;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _eserciziCompleti = _loadEserciziDaAssets();
    controllaSeCompletato();
  }

  Future<Map<String, dynamic>> _loadEserciziDaAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/esercizi.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return {for (var esercizio in jsonList) esercizio['_id']: esercizio};
    } catch (e) {
      throw Exception('Errore nel caricamento degli esercizi');
    }
  }

  bool allenamentoCompletato = false;

  Future<bool> isAllenamentoCompletato() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('allenamento_today') ?? false;
  }


  void controllaSeCompletato() async {
    final completato = await isAllenamentoCompletato();
    setState(() {
      allenamentoCompletato = completato;
      print('Allenamento completato: $allenamentoCompletato');
    });

  }

  @override
  Widget build(BuildContext context) {
    final today =
        DateFormat('EEEE', 'it_IT').format(DateTime.now()).toLowerCase();
    final todayCapitalized = today[0].toUpperCase() + today.substring(1);

    final allenamenti = widget.user['allenamenti_salvati'];
    if (allenamenti == null || allenamenti.isEmpty) {
      return _buildEmptyState(todayCapitalized, "Nessun allenamento salvato");
    }

    final workout = allenamenti.firstWhere(
      (w) => (w['settimana'] as List).any(
        (g) => g['giorno'].toString().toLowerCase() == today,
      ),
      orElse: () => null,
    );

    if (workout == null) {
      return _buildEmptyState(
        todayCapitalized,
        "Nessun workout previsto per oggi",
      );
    }

    final settimana = workout['settimana'] as List<dynamic>;
    final giornoOggi = settimana.firstWhere(
      (g) => g['giorno'].toString().toLowerCase() == today,
      orElse: () => null,
    );

    if (giornoOggi == null || giornoOggi['riposo'] == true) {
      return _buildRestDay(todayCapitalized);
    }

    final eserciziGiorno = giornoOggi['esercizi'] as List<dynamic>;

    return FutureBuilder<Map<String, dynamic>>(
      future: _eserciziCompleti,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingState(todayCapitalized);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            todayCapitalized,
            "Errore nel caricamento degli esercizi",
          );
        }

        final eserciziCompleti = snapshot.data!;
        final muscleGroups = _getMuscleGroups(giornoOggi);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E11),
          appBar: AppBar(
            title: Text(todayCapitalized), // Solo il testo del giorno
            centerTitle: true,
            backgroundColor: const Color(0xFF0A0E11),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Sostituisci questa parte nel tuo codice
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
                      const Color(0xFF0A0E11), // Dark
                      const Color(0xFF2D343C), // Lighter
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
                      workout['descrizione'] ??
                          'Sessione di allenamento personalizzata',
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
                        children:
                            muscleGroups
                                .map(
                                  (group) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF2D55,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFFF2D55,
                                        ).withOpacity(0.3),
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
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 12),
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
      },
    );
  }

  // ... (mantieni tutti gli altri metodi helper esattamente come nella versione precedente)
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
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF060E15),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF2D55)),
      ),
    );
  }

  Scaffold _buildEmptyState(String title, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF060E15),
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
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF060E15),
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
