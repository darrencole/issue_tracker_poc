import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("home_page");

class NoticesWidget extends StatelessWidget {
  NoticesWidget({
    this.filterMap,
  });

  final Map<String, dynamic> filterMap;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Query _setNoticeStream(var uid) {
    Query _noticeStream = Firestore.instance
        .collection('notices')
        .orderBy('last_updated', descending: true)
        .where('published', isEqualTo: true);

    if (filterMap['option'] == FilterOption.category) {
      _noticeStream =
          _noticeStream.where('category', isEqualTo: filterMap['category']);
    } else if (filterMap['option'] == FilterOption.severity) {
      _noticeStream =
          _noticeStream.where('severity', isEqualTo: filterMap['severity']);
    } else if (filterMap['option'] == FilterOption.reportedByMe) {
      _noticeStream = _noticeStream.where('author', isEqualTo: uid);
    } else if (filterMap['option'] == FilterOption.myPendingReports) {
      _noticeStream = Firestore.instance
          .collection('notices')
          .orderBy('last_updated', descending: true)
          .where('published', isEqualTo: false)
          .where('author', isEqualTo: uid);
    }

    return _noticeStream;
  }

  Widget _getNotice(
    BuildContext context,
    DocumentSnapshot ds,
    bool hasNotification,
  ) {
    return Column(
      children: <Widget>[
        ListTile(
          key: ValueKey(ds.documentID),
          title: Text(
            "${ds['subject']}",
            style: const TextStyle(fontSize: 18.0),
          ),
          // 'last_updated' could be null if user's device is offline
          // and their report has not been posted to the server yet.
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ds['last_updated'] != null
                  ? LastUpdated(
                      lastUpdatedTimestamp: ds['last_updated'],
                    )
                  : Container(),
              Row(
                children: <Widget>[
                  Icon(
                    Configurations.STATUS_TYPES[ds['status']],
                    size: 15.0,
                  ),
                  Text(
                    ds['status'],
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Icon(
            hasNotification ? Icons.fiber_manual_record : null,
            color: Colors.green,
          ),
          onTap: () {
            logger.fine('Display details for notice: ${ds.documentID}');
            Navigator.of(context).pushNamed('/noticeDetails:${ds.documentID}');
          },
        ),
      ],
    );
  }

  Map<String, DocumentSnapshot> _querySnapshotToMap(
      QuerySnapshot querySnapshot) {
    final documentMap = Map<String, DocumentSnapshot>();
    for (DocumentSnapshot documentSnapshot in querySnapshot.documents) {
      documentMap[documentSnapshot.documentID] = documentSnapshot;
    }
    return documentMap;
  }

  List<dynamic> _filterNotices(List noticeSnapshots, Function filter) {
    List<dynamic> _tempList = List();
    for (var _notice in noticeSnapshots) {
      if (filter(_notice)) {
        _tempList.add(_notice);
      }
    }
    return _tempList;
  }

  List<dynamic> _performManualFilters(
    List noticeSnapshots,
    Map<String, DocumentSnapshot> userSubscriptionsMap,
  ) {
    if (filterMap['option'] == FilterOption.mySubscriptions) {
      noticeSnapshots = _filterNotices(
        noticeSnapshots,
        (var _notice) {
          return userSubscriptionsMap[_notice.documentID] != null;
        },
      );
    }
    return noticeSnapshots;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _auth.currentUser().then((FirebaseUser currentUser) {
        return currentUser.uid;
      }),
      builder: (_, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          var _uid = snapshot.data;

          Query _noticeStream = _setNoticeStream(_uid);

          Observable<List<QuerySnapshot>> zipStream = Observable.combineLatest3(
            _noticeStream.snapshots(),
            Firestore.instance
                .collection('userSubscriptions/$_uid/notices')
                .snapshots(),
            Firestore.instance
                .collection('notifications/$_uid/notices')
                .snapshots(),
            (notices, userSubscriptions, userNotifications) =>
                [notices, userSubscriptions, userNotifications],
          );

          return StreamBuilder(
            stream: zipStream,
            builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshots) {
              if (!snapshots.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                List<dynamic> _noticeSnapshots = snapshots.data[0].documents;

                QuerySnapshot _userSubscriptionsSnapshot = snapshots.data[1];
                Map<String, DocumentSnapshot> _userSubscriptionsMap =
                    _querySnapshotToMap(_userSubscriptionsSnapshot);

                QuerySnapshot _userNotificationsSnapshot = snapshots.data[2];
                Map<String, DocumentSnapshot> _userNotificationsMap =
                    _querySnapshotToMap(_userNotificationsSnapshot);

                _noticeSnapshots = _performManualFilters(
                  _noticeSnapshots,
                  _userSubscriptionsMap,
                );

                if (_noticeSnapshots.length != 0) {
                  return ListView.builder(
                    itemCount: _noticeSnapshots.length * 2,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, i) {
                      if (i.isOdd) return Divider();
                      final _index = i ~/ 2;
                      DocumentSnapshot _ds = _noticeSnapshots[_index];
                      return _getNotice(
                        context,
                        _ds,
                        _userNotificationsMap[_ds.documentID] != null,
                      );
                    },
                  );
                } else {
                  return PlaceholderMessage(
                    message: 'No results found.',
                  );
                }
              }
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
