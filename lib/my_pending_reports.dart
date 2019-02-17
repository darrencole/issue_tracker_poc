import 'package:flutter/material.dart';

import 'package:issue_tracker/notices.dart';
import 'package:issue_tracker/utilities.dart';

class MyPendingReports extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pending Reports'),
      ),
      body: NoticesWidget(
        filterMap: {'option': FilterOption.myPendingReports},
      ),
    );
  }
}
