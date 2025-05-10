import 'package:flutter/material.dart';

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
        final index = setCompletati.indexWhere((s) => s['set'] == setInModifica);
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

        if (currentSet < widget.eserciziGiorno[currentIndex]['serie']) {
          currentSet++;
        }
      }

      // Aggiorna risultati completi
      risultati = setCompletati.map((set) => {
        'id_esercizio': widget.eserciziGiorno[currentIndex]['id_esercizio'],
        ...set,
      }).toList();

      ripetizioniController.clear();
      caricoController.clear();

      // Se abbiamo completato tutti i set
      if (setCompletati.length == widget.eserciziGiorno[currentIndex]['serie'] &&
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

  void _completaAllenamento() {
    print('Risultati allenamento:');
    print(risultati);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Allenamento completato!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
    Navigator.pop(context, risultati);
  }

  void _modificaSet(int numeroSet) {
    final set = setCompletati.firstWhere((s) => s['set'] == numeroSet);
    setState(() {
      setInModifica = numeroSet;
      caricoController.text = set['carico'];
      ripetizioniController.text = set['ripetizioni'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final esercizio = widget.eserciziGiorno[currentIndex];
    final dettagli = widget.eserciziCompleti[esercizio['id_esercizio']] ?? {};
    final nome = dettagli['nome'] ?? 'Esercizio sconosciuto';
    final tuttiSetCompletati = setCompletati.length == esercizio['serie'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: Text(
          "Esercizio ${currentIndex + 1}/${widget.eserciziGiorno.length}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D22),
        elevation: 0,
        actions: [
          if (tuttiSetCompletati && currentIndex < widget.eserciziGiorno.length - 1)
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
            // Exercise name with decorative elements
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
              ...setCompletati.map((set) => GestureDetector(
                onTap: () => _modificaSet(set['set']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: setInModifica == set['set'] 
                      ? const Color(0xFFFF2D55).withOpacity(0.2)
                      : const Color(0xFF1A1D22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: setInModifica == set['set']
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
                          color: setInModifica == set['set']
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        "${set['carico']} kg",
                        style: TextStyle(
                          fontSize: 16,
                          color: setInModifica == set['set']
                            ? Colors.white
                            : const Color(0xFFFF2D55),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${set['ripetizioni']} reps",
                        style: TextStyle(
                          fontSize: 16,
                          color: setInModifica == set['set']
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
              )).toList(),
              const SizedBox(height: 24),
            ],
            
            // Current set section
            if (!tuttiSetCompletati) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          controller: caricoController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: "0.0",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                            hintText: "0",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            
            const Spacer(),
            
            // Main action button with gradient
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF2D55),
                      const Color(0xFFFF5C35),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (tuttiSetCompletati && currentIndex == widget.eserciziGiorno.length - 1) {
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
                    setInModifica != null ? "SALVA MODIFICHE" :
                    !tuttiSetCompletati ? "SALVA SET" : 
                    currentIndex < widget.eserciziGiorno.length - 1 ? 
                      "PROSSIMO ESERCIZIO" : "FINISCI ALLENAMENTO",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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