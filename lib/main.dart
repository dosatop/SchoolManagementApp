import 'package:app/Pages/auth_pages/login_or_sign_up.dart';
import 'package:app/Pages/auth_pages/login_page.dart';
import 'package:app/Pages/auth_pages/sign_up_page.dart';
import 'package:app/Pages/dashboard_page.dart';
import 'package:app/Pages/onboarding/first_screen.dart';
import 'package:app/Providers/academic_tile_provider.dart';
import 'package:app/Providers/auth_provider.dart';
import 'package:app/Providers/user_provider.dart';
import 'package:app/Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => UserProvider(ApiService())),
        ChangeNotifierProvider(create: (_) => AcademicTileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.exo2TextTheme(
          // Theme.of(context).textTheme,
        ),
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        // colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 128, 143, 229)),
      ),
      home: const FirstScreen(),
      routes: {
        'firstScreen': (context) => const FirstScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/signUp': (context) => SignUpPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/loginOrSignUp':
            final isLogin = settings.arguments as bool? ?? true;

            return MaterialPageRoute(
              builder: (_) => LoginOrSignUp(isLogin: isLogin),
            );

          default:
            return null;
        }
      },
    );
  }
}
