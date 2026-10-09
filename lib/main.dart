import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/screens/home/home_page.dart';
import 'package:dab_fitness/screens/onboarding/splash_screen.dart';
import 'package:dab_fitness/screens/onboarding/welcome_page.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_home_page.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/screens/training/training_page.dart';
import 'package:dab_fitness/screens/training/video_detail_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel()),
        ChangeNotifierProvider(create: (_) => DatabaseModel()),
        ChangeNotifierProxyProvider<AuthModel, BookingModel>(
          create: (_) => BookingModel(null, null),
          update: (_, auth, __) => BookingModel(auth.token, auth.userId),
        ),
      ],
      child: MaterialApp(
        title: 'DAB Fitness',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
              .copyWith(secondary: Colors.blue.shade400, surface: Colors.white),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.grey,
          ),
          textTheme: TextTheme(
            displayLarge: GoogleFonts.openSans(
                color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold),
            displayMedium: GoogleFonts.openSans(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            displaySmall: GoogleFonts.openSans(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            headlineMedium: GoogleFonts.openSans(
                color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
            headlineSmall: GoogleFonts.openSans(
                color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
            titleMedium: GoogleFonts.lato(
                color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
            bodyLarge: GoogleFonts.openSans(
                color: Colors.grey, fontSize: 20, fontWeight: FontWeight.w400),
            bodyMedium: GoogleFonts.lato(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w400),
            labelLarge: GoogleFonts.roboto(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w400),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          WelcomePage.routeName: (_) => WelcomePage(),
          LoginPage.routeName: (_) => LoginPage(),
          SignUpPage.routeName: (_) => SignUpPage(),
          TrainerListPage.routeName: (_) => TrainerListPage(),
          HomePage.routeName: (_) => HomePage(),
          TrainingPage.routeName: (_) => TrainingPage(),
          VideoDetailPage.routeName: (_) => VideoDetailPage(),
          TrainerHomePage.routeName: (_) => TrainerHomePage(),
        },
      ),
    );
  }
}