import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:oauth1/oauth1.dart';

class TwitterLoginScreen extends StatefulWidget {
  static String id = 'twitter_login_screen';

  @override
  State<StatefulWidget> createState() => TwitterLoginState();
}

class TwitterLoginState extends State {
  static String twitterConsumerKey = 'YOUR-API-KEY';
  static String twitterConsumerSecret = 'YOUR-API-SECRET';

  static final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret);
  static final _auth = FirebaseAuth.instance;

  String _message = 'Logged out';
  String sessionToken;
  String sessionSecret;

  void _login() async {
    final TwitterLoginResult result = await twitterLogin.authorize();
    String newMessage;

    switch (result.status) {
      case TwitterLoginStatus.loggedIn:
        newMessage = 'Logged in! username: ${result.session.username}';
        final AuthCredential credential = TwitterAuthProvider.getCredential(
            authToken: result.session.token,
            authTokenSecret: result.session.secret);
        final user = await _auth.signInWithCredential(credential);
        sessionToken = result.session.token;
        sessionSecret = result.session.secret;
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
    await _auth.signOut();

    setState(() {
      _message = 'Logged out';
    });
  }

  void _tweet() async {
    print('pushed tweet button');
    TwitterSession session = await twitterLogin.currentSession;

    Client client = _getClient(twitterConsumerKey, twitterConsumerSecret,
        session.token, session.secret);

    client
        .get('https://api.twitter.com/1.1/statuses/home_timeline.json?count=1')
        .then((res) {
      print(res.body);
    });
  }

  static oauth1.Client _getClient(String consumerKey, String consumerSecret,
      String accessToken, String accessSecret) {
    return oauth1.Client(
        oauth1.Platform(
                'https://api.twitter.com/oauth/request_token',
                'https://api.twitter.com/oauth/authorize',
                'https://api.twitter.com/oauth/access_token',
                oauth1.SignatureMethods.hmacSha1)
            .signatureMethod,
        oauth1.ClientCredentials(consumerKey, consumerSecret),
        Credentials(accessToken, accessSecret));
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
              ),
              RaisedButton(
                child: Text('ツイートする'),
                color: Colors.lightBlue,
                onPressed: _tweet,
              )
            ],
          ),
        ),
      ),
    );
  }
}
