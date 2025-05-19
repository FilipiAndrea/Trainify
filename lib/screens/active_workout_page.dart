import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class ActiveWorkoutPage extends StatefulWidget {
  final List<dynamic> eserciziGiorno;
  final Map<String, dynamic> eserciziCompleti;

  const ActiveWorkoutPage({
    required this.eserciziGiorno,
    required this.eserciziCompleti,
    Key? key,
  }) : super(key: key);

  @override
  _ActiveWorkoutPageState createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  int currentIndex = 0;
  int currentSet = 1;

  final TextEditingController ripetizioniController = TextEditingController();
  final TextEditingController caricoController = TextEditingController();

  List<Map<String, dynamic>> setCompletati = [];
  List<Map<String, dynamic>> risultati = [];
  int? setInModifica;

  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isRunning = true;

  List<Map<String, dynamic>> datiEsercizi = [];

  @override
  void initState() {
    super.initState();
    _startTimer(); // Avvia il timer quando la pagina viene caricata
    _caricaDatiEsercizi();
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Assicurati di cancellare il timer quando il widget viene distrutto
    super.dispose();
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

  Future<void> segnaAllenamentoCompletato() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allenamento_today', true);
  }

  /*
  Future<void> leggiFileLocale() async {
    try {
      final file = await _getLocalFile();
      final contenuto = await file.readAsString();

    } catch (e) {
      print('Errore lettura file: $e');
    }
  }*/

  //DEBUG
  Future<void> resettaDatiEsercizi() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.writeAsString('[]'); // Svuota il contenuto
      print("File datiEsercizi.json svuotato");
    } else {
      print("File non trovato");
    }
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    print('Directory locale: ${directory.path}');
    return File('${directory.path}/datiEsercizi.json');
  }

  Future<void> _caricaDatiEsercizi() async {
    final file =
        await _getLocalFile(); // Funzione che ti restituisce il File corretto
    if (await file.exists()) {
      final contenuto = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contenuto);
      print(" contenuto: $contenuto");
      setState(() {
        datiEsercizi = jsonData.cast<Map<String, dynamic>>();
      });
      print(datiEsercizi);
    }
  }

  Future<void> _salvaDatiEsercizio() async {
    try {
      final file = await _getLocalFile();
      List<Map<String, dynamic>> datiEsercizi = [];

      // Se il file esiste, caricalo
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        datiEsercizi = List<Map<String, dynamic>>.from(json.decode(jsonString));
      } else {
        // Altrimenti usa l'asset come base
        final jsonString = await rootBundle.loadString(
          'assets/datiEsercizi.json',
        );
        datiEsercizi = List<Map<String, dynamic>>.from(json.decode(jsonString));
      }


      // Aggiorna i dati
      for (var risultato in risultati) {
        final idEsercizio = risultato['id_esercizio'];
        final carico = risultato['carico'];
        final ripetizioni = risultato['ripetizioni'];

        var esercizio = datiEsercizi.firstWhere(
          (e) => e['_id'] == idEsercizio,
          orElse: () => {'_id': idEsercizio, 'carico': [], 'ripetizioni': []},
        );

        if (!datiEsercizi.any((e) => e['_id'] == idEsercizio)) {
          datiEsercizi.add(esercizio);
        }

        (esercizio['carico'] as List).add(carico);
        (esercizio['ripetizioni'] as List).add(ripetizioni);
      }

      // Salva nel file locale
      await file.writeAsString(json.encode(datiEsercizi));
      print('Dati salvati in: ${file.path}');
      //leggiFileLocale();
    } catch (e) {
      print('Errore nel salvataggio: $e');
    }
  }

  void salvaEPassa() {
    final carico = caricoController.text;
    final ripetizioni = ripetizioniController.text;

    if (carico.isEmpty || ripetizioni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Inserisci carico e ripetizioni"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color(0xFFFF2D55),
        ),
      );
      return;
    }

    setState(() {
      if (setInModifica != null) {
        // Modifica un set esistente
        final index = setCompletati.indexWhere(
          (s) => s['set'] == setInModifica,
        );
        if (index != -1) {
          setCompletati[index] = {
            'set': setInModifica!,
            'carico': carico,
            'ripetizioni': ripetizioni,
          };
        }
        setInModifica = null;
      } else {
        // Aggiungi un nuovo set
        setCompletati.add({
          'set': currentSet,
          'carico': carico,
          'ripetizioni': ripetizioni,
        });

        final serie =
            int.tryParse(
              widget.eserciziGiorno[currentIndex]['serie'].toString(),
            ) ??
            0;

        if (currentSet < serie) {
          currentSet++;
        }
      }

      // Aggiorna risultati completi
      risultati =
          setCompletati
              .map(
                (set) => {
                  'id_esercizio':
                      widget.eserciziGiorno[currentIndex]['id_esercizio'],
                  ...set,
                },
              )
              .toList();

      ripetizioniController.clear();
      caricoController.clear();

      // Se abbiamo completato tutti i set
      if (setCompletati.length ==
              widget.eserciziGiorno[currentIndex]['serie'] &&
          currentIndex < widget.eserciziGiorno.length - 1) {
        _passaAlProssimoEsercizio();
      }
    });
  }

  void _passaAlProssimoEsercizio() {
    setState(() {
      setCompletati.clear();
      currentIndex++;
      currentSet = 1;
    });
  }

  void _completaAllenamento() async {
    _stopTimer();
    await _aggiornaStreak();
    await segnaAllenamentoCompletato();
    await _salvaDatiEsercizio();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Allenamento completato!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );

    final resultsWithTime = {
      'risultati': risultati,
      'tempo_totale': _duration.inSeconds,
    };

    Navigator.pop(context, resultsWithTime);
  }

  void _modificaSet(int numeroSet) {
    final set = setCompletati.firstWhere((s) => s['set'] == numeroSet);
    setState(() {
      setInModifica = numeroSet;
      caricoController.text = set['carico'];
      ripetizioniController.text = set['ripetizioni'];
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
          // Giorno successivo -> aumenta streak
          userData['streak'] = (userData['streak'] ?? 0) + 1;
        } else if (diff.inDays == 0) {
          // Allenamento già fatto oggi -> non fare nulla
        } else {
          // Più di un giorno -> reset streak
          userData['streak'] = 1;
        }
      } else {
        // Primo allenamento -> inizializza streak
        userData['streak'] = 1;
      }

      // Aggiorna la data dell'allenamento
      userData['lastWorkoutDate'] = oggi.toIso8601String();

      // Salva i dati aggiornati
      await prefs.setString('user_data', json.encode(userData));

      print("Streak aggiornata: ${userData['streak']}");
    } else {
      // Nessun dato utente trovato
      print("Dati utente non trovati.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final esercizio = widget.eserciziGiorno[currentIndex];
    final dettagli = widget.eserciziCompleti[esercizio['id_esercizio']] ?? {};
    final nome = dettagli['nome'] ?? 'Esercizio sconosciuto';
    final tuttiSetCompletati = setCompletati.length == esercizio['serie'];

    final esercizioCorrente = datiEsercizi.firstWhere(
      (e) => e['_id'] == widget.eserciziGiorno[currentIndex]['id_esercizio'],
      orElse: () => {'carico': [], 'ripetizioni': []},
    );


    final ultimeRipetizioni = esercizioCorrente['ripetizioni'];
    final ultimaRipetizione =
        (ultimeRipetizioni.isNotEmpty)
            ? ultimeRipetizioni.last.toString()
            : '0';

    final ultimiCarichi = esercizioCorrente['carico'];
    final ultimoCarico =
        (ultimiCarichi.isNotEmpty) ? ultimiCarichi.last.toString() : '0';


    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(
          "Esercizio ${currentIndex + 1}/${widget.eserciziGiorno.length}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0A0E11),
        elevation: 0,
        actions: [
          // IL TIMER VA QUI
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D55), Color(0xFFFF5C35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${_duration.inHours.toString().padLeft(2, '0')}'
                  ':${(_duration.inMinutes % 60).toString().padLeft(2, '0')}'
                  ':${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (tuttiSetCompletati &&
              currentIndex < widget.eserciziGiorno.length - 1)
            TextButton(
              onPressed: _passaAlProssimoEsercizio,
              child: Text(
                "SALTA",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  nome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Completed sets section

            // Current set section
            if (!tuttiSetCompletati) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D55).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF2D55).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "SET ${setCompletati.length + 1}/${esercizio['serie']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Input fields with modern design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Weight input
                  Column(
                    children: [
                      Text(
                        "CARICO (kg)",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E11),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: caricoController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: ultimoCarico,
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Reps input
                  Column(
                    children: [
                      Text(
                        "RIPETIZIONI",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D22),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: ripetizioniController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: ultimaRipetizione,
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            if (setCompletati.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "SET COMPLETATI",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...setCompletati
                  .map(
                    (set) => GestureDetector(
                      onTap: () => _modificaSet(set['set']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              setInModifica == set['set']
                                  ? const Color(0xFFFF2D55).withOpacity(0.2)
                                  : const Color(0xFF1A1D22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                setInModifica == set['set']
                                    ? const Color(0xFFFF2D55)
                                    : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "SET ${set['set']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    setInModifica == set['set']
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              "${set['carico']} kg",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    setInModifica == set['set']
                                        ? Colors.white
                                        : const Color(0xFFFF2D55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${set['ripetizioni']} reps",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    setInModifica == set['set']
                                        ? Colors.white
                                        : const Color(0xFFFF2D55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (setInModifica != set['set'])
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white.withOpacity(0.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // Main action button with gradient
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF2D55), const Color(0xFFFF5C35)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (tuttiSetCompletati &&
                        currentIndex == widget.eserciziGiorno.length - 1) {
                      _completaAllenamento();
                    } else {
                      salvaEPassa();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    setInModifica != null
                        ? "SALVA MODIFICHE"
                        : !tuttiSetCompletati
                        ? "SALVA SET"
                        : currentIndex < widget.eserciziGiorno.length - 1
                        ? "PROSSIMO ESERCIZIO"
                        : "FINISCI ALLENAMENTO",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
