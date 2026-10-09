import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/firebase_options.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/screens/onboarding/splash_screen.dart';
import 'package:dab_fitness/screens/onboarding/welcome_page.dart';
import 'package:dab_fitness/screens/profile/profile_page.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/screens/shell/trainer_shell.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/screens/training/training_page.dart';
import 'package:dab_fitness/screens/training/video_detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel()),
        ChangeNotifierProvider(create: (_) => DatabaseModel()),
        ChangeNotifierProxyProvider<AuthModel, BookingModel>(
          create: (_) => BookingModel(null),
          // Only start fresh when a different account signs in.
          update: (_, auth, previous) => previous?.userId == auth.userId
              ? previous!
              : BookingModel(auth.userId),
        ),
      ],
      child: MaterialApp(
        title: 'DAB Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          WelcomePage.routeName: (_) => WelcomePage(),
          LoginPage.routeName: (_) => LoginPage(),
          SignUpPage.routeName: (_) => SignUpPage(),
          TrainerListPage.routeName: (_) => TrainerListPage(),
          UserShell.routeName: (_) => const UserShell(),
          TrainingPage.routeName: (_) => TrainingPage(),
          VideoDetailPage.routeName: (_) => VideoDetailPage(),
          TrainerShell.routeName: (_) => const TrainerShell(),
          ProfilePage.routeName: (_) => const ProfilePage(),
        },
      ),
    );
  }
}
