import 'package:flutter/services.dart' show rootBundle;
import 'package:oauth1/oauth1.dart';
import 'package:oauth1/oauth1.dart' as oauth1;

Future<String> loadConfig() async {
  return rootBundle.loadString('assets/config.json');
}

oauth1.Client getClient(String consumerKey, String consumerSecret,
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
