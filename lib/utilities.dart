import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:intl/intl.dart';

enum FilterOption {
  none,
  category,
  severity,
  mySubscriptions,
  reportedByMe,
  myPendingReports,
}

class Constants {
  static const String CHECKED = 'checked';
  static const String UNCHECKED = 'unchecked';
  static const int NO_LIMIT = -9999;
  static const double DEFAULT_SIZE = -9999.0;
}

class Configurations {
  static const Color THEME_COLOR = Color(0xFF25215e);
  static const String PENDING_INVESTIGATION = 'pending investigation';
  static const double UPPER_LATITUDE = 11.4;
  static const double LOWER_LATITUDE = 10.03;
  static const double UPPER_LONGITUDE = -60.52;
  static const double LOWER_LONGITUDE = -61.94;
  static const int MIN_FILE_LENGTH = 100;
  static const int IMAGES_LIMIT = 10;

  static const Map<String, dynamic> STATUS_TYPES = {
    'pending investigation': Icons.find_in_page,
    'in progress': Icons.hourglass_empty,
    'resolved': Icons.done,
    'informational': Icons.announcement,
    'closed': Icons.block,
    'duplicate': Icons.content_copy,
  };

  static const List<String> NOTICE_CATEGORIES = [
    'road works',
    'traffic lights',
    'natural disasters',
    'other',
  ];

  static const Map<String, dynamic> SEVERITY_TYPES = {
    'red': Colors.red,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'yellow': Colors.yellow,
    'green': Colors.green,
  };
}

class EventPublisher {
  static const String NOTICE_FILTER_EVENT = "notice_filter";
  static const String NOTICE_LOCATION_EVENT = "notice_location";
  static const String NOTICE_SUBSCRIBE_EVENT = "notice_subscribe";
  static const String NOTICE_UNSUBSCRIBE_EVENT = "notice_unsubscribe";
  static const String REPORT_ISSUE_EVENT = "report_issue";
  static const String SIGN_UP_EVENT = "sign_up";
  static const String SIGN_IN_WITH_EMAIL_EVENT = "sign_in_with_email";
  static const String SIGN_IN_WITH_GOOGLE_EVENT = "sign_in_with_google";
  static const String RESET_PASSWORD_EVENT = "send_password_reset_email";
  static const String SIGN_OUT_EVENT = "sign_out";

  static const String NOTICE_SUBJECT_PARAM = "notice_subject";
  static const String NOTICE_ID_PARAM = "notice_id";
  static const String NOTICE_FILTER_OPTION_PARAM = "notice_filter_option";
  static const String NOTICE_FILTER_CATEGORY_PARAM = "notice_filter_category";
  static const String NOTICE_FILTER_SEVERITY_PARAM = "notice_filter_severity";

  static Future<Null> publishEvent({
    String eventName,
    Map<String, dynamic> eventParams,
  }) async {
    if (eventParams == null) {
      await FirebaseAnalytics().logEvent(
        name: eventName,
      );
    } else {
      await FirebaseAnalytics()
          .logEvent(name: eventName, parameters: eventParams);
    }
  }
}

class Utilities {
  static String lastReportedFormat(DateTime lastUpdated) {
    Duration lastReported = DateTime.now().difference(lastUpdated);

    if (lastReported.inMinutes < 3) {
      return 'Just now';
    }
    if (lastReported.inMinutes < 30) {
      return 'A few minutes ago';
    }
    if (lastReported.inMinutes < 60) {
      return 'About half hour ago';
    }
    if (lastReported.inHours < 2) {
      return 'About an hour ago';
    } else {
      //Month Date, Year hh:mm AM/PM eg: October 1, 2018 2:30 PM
      return DateFormat('MMMM d, y', 'en_US').add_jm().format(lastUpdated);
    }
  }

  static Future<bool> internetAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return (result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> checkInternetAvailability({
    GlobalKey<ScaffoldState> scaffoldKey,
    BuildContext context,
  }) {
    return internetAvailable().then((bool _isAvailable) {
      if (!_isAvailable) {
        final snackBar = SnackBar(content: Text('No Internet connection.'));
        if (scaffoldKey != null) {
          scaffoldKey.currentState.showSnackBar(snackBar);
        } else if (context != null) {
          Scaffold.of(context).showSnackBar(snackBar);
        }
      }
      return _isAvailable;
    });
  }

  static void showVerificationMessage({
    BuildContext context,
    String title,
    String message,
    Function redirect,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                if (redirect != null) {
                  redirect();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
