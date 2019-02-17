import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("report_issue");

class IssueSubmissionForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IssueSubmissionFormState();
}

class IssueSubmissionFormState extends State<IssueSubmissionForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _latitudeController = TextEditingController();
  TextEditingController _longitudeController = TextEditingController();
  bool _showErrorMessage;
  String _uid;
  String _errorMessage;
  String _category;
  LocationFormWidget _locationFormWidget;
  ImageSubmissionWidget _imageSubmissionWidget;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Utilities.checkInternetAvailability(context: context));

    _auth.currentUser().then((FirebaseUser currentUser) => setState(() {
          _uid = currentUser.uid;
        }));

    _showErrorMessage = false;
    _errorMessage = null;

    _category = null;

    _locationFormWidget = LocationFormWidget(
      latitudeController: _latitudeController,
      longitudeController: _longitudeController,
    );

    _imageSubmissionWidget = ImageSubmissionWidget(
      limit: Configurations.IMAGES_LIMIT,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
  }

  bool _validReport() {
    if (_category == null) {
      setState(() {
        _errorMessage = 'Please select a category.';
        _showErrorMessage = true;
      });
    }
    return _formKey.currentState.validate() && _category != null;
  }

  void _handleSubmitReport() {
    //Get new noticeId
    final _noticeId =
        Firestore.instance.collection('notices').document().documentID;

    //Package report
    var _report = {
      'author': _uid,
      'category': _category,
      'date_reported': FieldValue.serverTimestamp(),
      'description': _descriptionController.text,
      'last_updated': FieldValue.serverTimestamp(),
      'published': false,
      'status': Configurations.PENDING_INVESTIGATION,
      'subject': _subjectController.text,
    };

    //Add location Geopoint if required
    if (_locationFormWidget.includeLocation()) {
      _report['location'] = GeoPoint(
        double.parse(_latitudeController.text),
        double.parse(_longitudeController.text),
      );
    }

    //Post report to Firebase
    Firestore.instance.document('notices/$_noticeId').setData(_report);

    //Subscribe author to the new notice
    Firestore.instance
        .document('subscriptions/$_noticeId/users/$_uid')
        .setData({'timestamp': FieldValue.serverTimestamp()});
    Firestore.instance
        .document('userSubscriptions/$_uid/notices/$_noticeId')
        .setData({'timestamp': FieldValue.serverTimestamp()});

    logger.fine('Issue reported');
    EventPublisher.publishEvent(
      eventName: EventPublisher.REPORT_ISSUE_EVENT,
      eventParams: <String, dynamic>{
        EventPublisher.NOTICE_SUBJECT_PARAM: _subjectController.text,
        EventPublisher.NOTICE_ID_PARAM: _noticeId,
      },
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    Widget _buttonBar = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        RaisedButton(
          child: Text('Clear Form'),
          onPressed: () {
            setState(() {
              _category = null;
            });
            _subjectController.clear();
            _descriptionController.clear();
            _locationFormWidget.reset();
            _imageSubmissionWidget.clear();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: RaisedButton(
            child: Text('Submit'),
            onPressed: () {
              if (_validReport()) {
                _handleSubmitReport();
              }
            },
          ),
        ),
      ],
    );

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.fromLTRB(32.0, 0.0, 32.0, 32.0),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: Subtitle(
                text: 'Report an issue:',
              ),
            ),
            _showErrorMessage
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 12.0,
                        ),
                        softWrap: true,
                      ),
                    ],
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Category',
                    //ToDo Implement custom theme and use "color: Theme.of(context).accentTextTheme.caption.color",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  DropdownButton(
                    items: Configurations.NOTICE_CATEGORIES
                        .map((String dropDownItem) {
                      return DropdownMenuItem(
                        value: dropDownItem,
                        child: Text(dropDownItem),
                      );
                    }).toList(),
                    value: _category,
                    hint: Text('Please select a category'),
                    onChanged: (String value) {
                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            TextFormField(
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a subject';
                }
              },
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Subject',
              ),
            ),
            TextFormField(
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a description';
                }
              },
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description',
              ),
              maxLines: 4,
            ),
            _locationFormWidget,
            _imageSubmissionWidget,
            _buttonBar,
          ],
        ),
      ),
    );
  }
}

class ReportIssue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Issue'),
      ),
      body: IssueSubmissionForm(),
    );
  }
}
