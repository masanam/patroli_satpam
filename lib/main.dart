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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error;
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
      title: 'Police Patrol App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
        // ... Add other routes
      },
    );
  }
}
