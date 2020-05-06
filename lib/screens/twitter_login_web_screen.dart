import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:oauth1/oauth1.dart';

class TwitterLoginWebScreen extends StatefulWidget {
  final twitterPlatform = Platform(
    'https://api.twitter.com/oauth/request_token',
    // temporary credentials request
    'https://api.twitter.com/oauth/authorize', // resource owner authorization
    'https://api.twitter.com/oauth/access_token', // token credentials request
    SignatureMethods.hmacSha1, // signature method
  );

  final ClientCredentials clientCredentials;
  final String oauthCallbackHandler;

  TwitterLoginWebScreen({
    @required final String consumerKey,
    @required final String consumerSecret,
    @required this.oauthCallbackHandler,
  }) : clientCredentials = ClientCredentials(consumerKey, consumerSecret);

  @override
  State<StatefulWidget> createState() => _TwitterLoginState();
}

class _TwitterLoginState extends State<TwitterLoginWebScreen> {
  final flutterWebPlugin = FlutterWebviewPlugin();

  Authorization _oauth;

  @override
  void initState() {
    super.initState();

    // initialize Twitter OAuth
    _oauth = Authorization(widget.clientCredentials, widget.twitterPlatform);

    flutterWebPlugin.onUrlChanged.listen((url) {
      if (url.startsWith(widget.oauthCallbackHandler)) {
        final queryParameters = Uri
            .parse(url)
            .queryParameters;
        final oauthToken = queryParameters['oauth_token'];
        final oauthVerifier = queryParameters['oauth_verifier'];
        if (null != oauthToken && null != oauthVerifier) {
          // todo loginFinish
          _twitterLoginFinish(oauthToken, oauthVerifier);
        }
      }
    });

    // Login start
    _twitterLoginStart();
  }

  @override
  void dispose() {
    flutterWebPlugin.dispose();
    super.dispose();
  }

  Future<void> _twitterLoginStart() async {
    assert(null != _oauth);
    // Step1 Request Token
    final requestTokenResponse =
    await _oauth.requestTemporaryCredentials(widget.oauthCallbackHandler);

    // Step2 Redirect to Authorization Page
    final authorizationPage = _oauth.getResourceOwnerAuthorizationURI(
        requestTokenResponse.credentials.token);
    flutterWebPlugin.launch(authorizationPage);
  }

  Future<void> _twitterLoginFinish(String oauthToken,
      String oauthVerifier) async {
    // Step3 Request Access Token
    final tokenCredentialsResponse = await _oauth.requestTokenCredentials(
        Credentials(oauthToken, ""), oauthVerifier);

    final result = TwitterAuthProvider.getCredential(
        authToken: tokenCredentialsResponse.credentials.token,
        authTokenSecret: tokenCredentialsResponse.credentials.tokenSecret,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(title: Text("Twitter Login")),
      url: "https://twitter.com",
    );
  }
}
