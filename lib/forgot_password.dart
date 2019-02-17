import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("forgot_password");

class ForgotPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage;
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _errorMessage = '';
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  bool _validationPassed(String email) {
    setState(() {
      _errorMessage = '';
      if (email == null || email == '') {
        _errorMessage = 'Email required. ';
      }
    });

    return _errorMessage == '';
  }

  Future<bool> _handlePasswordReset() async {
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey) &&
        _validationPassed(_emailController.text)) {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      logger.fine('Sent password reset email');
      EventPublisher.publishEvent(
        eventName: EventPublisher.RESET_PASSWORD_EVENT,
      );
      return true;
    }
    return false;
  }

  void _handleInvalidEmail(Exception e) {
    setState(() {
      _errorMessage = 'Invalid email entered.';
    });
    logger.warning(e);
  }

  void _handleValidReset() {
    Utilities.showVerificationMessage(
      context: context,
      title: 'Password Reset Email Sent',
      message:
          'An email was sent to your email address. Open the email and follow the instructions to reset your password.',
      redirect: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _resetPasswordForm() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
            child: Text(
              '''Enter your email address then press "Submit".''',
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 15.0),
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
            ),
          ),
          RaisedButton(
            child: Text('Submit'),
            onPressed: () {
              _handlePasswordReset().then((success) {
                if (success) {
                  _handleValidReset();
                }
              }).catchError((e) => _handleInvalidEmail(e));
            },
          ),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(32.0, 4.0, 32.0, 32.0),
        child: ListView(
          children: <Widget>[
            ErrorMessageSection(
              errorMessage: _errorMessage,
            ),
            Subtitle(
              text: 'Reset Password',
            ),
            _resetPasswordForm(),
          ],
        ),
      ),
    );
  }
}
