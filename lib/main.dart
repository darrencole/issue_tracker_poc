import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info/package_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:issue_tracker/sign_in.dart';
import 'package:issue_tracker/home_page.dart';
import 'package:issue_tracker/notice_details.dart';
import 'package:issue_tracker/notice_map.dart';
import 'package:issue_tracker/report_issue.dart';
import 'package:issue_tracker/my_pending_reports.dart';
import 'package:issue_tracker/about.dart';
import 'package:issue_tracker/sign_up.dart';
import 'package:issue_tracker/forgot_password.dart';
import 'package:issue_tracker/utilities.dart';

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  final PackageInfo packageInfo = await PackageInfo.fromPlatform();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseUser currentUser = await _auth.currentUser();

  Firestore.instance.settings(timestampsInSnapshotsEnabled: true);

  runApp(App(
    isLoggedIn: currentUser != null,
    appName: packageInfo.appName,
  ));
}

class App extends StatelessWidget {
  App({
    this.isLoggedIn,
    this.appName,
  });

  final bool isLoggedIn;
  final String appName;
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primaryColor: Configurations.THEME_COLOR,
        accentColor: Configurations.THEME_COLOR,
      ),
      navigatorObservers: <NavigatorObserver>[
        observer,
      ],
      home: isLoggedIn ? HomePage() : SignIn(),
      routes: <String, WidgetBuilder>{
        '/signIn': (BuildContext context) => SignIn(),
        '/homePage': (BuildContext context) => HomePage(),
        '/reportIssue': (BuildContext context) => ReportIssue(),
        '/myPendingReports': (BuildContext context) => MyPendingReports(),
        '/about': (BuildContext context) => About(),
        '/signUp': (BuildContext context) => SignUp(),
        '/forgotPassword': (BuildContext context) => ForgotPassword(),
      },
      onGenerateRoute: _getRoute,
    );
  }

  Route<Null> _getRoute(RouteSettings settings) {
    final List<String> path = settings.name.split('/');

    if (path[1].startsWith('noticeDetails:')) {
      final String noticeId = path[1].substring(14);
      return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) => NoticeDetails(noticeId: noticeId));
    }

    if (path[1].startsWith('noticeMap:')) {
      final String noticeId = path[1].substring(10);
      return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) => NoticeMap(noticeId: noticeId));
    }

    return null;
  }
}
