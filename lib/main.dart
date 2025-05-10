import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/c_workout_page.dart';
import 'screens/today_workout_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(TrainifyApp());

class TrainifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('it', 'IT'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Trainify',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060E15),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/allenamento': (context) => WorkoutPage(),
        '/workoutOggi': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TodayWorkoutPage(user: args['user']);
        },
      },
    );
  }
}
