import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/image_tweet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:oauth1/oauth1.dart';
import 'dart:async' show Future;
import 'dart:convert';

Future<String> loadConfig() async {
  return rootBundle.loadString('assets/config.json');
}

class TwitterLoginScreen extends StatefulWidget {
  static String id = 'twitter_login_screen';

  @override
  State<StatefulWidget> createState() => TwitterLoginState();
}

class TwitterLoginState extends State {
  static String twitterConsumerKey;
  static String twitterConsumerSecret;

  static final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret);
  static final _auth = FirebaseAuth.instance;
  static final _txtController = new TextEditingController();

  String _message = 'Logged out';
  String sessionToken;
  String sessionSecret;
  bool isPosted = false;

  @override
  void initState() {
    loadConfig().then((t) {
      final config = json.decode(t);
      twitterConsumerKey = config['twitter_consumer_key'];
      twitterConsumerSecret = config['twitter_consumer_secret'];
    });
    super.initState();
  }

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

  _showSnackBar(BuildContext context) {
    final _snackBar = SnackBar(
      content: Text('ツイートしました!'),
      action: SnackBarAction(
        label: 'とじる',
        onPressed: () {
          Scaffold.of(context).removeCurrentSnackBar();
        },
      ),
      duration: Duration(seconds: 3),
    );
    Scaffold.of(context).showSnackBar(_snackBar);
  }

  Future<bool> _tweet() async {
    print('pushed tweet button');
    TwitterSession session = await twitterLogin.currentSession;

    Client client = _getClient(twitterConsumerKey, twitterConsumerSecret,
        session.token, session.secret);

    String status = _txtController.text;

    Map<String, String> body = {'status': '$status'};

    final res = await client
        .post('https://api.twitter.com/1.1/statuses/update.json', body: body);

    _txtController.clear();

    if (res.statusCode == 200) {
      return true;
    } else {
      return false;
    }
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
    return Scaffold(
      appBar: new AppBar(
        title: Text('Twitter login page'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(50.0),
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
                  TextField(
                    controller: _txtController,
                    decoration: InputDecoration(hintText: 'What\'s happning?'),
                  ),
                  RaisedButton(
                    child: Text('ツイートする'),
                    color: Colors.lightBlue,
                    onPressed: () async {
                      bool isTweeted = await _tweet();
                      print('tweet status is: $isTweeted');
                      if (isTweeted) {
                        _showSnackBar(context);
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text('画像付きツイートする'),
                    color: Colors.blueAccent,
                    onPressed: () {
                      print('画像付きツイートをする');
                      Navigator.pushNamed(context, ImageTweetScreen.id);
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
