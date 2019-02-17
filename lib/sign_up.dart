import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("sign_up");

class SignUp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _errorMessage = '';
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  bool _validationPassed(
      String email, String password, String confirmPassword) {
    setState(() {
      _errorMessage = '';
      if (email == null || email == '') {
        _errorMessage = 'Email required. ';
      }
      if (password == null || password == '') {
        _errorMessage = '${_errorMessage}Password required. ';
      }
      if (confirmPassword == null || confirmPassword == '') {
        _errorMessage = '${_errorMessage}Password confirmation required.';
      }
      if (_errorMessage == '' && password != confirmPassword) {
        _errorMessage = 'Password and Confirmed Password do not match.';
      }
    });

    return _errorMessage == '';
  }

  void _handleExceptions(Exception e) {
    final List<String> message = e.toString().split(',');
    setState(() {
      _errorMessage = message[1].substring(1);
    });
    logger.warning(e);
  }

  Future<FirebaseUser> _handleCreateUserWithEmailAndPassword() async {
    FirebaseUser user;
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey) &&
        _validationPassed(
          _emailController.text,
          _passwordController.text,
          _confirmPasswordController.text,
        )) {
      user = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      logger.fine('Created new account');
      EventPublisher.publishEvent(
        eventName: EventPublisher.SIGN_UP_EVENT,
      );
    }

    return user;
  }

  void _sendEmailVerification(FirebaseUser user) async {
    if (user != null) {
      logger.fine(user);
      user.sendEmailVerification();
      Utilities.showVerificationMessage(
        context: context,
        title: 'Verification Email Sent',
        message:
            'An email was sent to your email address. Open the email and click on the link provided to complete the sign-up process.',
        redirect: () {
          Navigator.of(context).pop();
        },
      );
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _signUpForm() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 15.0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Choose a password',
                  ),
                  obscureText: true,
                ),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    hintText: 'Confirm password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          RaisedButton(
            child: Text('Submit'),
            onPressed: () {
              _handleCreateUserWithEmailAndPassword()
                  .then((FirebaseUser user) => _sendEmailVerification(user))
                  .catchError((e) => _handleExceptions(e));
            },
          ),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(32.0, 4.0, 32.0, 32.0),
        child: ListView(
          children: <Widget>[
            ErrorMessageSection(
              errorMessage: _errorMessage,
            ),
            Subtitle(
              text: 'Create account:',
            ),
            _signUpForm(),
          ],
        ),
      ),
    );
  }
}
