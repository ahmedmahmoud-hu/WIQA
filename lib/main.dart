import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'controllers/language_controller.dart';

import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/auth_choice_screen.dart'; // 👈 استيراد جديد
import 'screens/main/main_navigation_screen.dart';


// تعريف الـ routeObserver كمتغير عام لحل الخطأ في HomeScreen
final RouteObserver routeObserver = RouteObserver();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  
  final String? token = prefs.getString('jwt_token');

  Widget initialScreen;
  if (!hasSeenOnboarding) {
    initialScreen = const WelcomeScreen(); 
  } else if (token != null && token.isNotEmpty) {
    initialScreen = const MainNavigationScreen();
  } else {
    initialScreen = const AuthChoiceScreen(); // 👈 بدل LoginScreen
  }
  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen; 

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WIQA',
          locale: languageController.locale, 
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          
          // تسجيل الـ routeObserver هنا ليعمل على مستوى التطبيق بالكامل
          navigatorObservers: [routeObserver],
          
          theme: ThemeData(
            primarySwatch: Colors.blue,
            // fontFamily: 'Cairo', 
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/auth-choice': (context) => const AuthChoiceScreen(), // 👈 لو حبيت تستخدمه كـ named route كمان
          },
          
          home: initialScreen, 
        );
      },
    );
  }
}