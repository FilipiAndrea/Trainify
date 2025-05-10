import 'package:flutter/material.dart';

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
        title: const Text('Profilo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF060E15),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditProfile(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildUserHeader() {
    final avatarUrl = _getUserData('avatarUrl');
    final nome = _getUserData('nome') ?? 'Utente';
    final email = _getUserData('email') ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: avatarUrl != null 
              ? NetworkImage(avatarUrl.toString()) 
              : null,
          child: avatarUrl == null 
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
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
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _confirmLogout(context),
        child: const Text(
          'ESCI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/editProfile',
      arguments: user,
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/notifications',
      arguments: user,
    );
  }

  void _navigateToPrivacy(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/privacy',
      arguments: user,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text('ANNULLA', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('ESCI', style: TextStyle(color: Color(0xFFFF2D55))),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/login'));
            },
          ),
        ],
      ),
    );
  }
}