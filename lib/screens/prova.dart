/*import 'package:flutter/material.dart';
import 'package:trainify/screens/today_workout_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String nomeUtente = args['user']['nome']?.split(' ').first ?? 'Atleta';
    final int streakCount = args['user']['streak'] ?? 5;

    final dynamic user = args['user'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      body: Column(
        children: [
          // Header con gradiente e contenuto
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1D22).withOpacity(0.8),
                  const Color(0xFF0A0E11).withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Benvenuto e streak counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bentornato,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomeUtente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Streak counter con effetto fiamma
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF5C35)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$streakCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Card motivazionale
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Allenamento di oggi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Completa il tuo workout per mantenere lo streak!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.fitness_center,
                          color: Color(0xFFFF2D55), size: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Corpo centrale con pulsanti
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bottone ALLENATI OGGI
                  _WorkoutButton(
                    title: "ALLENATI OGGI",
                    subtitle: "Inizia il workout programmato",
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFFFF2D55),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TodayWorkoutPage(user: args['user']),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bottone FREESTYLE
                  _WorkoutButton(
                    title: "FREESTYLE",
                    subtitle: "Crea il tuo allenamento",
                    icon: Icons.tune,
                    color: Colors.transparent,
                    borderColor: const Color(0xFFFF2D55),
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigator.push per freestyle
                    },
                  ),
                ],
              ),
            ),
          ),

          // Versione completa con gestione del tap sull'icona home
          _CustomBottomNavBar(
            currentIndex: 0,
            onItemSelected: (index) {
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {'user': user},
                );
              }
              else if (index == 1) {
                Navigator.pushNamed(
                  context,
                  '/progressi',
                  arguments: {'user': user},
                );
              }
              else if (index == 2) {
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: {'user': user},
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Componente pulsante workout riutilizzabile
class _WorkoutButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _WorkoutButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.borderColor = Colors.transparent,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: color,
      elevation: color == Colors.transparent ? 0 : 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color == Colors.transparent
                      ? const Color(0xFFFF2D55).withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: textColor.withOpacity(0.7), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra di navigazione personalizzata
class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.fitness_center,
            label: 'Workout',
            isActive: currentIndex == 0,
            onPressed: () => onItemSelected(0),
          ),
          _NavButton(
            icon: Icons.bar_chart,
            label: 'Progressi',
            isActive: currentIndex == 1,
            onPressed: () => onItemSelected(1),
          ),
          _NavButton(
            icon: Icons.person,
            label: 'Profilo',
            isActive: currentIndex == 2,
            onPressed: () => onItemSelected(2),
          ),
        ],
      ),
    );
  }
}

// Pulsante di navigazione singolo
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 28,
            color: isActive
                ? const Color(0xFFFF2D55)
                : Colors.white.withOpacity(0.5),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFFFF2D55)
                : Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}*/