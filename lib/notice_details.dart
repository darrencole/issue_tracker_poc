import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("notice_details");

class NoticeDetails extends StatelessWidget {
  NoticeDetails({
    this.noticeId,
  });

  final String noticeId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _removeNotification(String uid) {
    DocumentReference _dr = Firestore.instance
        .collection('notifications/$uid/notices')
        .document(noticeId);
    _dr.delete();
  }

  Future<void> _handleClickLocationButton(
    BuildContext context,
    String subject,
  ) async {
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey)) {
      Navigator.of(context).pushNamed('/noticeMap:$noticeId');
      logger.fine('Location button pressed for notice: $noticeId');
      EventPublisher.publishEvent(
        eventName: EventPublisher.NOTICE_LOCATION_EVENT,
        eventParams: <String, dynamic>{
          EventPublisher.NOTICE_SUBJECT_PARAM: subject,
          EventPublisher.NOTICE_ID_PARAM: noticeId,
        },
      );
    }
  }

  void _handleClickNoticeSubscription(
    String uid,
    bool subscribe,
    String subject,
  ) {
    String _status;
    String _eventName;
    final _subscriptionDr = Firestore.instance
        .collection('subscriptions/$noticeId/users')
        .document(uid);
    final _userSubscriptionDr = Firestore.instance
        .collection('userSubscriptions/$uid/notices')
        .document(noticeId);

    if (subscribe) {
      _subscriptionDr.setData({
        'timestamp': FieldValue.serverTimestamp(),
      });
      _userSubscriptionDr.setData({
        'timestamp': FieldValue.serverTimestamp(),
      });
      _status = Constants.CHECKED;
      _eventName = EventPublisher.NOTICE_SUBSCRIBE_EVENT;
    } else {
      _subscriptionDr.delete();
      _userSubscriptionDr.delete();
      _status = Constants.UNCHECKED;
      _eventName = EventPublisher.NOTICE_UNSUBSCRIBE_EVENT;
    }

    logger.fine('Subscription checkbox $_status for notice: $noticeId');
    EventPublisher.publishEvent(
      eventName: _eventName,
      eventParams: <String, dynamic>{
        EventPublisher.NOTICE_SUBJECT_PARAM: subject,
        EventPublisher.NOTICE_ID_PARAM: noticeId,
      },
    );
  }

  Widget _getSubscriptionSection(
    BuildContext context,
    String uid,
    String subject,
    DocumentSnapshot subscriptionSnapshot,
  ) {
    return CheckboxListTile(
      title: const Text('Send me notifications when this issue is updated.'),
      value: subscriptionSnapshot.exists,
      onChanged: (bool value) {
        _handleClickNoticeSubscription(uid, value, subject);
      },
      secondary: Icon(
        Icons.add_alert,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _getBody(String uid) {
    Observable<List<DocumentSnapshot>> zipStream = Observable.combineLatest2(
      Firestore.instance.collection('notices').document(noticeId).snapshots(),
      Firestore.instance
          .collection('subscriptions/$noticeId/users')
          .document(uid)
          .snapshots(),
      (notice, subscription) => [notice, subscription],
    );

    return StreamBuilder(
      stream: zipStream,
      builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshots) {
        if (!snapshots.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          DocumentSnapshot _noticeSnapshot = snapshots.data[0];
          if (_noticeSnapshot.exists) {
            DocumentSnapshot _subscriptionSnapshot = snapshots.data[1];
            return Container(
              padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
              child: ListView(
                children: <Widget>[
                  Text(
                    '${_noticeSnapshot['subject']}',
                    style: Theme.of(context).textTheme.display1,
                  ),
                  // 'last_updated' could be null if user's device is offline
                  // and their report has not been posted to the server yet.
                  _noticeSnapshot['last_updated'] != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LastUpdated(
                            lastUpdatedTimestamp:
                                _noticeSnapshot['last_updated'],
                          ),
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: <Widget>[
                        Text('Status:'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: Icon(
                            Configurations
                                .STATUS_TYPES[_noticeSnapshot['status']],
                            size: 15.0,
                          ),
                        ),
                        Text(_noticeSnapshot['status']),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text('Category: ${_noticeSnapshot['category']}'),
                  ),
                  _noticeSnapshot['severity'] != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: <Widget>[
                              Text('Severity:'),
                              Icon(
                                Icons.stop,
                                color: Configurations.SEVERITY_TYPES[
                                    _noticeSnapshot['severity']],
                              ),
                              Text(_noticeSnapshot['severity']),
                            ],
                          ),
                        )
                      : Container(),
                  _noticeSnapshot['location'] != null
                      ? Row(
                          children: <Widget>[
                            Text('Location:'),
                            IconButton(
                              icon: Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'Location',
                              onPressed: () => _handleClickLocationButton(
                                    context,
                                    _noticeSnapshot['subject'],
                                  ),
                            )
                          ],
                        )
                      : Container(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 25.0),
                    child: Text(
                      "${_noticeSnapshot['description']}",
                      style: TextStyle(
                        fontSize: 17.0,
                      ),
                      softWrap: true,
                    ),
                  ),
                  Divider(),
                  _getSubscriptionSection(
                    context,
                    uid,
                    _noticeSnapshot['subject'],
                    _subscriptionSnapshot,
                  ),
                  Divider(),
                ],
              ),
            );
          } else {
            return Align(
              alignment: Alignment.topCenter,
              child: PlaceholderMessage(
                message: 'This notice has been removed.',
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Details'),
      ),
      body: FutureBuilder(
        future: FirebaseAuth.instance.currentUser(),
        builder: (_, AsyncSnapshot<FirebaseUser> snapshot) {
          if (snapshot.hasData) {
            String _uid = snapshot.data.uid;
            _removeNotification(_uid);
            return _getBody(_uid);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
