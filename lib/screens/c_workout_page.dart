import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateWorkoutPage extends StatefulWidget {
  @override
  _CreateWorkoutPageState createState() => _CreateWorkoutPageState();
}

class _CreateWorkoutPageState extends State<CreateWorkoutPage> with TickerProviderStateMixin {
  String? _selectedLevel;
  String? _selectedDays;
  String? _selectedGoal;
  String? _selectedFrequency;
  String? _selectedFocus;
  String? _selectedPhase;
  final TextEditingController _notesController = TextEditingController();
  final int _maxNotesLength = 100;
  bool _isGenerating = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _levels = ['Base', 'Medio', 'Avanzato'];
  final List<String> _days = ['2 giorni', '3 giorni', '4 giorni', '5 giorni'];
  final List<String> _goals = ['Forza', 'Ipertrofia', 'Misto'];
  final List<String> _frequencies = ['Monofrequenza', 'Multifrequenza'];
  final List<String> _focusAreas = [
    'Tutto il corpo',
    'Petto',
    'Schiena',
    'Spalle',
    'Bicipiti',
    'Tricipiti',
    'Quadricipiti',
    'Femorali',
    'Polpacci'
  ];
  final List<String> _phases = ['Massa', 'Definizione', 'Mantenimento'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1D22),
                    Color(0xFF0A0E11).withOpacity(0.8),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  'Crea Allenamento',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Hero Button
                    _buildHeroButton(),
                    const SizedBox(height: 32),
                    
                    // Generation Card
                    _buildGenerationCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF2D55).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.pushNamed(context, '/allenamentoManuale'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'CREA IL TUO ALLENAMENTO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1D22),
            Color(0xFF252932),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genera il tuo allenamento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Personalizza ogni dettaglio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            // Form Fields
            _buildFormSection(),
            
            SizedBox(height: 32),
            
            // Generate Button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(child: _buildModernDropdown(
              label: 'Livello',
              value: _selectedLevel,
              items: _levels,
              icon: Icons.trending_up,
              onChanged: (value) => setState(() => _selectedLevel = value),
            )),
            SizedBox(width: 16),
            Expanded(child: _buildModernDropdown(
              label: 'Giorni/settimana',
              value: _selectedDays,
              items: _days,
              icon: Icons.calendar_today,
              onChanged: (value) => setState(() => _selectedDays = value),
            )),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Row 2
        Row(
          children: [
            Expanded(child: _buildModernDropdown(
              label: 'Obiettivo',
              value: _selectedGoal,
              items: _goals,
              icon: Icons.track_changes,
              onChanged: (value) => setState(() => _selectedGoal = value),
            )),
            SizedBox(width: 16),
            Expanded(child: _buildModernDropdown(
              label: 'Frequenza',
              value: _selectedFrequency,
              items: _frequencies,
              icon: Icons.repeat,
              onChanged: (value) => setState(() => _selectedFrequency = value),
            )),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Row 3
        Row(
          children: [
            Expanded(child: _buildModernDropdown(
              label: 'Focus muscolare',
              value: _selectedFocus,
              items: _focusAreas,
              icon: Icons.accessibility_new,
              onChanged: (value) => setState(() => _selectedFocus = value),
              
            )),
            SizedBox(width: 16),
            Expanded(child: _buildModernDropdown(
              label: 'Fase attuale',
              value: _selectedPhase,
              items: _phases,
              icon: Icons.timeline,
              onChanged: (value) => setState(() => _selectedPhase = value),
            )),
          ],
        ),
        
        SizedBox(height: 24),
        
        // Notes Field
        _buildNotesField(),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  // Continuazione della classe _CreateWorkoutPageState

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFFFF2D55), size: 16),
            SizedBox(width: 8),
            Text(
              label + (isOptional ? ' (opzionale)' : ''),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF0A0E11).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value != null 
                ? Color(0xFFFF2D55).withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF1A1D22),
              style: TextStyle(color: Colors.white, fontSize: 14),
              icon: Container(
                margin: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              hint: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Seleziona',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
              items: items.map((String itemValue) {
                return DropdownMenuItem<String>(
                  value: itemValue,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      itemValue,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, color: Color(0xFFFF2D55), size: 16),
            SizedBox(width: 8),
            Text(
              'Note aggiuntive (opzionale)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF0A0E11).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _notesController.text.isNotEmpty
                ? Color(0xFFFF2D55).withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLength: _maxNotesLength,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Aggiungi dettagli specifici per il tuo allenamento...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            style: TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    bool canGenerate = _canGenerate();
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: canGenerate
          ? LinearGradient(
              colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : LinearGradient(
              colors: [Colors.grey.shade700, Colors.grey.shade600],
            ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: canGenerate
          ? [
              BoxShadow(
                color: Color(0xFFFF2D55).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ]
          : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: canGenerate && !_isGenerating ? _generateWorkout : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGenerating) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'GENERANDO...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ] else ...[
                  Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'GENERA ALLENAMENTO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canGenerate() {
    return _selectedLevel != null &&
        _selectedDays != null &&
        _selectedGoal != null &&
        _selectedFrequency != null &&
        _selectedPhase != null;
  }

  Future<void> _generateWorkout() async {
    setState(() => _isGenerating = true);

    try {
      final userId = await getUserIdFromPrefs();

      if (userId == null) {
        _showErrorSnackBar("Errore: utente non trovato");
        return;
      }

      final workoutData = {
        'userId': userId,
        'level': _selectedLevel,
        'days': _selectedDays,
        'goal': _selectedGoal,
        'frequency': _selectedFrequency,
        'focus': _selectedFocus,
        'phase': _selectedPhase,
        'notes': _notesController.text,
      };

      await _sendWorkoutToServer(workoutData);
      _showSuccessSnackBar("Allenamento generato con successo!");
      
    } catch (e) {
      _showErrorSnackBar("Errore durante la generazione: $e");
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

// Funzioni di utilità (da mettere fuori dalla classe)
Future<void> _sendWorkoutToServer(Map<String, dynamic> workoutData) async {
  final url = Uri.parse('https://trainify-server.onrender.com/api/workout');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(workoutData),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Workout generato: $responseBody');
    } else {
      throw Exception('Errore dal server: ${response.body}');
    }
  } catch (e) {
    throw Exception('Errore durante la richiesta: $e');
  }
}

Future<String?> getUserIdFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user_data');

  if (userJson == null) return null;

  final Map<String, dynamic> userMap = json.decode(userJson);
  return userMap['_id'];
}