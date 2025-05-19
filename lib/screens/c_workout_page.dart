import 'package:flutter/material.dart';

class CreateWorkoutPage extends StatefulWidget {
  @override
  _CreateWorkoutPageState createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> {
  String? _selectedLevel;
  String? _selectedDays;
  String? _selectedGoal;
  String? _selectedFrequency;
  String? _selectedFocus;
  String? _selectedPhase;
  final TextEditingController _notesController = TextEditingController();
  final int _maxNotesLength = 20;

  final List<String> _levels = ['Base', 'Medio', 'Avanzato'];
  final List<String> _days = ['2 giorni', '3 giorni', '4 giorni', '5 giorni'];
  final List<String> _goals = ['Forza', 'Ipertrofia', 'Misto'];
  final List<String> _frequencies = ['Monofrequenza', 'Multifrequenza'];
  final List<String> _focusAreas = [
    'Tutto il corpo',
    'Upper Body',
    'Lower Body',
    'Push/Pull/Legs',
    'Addome'
  ];
  final List<String> _phases = ['Massa', 'Definizione', 'Mantenimento'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        title: const Text('Crea Allenamento'),
        backgroundColor: const Color(0xFF060E15),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bottone principale
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/allenamentoManuale');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CREA IL TUO ALLENAMENTO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card di generazione
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D22),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genera il tuo allenamento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Personalizza il tuo allenamento inserendo le seguenti informazioni:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Livello di esperienza
                  _buildDropdown(
                    label: 'Livello',
                    value: _selectedLevel,
                    items: _levels,
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Giorni di allenamento
                  _buildDropdown(
                    label: 'Giorni a settimana',
                    value: _selectedDays,
                    items: _days,
                    onChanged: (value) {
                      setState(() {
                        _selectedDays = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Obiettivo
                  _buildDropdown(
                    label: 'Obiettivo principale',
                    value: _selectedGoal,
                    items: _goals,
                    onChanged: (value) {
                      setState(() {
                        _selectedGoal = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Frequenza
                  _buildDropdown(
                    label: 'Frequenza',
                    value: _selectedFrequency,
                    items: _frequencies,
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Focus muscolare
                  _buildDropdown(
                    label: 'Focus muscolare (facoltativo)',
                    value: _selectedFocus,
                    items: _focusAreas,
                    onChanged: (value) {
                      setState(() {
                        _selectedFocus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fase
                  _buildDropdown(
                    label: 'Fase attuale',
                    value: _selectedPhase,
                    items: _phases,
                    onChanged: (value) {
                      setState(() {
                        _selectedPhase = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Note aggiuntive
                  TextField(
                    controller: _notesController,
                    maxLength: _maxNotesLength,
                    decoration: InputDecoration(
                      labelText: 'Note aggiuntive (facoltativo, max $_maxNotesLength caratteri)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      counterStyle: TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bottone genera
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canGenerate() ? _generateWorkout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'GENERA ALLENAMENTO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E11).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1D22),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              hint: Text(
                'Seleziona',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  bool _canGenerate() {
    return _selectedLevel != null &&
        _selectedDays != null &&
        _selectedGoal != null &&
        _selectedFrequency != null &&
        _selectedPhase != null;
  }

  void _generateWorkout() {
    // Qui implementerai la logica per generare l'allenamento
    final workoutData = {
      'level': _selectedLevel,
      'days': _selectedDays,
      'goal': _selectedGoal,
      'frequency': _selectedFrequency,
      'focus': _selectedFocus,
      'phase': _selectedPhase,
      'notes': _notesController.text,
    };

    print(workoutData); // Per debug
    // Navigator.push per andare alla pagina con l'allenamento generato
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}