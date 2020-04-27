import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_twitter/flutter_twitter.dart';

class TwitterLoginScreen extends StatefulWidget {
  static String id = 'twitter_login_screen';

  @override
  State<StatefulWidget> createState() => TwitterLoginState();
}

class TwitterLoginState extends State {
  static final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: 'YOUR-API-KEY', consumerSecret: 'YOUR-API-SECRET-KEY');

  String _message = 'Logged out';

  void _login() async {
    final TwitterLoginResult result = await twitterLogin.authorize();
    String newMessage;

    switch (result.status) {
      case TwitterLoginStatus.loggedIn:
        newMessage = 'Logged in! username: ${result.session.username}';
        break;
      case TwitterLoginStatus.cancelledByUser:
        newMessage = 'Login cancelled by user';
        break;
      case TwitterLoginStatus.error:
        newMessage = 'Login error: ${result.errorMessage}';
        break;
    }
    setState(() {
      _message = newMessage;
    });
  }

  void _logout() async {
    await twitterLogin.logOut();

    setState(() {
      _message = 'Logged out';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: new AppBar(
          title: Text('Twitter login page'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_message),
              RaisedButton(
                child: Text('Login'),
                onPressed: _login,
              ),
              RaisedButton(
                child: Text('Log out'),
                onPressed: _logout,
              )
            ],
          ),
        ),
      ),
    );
  }
}
