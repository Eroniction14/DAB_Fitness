import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import './pages/home_page.dart';
import './pages/login_page.dart';
import './pages/signup_page.dart';
import './pages/splashscreen.dart';
import './pages/trainer_page.dart';
import './pages/trainerhome_page.dart';
import './pages/training_page.dart';
import './pages/videodetail_page.dart';
import './pages/welcome_page.dart';
import './provider/auth_model.dart';
import './provider/booking_model.dart';
import './provider/database_model.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Auth()),
        ChangeNotifierProvider(create: (_) => DataBase()),
        ChangeNotifierProxyProvider<Auth, Booking>(
          create: (_) => Booking(null, null),
          update: (_, auth, __) => Booking(auth.token, auth.userId),
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
        home: SplashScreen(),
        routes: {
          WelcomePage.routeName: (_) => WelcomePage(),
          LoginPage.routeName: (_) => LoginPage(),
          SignUpPage.routeName: (_) => SignUpPage(),
          TrainerPage.routeName: (_) => TrainerPage(),
          HomePage.routeName: (_) => HomePage(),
          TrainingPage.routeName: (_) => TrainingPage(),
          VideoDetail.routeName: (_) => VideoDetail(),
          TrainerHome.routeName: (_) => TrainerHome(),
        },
      ),
    );
  }
}