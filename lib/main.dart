import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:police_patrol_app/views/chat_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/command_center_page.dart';
import 'package:police_patrol_app/views/dashboard_page.dart';
import 'package:police_patrol_app/views/login_page.dart';
import 'package:police_patrol_app/views/map_page.dart';
import 'package:police_patrol_app/views/registration_page.dart';
import 'package:police_patrol_app/views/report_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:police_patrol_app/firebase_options.dart';
import 'package:police_patrol_app/views/report_view_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/incident-management-page.dart';
import 'package:police_patrol_app/viewsCommandCenter/incident_dashboard_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/officer_monitoring_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/resource-management-page.dart';
import 'package:police_patrol_app/viewsCommandCenter/data_analytics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    firebaseError = error;
    debugPrint('Firebase.initializeApp failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(PolicePatrolApp(firebaseError: firebaseError));
}

class PolicePatrolApp extends StatelessWidget {
  final Object? firebaseError;

  const PolicePatrolApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase belum dikonfigurasi untuk platform ini.\n\n'
                '$firebaseError',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return GetMaterialApp(
      title: 'Patroli App',
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF163B56),
          primary: const Color(0xFF163B56),
          secondary: const Color(0xFF2B7A9A),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF5F7FA),
          foregroundColor: Color(0xFF172B3A),
          titleTextStyle: TextStyle(
            color: Color(0xFF172B3A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD7E0E8))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD7E0E8))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2B7A9A), width: 2)),
          labelStyle: const TextStyle(color: Color(0xFF526879)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        )),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        )),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172B3A)),
          titleLarge: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172B3A)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF34495A)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF526879)),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/dashboard': (context) => DashboardPage(),
        '/chat': (context) => ChatPage(),
        '/map': (context) => MapPage(),
        '/report': (context) => ReportPage(
              patrolRouteId: '',
            ),
        '/reportView': (context) => ReportViewPage(),
        '/commandCenter': (context) => CommandCenterPage(),
        '/resourceManagement': (context) => ResourceManagementPage(),
        '/incidentDashboard': (context) => IncidentDashboardPage(),
        '/officerMonitoring': (context) => OfficerMonitoringPage(),
        '/incidentManagement': (context) => IncidentManagementPage(),
        '/dataAnalytics': (context) => const DataAnalyticsPage(),
        // ... Add other routes
      },
    );
  }
}
