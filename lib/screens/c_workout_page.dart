import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  // Variabili per memorizzare le selezioni
  int? giorniAllenamento;
  int? livello;
  String? gruppoMuscolare;
  String? obiettivo = 'Massa';
  String? frequenza = 'Multifrequenza';

  // Mostra dialog informativo sulla frequenza
  void _showFrequenzaInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Frequenza Allenamento'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Monofrequenza: Allenare ogni gruppo muscolare 1 volta a settimana'),
            SizedBox(height: 8),
            Text('• Multifrequenza: Allenare ogni gruppo muscolare 2+ volte a settimana'),
            SizedBox(height: 8),
            Text('La multifrequenza è generalmente più efficace per la crescita muscolare.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Genera l'allenamento in base alle selezioni
  void _generaAllenamento(BuildContext context) {
    if (livello == null || gruppoMuscolare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona tutte le opzioni')),
      );
      return;
    }
    
    final messaggio = '''
    Allenamento generato con:
    - Obiettivo: $obiettivo
    - Frequenza: $frequenza
    - Giorni: ${giorniAllenamento ?? 3}
    - Livello: ${livello == 1 ? 'Base' : livello == 2 ? 'Intermedia' : 'Avanzato'}
    - Focus: ${gruppoMuscolare ?? 'Tutti i gruppi'}
    ''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allenamento Generato'),
        content: Text(messaggio),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definizione delle competenze
    final competenze = [
      Competenza(1, 'Base'),
      Competenza(2, 'Intermedia'),
      Competenza(3, 'Avanzato'),
    ];

    // Definizione dei gruppi muscolari
    final gruppiMuscolari = [
      'Petto',
      'Schiena',
      'Gambe',
      'Braccia',
      'Spalle',
      'Polpacci',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Planner'),
        backgroundColor: const Color(0xFF060E15),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sezione Obiettivo (Massa/Definizione)
            const Text(
              'Qual è il tuo obiettivo principale?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Massa'),
                    selected: obiettivo == 'Massa',
                    onSelected: (selected) {
                      setState(() {
                        obiettivo = 'Massa';
                      });
                    },
                    selectedColor: Colors.redAccent,
                    labelStyle: TextStyle(
                      color: obiettivo == 'Massa' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Definizione'),
                    selected: obiettivo == 'Definizione',
                    onSelected: (selected) {
                      setState(() {
                        obiettivo = 'Definizione';
                      });
                    },
                    selectedColor: Colors.redAccent,
                    labelStyle: TextStyle(
                      color: obiettivo == 'Definizione' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sezione Frequenza (Monofrequenza/Multifrequenza)
            Row(
              children: [
                const Text(
                  'Tipo di frequenza:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showFrequenzaInfo(context),
                  tooltip: 'Informazioni sulla frequenza',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Monofrequenza'),
                    selected: frequenza == 'Monofrequenza',
                    onSelected: (selected) {
                      setState(() {
                        frequenza = 'Monofrequenza';
                      });
                    },
                    selectedColor: Colors.redAccent,
                    labelStyle: TextStyle(
                      color: frequenza == 'Monofrequenza' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Multifrequenza'),
                    selected: frequenza == 'Multifrequenza',
                    onSelected: (selected) {
                      setState(() {
                        frequenza = 'Multifrequenza';
                      });
                    },
                    selectedColor: Colors.redAccent,
                    labelStyle: TextStyle(
                      color: frequenza == 'Multifrequenza' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Seleziona giorni allenamento
            const Text(
              'Giorni di allenamento a settimana:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: giorniAllenamento ?? 3,
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: index + 3,
                  child: Text('${index + 3} giorni'),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  giorniAllenamento = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Minimo 3 giorni',
              ),
            ),
            const SizedBox(height: 20),

            // Seleziona livello
            const Text(
              'Livello attuale:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: livello,
              items: competenze.map((c) => DropdownMenuItem<int>(
                value: c.value,
                child: Text(c.label),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  livello = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleziona il tuo livello',
              ),
            ),
            const SizedBox(height: 20),

            // Seleziona gruppo muscolare
            const Text(
              'Focus muscolare:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: gruppoMuscolare,
              items: gruppiMuscolari.map((gruppo) => DropdownMenuItem(
                value: gruppo,
                child: Text(gruppo),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  gruppoMuscolare = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleziona un gruppo',
              ),
            ),
            const SizedBox(height: 30),

            // Bottone Genera
            Center(
              child: ElevatedButton(
                onPressed: () => _generaAllenamento(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'GENERA ALLENAMENTO',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Competenza {
  final int value;
  final String label;

  Competenza(this.value, this.label);
}