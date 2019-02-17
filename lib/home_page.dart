import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';

import 'package:issue_tracker/notices.dart';
import 'package:issue_tracker/notice_filter.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("home_page");

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Report issue', icon: Icons.report),
  const Choice(title: 'Filter notices', icon: Icons.filter_list),
  const Choice(title: 'My pending reports', icon: Icons.assignment),
  const Choice(title: 'About', icon: Icons.info_outline),
  const Choice(title: 'Sign out', icon: Icons.exit_to_app),
];

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String _uid;
  String _appName = 'Unknown';
  Map<String, dynamic> _filterMap;

  Future<Null> _initPackageState() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _appName = packageInfo.appName;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPackageState();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        logger.fine("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        logger.fine("onLaunch: $message");
        Navigator.of(context)
            .pushNamed('/noticeDetails:${message['notice_id']}');
      },
      onResume: (Map<String, dynamic> message) async {
        logger.fine("onResume: $message");
        Navigator.of(context)
            .pushNamed('/noticeDetails:${message['notice_id']}');
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      logger.fine("Settings registered: $settings");
    });

    _auth.currentUser().then((FirebaseUser currentUser) => setState(() {
          _uid = currentUser.uid;
        }));

    _filterMap = {'option': FilterOption.none};
  }

  Future<void> _reportIssue() async {
    final _result = await Navigator.of(context).pushNamed('/reportIssue');
    if (_result != null && _result) {
      String _text = 'Success! Your issue report has been submitted.';
      if (!await Utilities.internetAvailable()) {
        _text =
            'Your report will be submitted when Internet connectivity is restored.';
      }
      final snackBar = SnackBar(
        content: Text(_text),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  void _logFilterAction() {
    logger.fine('Filter notices: $_filterMap');

    Map<String, dynamic> _eventParams = Map();
    _eventParams[EventPublisher.NOTICE_FILTER_OPTION_PARAM] =
        _filterMap['option'].toString();
    if (_filterMap['option'] == FilterOption.category) {
      _eventParams[EventPublisher.NOTICE_FILTER_CATEGORY_PARAM] =
          _filterMap['category'].toString();
    } else if (_filterMap['option'] == FilterOption.severity) {
      _eventParams[EventPublisher.NOTICE_FILTER_SEVERITY_PARAM] =
          _filterMap['severity'].toString();
    }
    EventPublisher.publishEvent(
      eventName: EventPublisher.NOTICE_FILTER_EVENT,
      eventParams: _eventParams,
    );
  }

  void _filterNotices() {
    NoticeFilterWidget _noticeFilter = NoticeFilterWidget(
      filterMap: _filterMap,
    );
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Filter notices by...'),
          children: <Widget>[
            _noticeFilter,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text('Filter'),
                  onPressed: () {
                    setState(() {
                      _filterMap = _noticeFilter.getSelected();
                    });
                    _logFilterAction();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey)) {
      String _token = await _firebaseMessaging.getToken();
      Firestore.instance
          .collection('/users/$_uid/tokens')
          .document(_token)
          .delete();

      await _auth.signOut();
      await _googleSignIn.signOut();
      Navigator.of(context).pushReplacementNamed('/signIn');

      logger.fine('Signed out of $_appName');
      EventPublisher.publishEvent(
        eventName: EventPublisher.SIGN_OUT_EVENT,
      );
    }
  }

  void _select(Choice choice) {
    switch (choice.title) {
      case 'Report issue':
        logger.fine('Go to Report Issue Screen');
        _reportIssue();
        break;
      case 'Filter notices':
        _filterNotices();
        break;
      case 'My pending reports':
        logger.fine('Go to My Pending Reports Screen');
        Navigator.of(context).pushNamed('/myPendingReports');
        break;
      case 'About':
        logger.fine('Go to About Screen');
        Navigator.of(context).pushNamed('/about');
        break;
      case 'Sign out':
        _signOut();
        break;
      default:
        break;
    }
  }

  Widget _getFilterChip() {
    String _text =
        "Filtered by ${_filterMap['option'].toString().split('.').last}";
    if (_filterMap['option'] == FilterOption.category) {
      _text = "$_text: ${_filterMap['category']}";
    } else if (_filterMap['option'] == FilterOption.severity) {
      _text = "$_text: ${_filterMap['severity']}";
    } else if (_filterMap['option'] == FilterOption.mySubscriptions) {
      _text = "My subscriptions";
    } else if (_filterMap['option'] == FilterOption.reportedByMe) {
      _text = "Reported by me";
    }

    return Chip(
      backgroundColor: Theme.of(context).accentColor,
      label: Text(
        _text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIconColor: Colors.white,
      deleteButtonTooltipMessage: 'Remove filter',
      onDeleted: () {
        setState(() {
          _filterMap = {'option': FilterOption.none};
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Image.asset('assets/icon/icon_small.png'),
        ),
        title: Text(_appName),
        actions: <Widget>[
          IconButton(
            icon: Icon(choices[1].icon),
            tooltip: choices[1].title,
            onPressed: () {
              _select(choices[1]);
            },
          ),
          IconButton(
            icon: Icon(choices[2].icon),
            tooltip: choices[2].title,
            onPressed: () {
              _select(choices[2]);
            },
          ),
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.skip(3).map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _filterMap['option'] != FilterOption.none
              //TODO Remove 'Align' after implementing tabs. See if 'Chip' will center with 'no records found'
              ? Align(
                  alignment: Alignment.center,
                  child: _getFilterChip(),
                )
              : Container(),
          Expanded(
            child: NoticesWidget(
              filterMap: _filterMap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(choices[0].icon),
        tooltip: choices[0].title,
        onPressed: () {
          _select(choices[0]);
        },
      ),
    );
  }
}
