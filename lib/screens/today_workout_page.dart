import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class TodayWorkoutPage extends StatefulWidget {
  final Map<String, dynamic> user;

  TodayWorkoutPage({required this.user});

  @override
  _TodayWorkoutPageState createState() => _TodayWorkoutPageState();
}

class _TodayWorkoutPageState extends State<TodayWorkoutPage> {
  late Future<Map<String, dynamic>> _eserciziCompleti;

  @override
  void initState() {
    super.initState();
    _eserciziCompleti = loadEserciziDaAssets();
  }

  Future<Map<String, dynamic>> loadEserciziDaAssets() async {
    final String jsonString = await rootBundle.loadString('assets/esercizi.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return {
      for (var esercizio in jsonList) esercizio['_id']: esercizio,
    };
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE', 'it_IT').format(DateTime.now()).toLowerCase();
    final todayCapitalized = today[0].toUpperCase() + today.substring(1);

    final allenamenti = widget.user['allenamenti_salvati'];
    if (allenamenti == null || allenamenti.isEmpty) {
      return _buildScaffold(todayCapitalized, "Nessun allenamento salvato.");
    }

    final workout = allenamenti.firstWhere(
      (w) => (w['settimana'] as List).any(
        (g) => g['giorno'].toString().toLowerCase() == today,
      ),
      orElse: () => null,
    );

    if (workout == null) {
      return _buildScaffold(todayCapitalized, "Nessun workout previsto per oggi.");
    }

    final settimana = workout['settimana'] as List<dynamic>;
    final giornoOggi = settimana.firstWhere(
      (g) => g['giorno'].toString().toLowerCase() == today,
      orElse: () => null,
    );

    if (giornoOggi == null || giornoOggi['riposo'] == true) {
      return _buildScaffold(todayCapitalized, "Oggi è giorno di riposo.");
    }

    final eserciziGiorno = giornoOggi['esercizi'] as List<dynamic>;

    return FutureBuilder<Map<String, dynamic>>(
      future: _eserciziCompleti,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildScaffold(todayCapitalized, "Caricamento esercizi...");
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildScaffold(todayCapitalized, "Errore nel caricamento degli esercizi.");
        }

        final eserciziCompleti = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(todayCapitalized),
            centerTitle: true,
            backgroundColor: const Color(0xFF060E15),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aggiungi il testo "Pianificato per oggi:"
                Text(
                  "Pianificato per oggi:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(height: 16), // Spazio tra il testo e la lista
                // Lista degli esercizi
                Expanded(
                  child: ListView.builder(
                    itemCount: eserciziGiorno.length,
                    itemBuilder: (context, index) {
                      final esercizioGiorno = eserciziGiorno[index];
                      final id = esercizioGiorno['id_esercizio'];
                      final esercizioDettagli = eserciziCompleti[id];

                      if (esercizioDettagli == null) {
                        return ListTile(
                          title: Text("Esercizio sconosciuto (ID: $id)"),
                          subtitle: Text("Controlla il file esercizi.json"),
                        );
                      }

                      final nome = esercizioDettagli['nome'];
                      final serie = esercizioGiorno['serie'] ?? '-';
                      final ripetizioni = esercizioGiorno['ripetizioni'] ?? '-';

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060E15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          children: [
                            // Icona prima dell'esercizio (esempio: fitness_center e accessibility)
                            Icon(
                              Icons.fitness_center, 
                              color: const Color.fromARGB(255, 255, 255, 255),
                              size: 30,
                            ),
                            SizedBox(width: 12), // Spazio tra l'icona e il testo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Serie: $serie • Ripetizioni: $ripetizioni",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Usa ScaffoldMessenger per mostrare il SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Allenamento iniziato!")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 224, 9, 9),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "SPINGI",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Scaffold _buildScaffold(String title, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: const Color(0xFF060E15),
      ),
      body: Center(child: Text(message)),
    );
  }
}
