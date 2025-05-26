import 'package:flutter/material.dart';
import 'package:trainify/screens/cMan_workout_page.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/c_workout_page.dart';
import 'screens/today_workout_page.dart';
import 'screens/active_workout_page.dart';
import 'screens/profile_page.dart';
import 'utils/check_login.dart';
import 'screens/workout_selection_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(TrainifyApp());

class TrainifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: [Locale('en', 'US'), Locale('it', 'IT')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Trainify',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060E15),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/allenamento': (context) => CreateWorkoutPage(),
        '/allenamentoManuale' : (context) => ManualWorkoutCreationPage(),
        '/workoutSelection': (context) => WorkoutSelectionPage(),
        '/workoutOggi': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TodayWorkoutPage(user: args['user']);
        },
        '/activeWorkout': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ActiveWorkoutPage(
            eserciziGiorno: args['eserciziGiorno'],
            eserciziCompleti: args['eserciziCompleti'],
          );
        },
        '/profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>; // Ricevi l'oggetto direttamente
          return ProfilePage(user: args['user']);
        },
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    bool isLogged = await AuthService.isLoggedIn();

    if (isLogged) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}