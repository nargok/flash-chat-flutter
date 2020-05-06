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

oauth1.Authorization getAuthorization(
  String consumerKey,
  String consumerSecret,
) {
  return oauth1.Authorization(
      oauth1.ClientCredentials(consumerKey, consumerSecret),
      oauth1.Platform(
          'https://api.twitter.com/oauth/request_token',
          'https://api.twitter.com/oauth/authorize',
          'https://api.twitter.com/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1));
}

/* 署名作成
  1. キーの作成
  2. データの作成
  3. キーとデータを署名に変換する
*/
class AuthorizationHeader {
  final SignatureMethod _signatureMethod;
  final ClientCredentials _clientCredentials;
  final Credentials _credentials;
  final String _method;
  final String _url;
  final Map<String, String> _additionalParameters;

  AuthorizationHeader(this._signatureMethod, this._clientCredentials,
      this._credentials, this._method, this._url, this._additionalParameters);

  @override
  String toString() {
    final Map<String, String> params = <String, String>{};

    params['oauth_nonce'] = DateTime.now().millisecondsSinceEpoch.toString();
    params['oauth_signature_method'] = _signatureMethod.name;
    params['oauth_timestamp'] =
        (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
    params['oauth_consumer_key'] = _clientCredentials.token;
    params['oauth_version'] = '1.0';
    if (_credentials != null) {
      params['oauth_token'] = _credentials.token;
    }
    params.addAll(_additionalParameters);
    if (!params.containsKey('oauth_signature')) {
      params['oauth_signature'] = _createSignature(_method, _url, params);
    }

    final String authHeader = 'OAuth ' +
        params.keys.map((String k) {
          return '$k="${Uri.encodeComponent(params[k])}"';
        }).join(', ');
    return authHeader;
  }

  String _createSignature(
      String method, String url, Map<String, String> params) {
    if (params.isEmpty) {
      throw ArgumentError('params is empty.');
    }
    final Uri uri = Uri.parse(url);

    // 1. Percent encode every key and value
    //    that will be signed.
    final Map<String, String> encodedParams = <String, String>{};
    params.forEach((String k, String v) {
      encodedParams[Uri.encodeComponent(k)] = Uri.encodeComponent(v);
    });
    uri.queryParameters.forEach((String k, String v) {
      encodedParams[Uri.encodeComponent(k)] = Uri.encodeComponent(v);
    });
    params.remove('realm');

    // 2. Sort the list of parameters alphabetically[1]
    //    by encoded key[2].
    final List<String> sortedEncodedKeys = encodedParams.keys.toList()..sort();

    // 3. For each key/value pair:
    // 4. Append the encoded key to the output string.
    // 5. Append the '=' character to the output string.
    // 6. Append the encoded value to the output string.
    // 7. If there are more key/value pairs remaining,
    //    append a '&' character to the output string.
    final String baseParams = sortedEncodedKeys.map((String k) {
      return '$k=${encodedParams[k]}';
    }).join('&');

    //
    // Creating the signature base string
    //

    final StringBuffer base = StringBuffer();
    // 1. Convert the HTTP Method to uppercase and set the
    //    output string equal to this value.
    base.write(method.toUpperCase());

    // 2. Append the '&' character to the output string.
    base.write('&');

    // 3. Percent encode the URL origin and path, and append it to the
    //    output string.
    base.write(Uri.encodeComponent(uri.origin + uri.path));

    // 4. Append the '&' character to the output string.
    base.write('&');

    // 5. Percent encode the parameter string and append it
    //    to the output string.
    base.write(Uri.encodeComponent(baseParams.toString()));

    //
    // Getting a signing key
    //

    // The signing key is simply the percent encoded consumer
    // secret, followed by an ampersand character '&',
    // followed by the percent encoded token secret:
    final String consumerSecret =
        Uri.encodeComponent(_clientCredentials.tokenSecret);
    final String tokenSecret = _credentials != null
        ? Uri.encodeComponent(_credentials.tokenSecret)
        : '';
    final String signingKey = '$consumerSecret&$tokenSecret';

    //
    // Calculating the signature
    //
    return _signatureMethod.sign(signingKey, base.toString());
  }
}

class AuthorizationHeaderBuilder {
  SignatureMethod _signatureMethod;
  ClientCredentials _clientCredentials;
  Credentials _credentials;
  String _method;
  String _url;
  Map<String, String> _additionalParameters;

  AuthorizationHeaderBuilder();

  AuthorizationHeaderBuilder.from(AuthorizationHeaderBuilder other)
      : _signatureMethod = other._signatureMethod,
        _clientCredentials = other._clientCredentials,
        _credentials = other._credentials,
        _method = other._method,
        _url = other._url,
        _additionalParameters = other._additionalParameters;

  set signatureMethod(SignatureMethod value) => _signatureMethod = value;

  set clientCredentials(ClientCredentials value) => _clientCredentials = value;

  set credentials(Credentials value) => _credentials = value;

  set method(String value) => _method = value;

  set url(String value) => _url = value;

  set additionalParameters(Map<String, String> value) =>
      _additionalParameters = value;

  AuthorizationHeader build() {
    if (_signatureMethod == null) {
      throw StateError('signatureMethod is not set');
    }
    if (_clientCredentials == null) {
      throw StateError('clientCredentials is not set');
    }
    if (_method == null) {
      throw StateError('method is not set');
    }
    if (_url == null) {
      throw StateError('url is not set');
    }

    return AuthorizationHeader(_signatureMethod, _clientCredentials,
        _credentials, _method, _url, _additionalParameters);
  }
}
