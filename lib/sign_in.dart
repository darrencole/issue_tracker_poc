import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import 'package:issue_tracker/custom_widgets.dart';
import 'package:issue_tracker/utilities.dart';

final Logger logger = Logger("sign_in");

class SignIn extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

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
  }

  bool _validationPassed(String email, String password) {
    setState(() {
      _errorMessage = '';
      if (email == null || email == '') {
        _errorMessage = 'Email required. ';
      }
      if (password == null || password == '') {
        _errorMessage = '${_errorMessage}Password required.';
      }
    });

    return _errorMessage == '';
  }

  void _handleInvalidCredentials(Exception e) {
    setState(() {
      _errorMessage = 'Invalid email or password entered.';
    });
    logger.warning(e);
  }

  void _handleValidSignIn(
      FirebaseUser user, String signInType, String eventName) {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

    if (user != null) {
      if (user.isEmailVerified) {
        logger.fine(user);
        _firebaseMessaging.getToken().then((token) {
          logger.fine('Device Token: $token');
          Firestore.instance
              .collection('/users/${user.uid}/tokens')
              .document(token)
              .setData({
            'timestamp': FieldValue.serverTimestamp(),
          });
        });
        Navigator.of(context).pushReplacementNamed('/homePage');
        logger.fine('Signed in with $signInType');
        EventPublisher.publishEvent(
          eventName: eventName,
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password entered.';
        });
      }
    }
  }

  Future<FirebaseUser> _handleSignInWithEmailAndPassword() async {
    FirebaseUser user;
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey) &&
        _validationPassed(
          _emailController.text,
          _passwordController.text,
        )) {
      user = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    return user;
  }

  Future<FirebaseUser> _handleGoogleSignIn() async {
    if (await Utilities.checkInternetAvailability(scaffoldKey: _scaffoldKey)) {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      FirebaseUser user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return user;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _signInForm = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            hintText: 'Password',
          ),
          obscureText: true,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 15.0,
                  ),
                  softWrap: true,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/forgotPassword');
                },
              ),
              RaisedButton(
                child: Text('Sign in'),
                onPressed: () {
                  _handleSignInWithEmailAndPassword()
                      .then((FirebaseUser user) => _handleValidSignIn(
                            user,
                            'email and password',
                            EventPublisher.SIGN_IN_WITH_EMAIL_EVENT,
                          ))
                      .catchError((e) => _handleInvalidCredentials(e));
                },
              ),
            ],
          ),
        ),
        RaisedButton(
          child: Text('Sign in with Google'),
          onPressed: () {
            _handleGoogleSignIn()
                .then((FirebaseUser user) => _handleValidSignIn(
                      user,
                      'Google',
                      EventPublisher.SIGN_IN_WITH_GOOGLE_EVENT,
                    ))
                .catchError((e) => logger.warning(e));
          },
        ),
      ],
    );

    Widget _signUpSection = Container(
      padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 15.0,
            ),
            softWrap: true,
          ),
          InkWell(
            child: Text(
              'Sign up!',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 15.0,
                decoration: TextDecoration.underline,
              ),
              softWrap: true,
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/signUp');
            },
          ),
        ],
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(32.0, 4.0, 32.0, 32.0),
        child: ListView(
          children: <Widget>[
            ErrorMessageSection(
              errorMessage: _errorMessage,
            ),
            _signInForm,
            _signUpSection,
          ],
        ),
      ),
    );
  }
}
