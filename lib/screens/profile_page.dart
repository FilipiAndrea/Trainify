import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  final dynamic user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  // Metodo helper per estrarre i dati dall'oggetto user
  dynamic _getUserData(String key) {
    if (user is Map) {
      return (user as Map<String, dynamic>)[key];
    }
    try {
      return user.toMap()[key];
    } catch (e) {
      // Se l'oggetto non ha toMap(), prova ad accedere direttamente alle proprietà
      switch (key) {
        case 'nome':
          return user.nome;
        case 'email':
          return user.email;
        case 'avatarUrl':
          return user.avatarUrl;
        case 'workoutCompletati':
          return user.workoutCompletati;
        case 'streak':
          return user.streak;
        case 'livello':
          return user.livello;
        default:
          return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E11),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profilo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A0E11),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditProfile(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sezione Avatar e Informazioni Base
                  _buildUserHeader(),
                  const SizedBox(height: 30),

                  // Sezione Statistiche
                  _buildStatsSection(),
                  const SizedBox(height: 30),

                  // Sezione Impostazioni
                  _buildSettingsSection(context),
                ],
              ),
            ),
          ),

          // Aggiunta della CustomBottomNavBar
          CustomBottomNavBar(
            currentIndex: 2, // Modificato da 1 a 2 per evidenziare Profilo
            onItemSelected: (index) {
              if (index == 0) {
                // Bottone Crea - Apri la pagina per creare un nuovo allenamento
                Navigator.pushNamed(
                  context,
                  '/create-workout',
                  arguments: {'user': user},
                );
              } else if (index == 1) {
                // Bottone Workout - Torna alla home
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {'user': user},
                );
              } else if (index == 2) {
                // Bottone Profilo - Se siamo già nel profilo, non fare nulla
                if (ModalRoute.of(context)?.settings.name != '/profile') {
                  Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: {'user': user},
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ... (tutti gli altri metodi rimangono invariati)
  Widget _buildUserHeader() {
    final avatarUrl = _getUserData('avatarUrl');
    final nome = _getUserData('nome') ?? 'Utente';
    final email = _getUserData('email') ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl.toString()) : null,
          child:
              avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
        ),
        const SizedBox(height: 20),
        Text(
          nome,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final workoutCompletati = _getUserData('workoutCompletati') ?? 0;
    final streak = _getUserData('streak') ?? 0;
    final livello = _getUserData('livello') ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Workout', workoutCompletati.toString()),
          _buildStatItem('Streak', '$streak 🔥'),
          _buildStatItem('Livello', livello.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IMPOSTAZIONI',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: Icons.edit,
          title: 'Modifica profilo',
          onTap: () => _navigateToEditProfile(context),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.notifications,
          title: 'Notifiche',
          onTap: () => _navigateToNotifications(context),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.security,
          title: 'Privacy',
          onTap: () => _navigateToPrivacy(context),
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(context),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.white.withOpacity(0.1),
      indent: 56,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF2D55),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _confirmLogout(context),
        child: const Text(
          'ESCI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, '/editProfile', arguments: user);
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/notifications', arguments: user);
  }

  void _navigateToPrivacy(BuildContext context) {
    Navigator.pushNamed(context, '/privacy', arguments: user);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D22),
            title: const Text(
              'Conferma uscita',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Sei sicuro di voler uscire dal tuo account?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'ANNULLA',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text(
                  'ESCI',
                  style: TextStyle(color: Color(0xFFFF2D55)),
                ),
                onPressed: () async {
                  // 1. Cancella SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('jwt_token');
                  await prefs.remove('user_id');
                  await prefs.remove('user_data');
                  await prefs.remove('allenamento_today');

                  // 2. Chiudi tutti i route e torna al login
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1215), // Sfondo più scuro
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(icon: Icons.add, label: 'Crea', index: 0),
          _buildNavItem(icon: Icons.fitness_center, label: 'Workout', index: 1),
          _buildNavItem(icon: Icons.person, label: 'Profilo', index: 2),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color:
                isActive
                    ? const Color(0xFFFF2D55)
                    : Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isActive
                      ? const Color(0xFFFF2D55)
                      : Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (isActive)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
