import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:oauth1/oauth1.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import '../common.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageTweetScreen extends StatefulWidget {
  static String id = 'image_tweet_screen';

  @override
  State<StatefulWidget> createState() => _ImageTweetState();
}

class _ImageTweetState extends State {
  static String baseUrl = 'https://api.twitter.com/1.1/';
  static String tweetEndpoint = 'statuses/update.json';
  static String mediaEndpoint =
      'https://upload.twitter.com/1.1/media/upload.json';
  static String twitterConsumerKey;
  static String twitterConsumerSecret;
  oauth1.Client client;

  static final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret);

  File _imageFile;
  TextEditingController _txtController = TextEditingController();

  @override
  void initState() {
    loadConfig().then((t) {
      final config = json.decode(t);
      twitterConsumerKey = config['twitter_consumer_key'];
      twitterConsumerSecret = config['twitter_consumer_secret'];
    });
    super.initState();
  }

  Future _getImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = image;
    });
  }

  // 画像を登録する処理
  Future<String> _putImageFile(
      oauth1.ClientCredentials clientCredentials,
      oauth1.Credentials credentials,
      oauth1.Client client,
      String filepath) async {

    final signature = getSignature(
        oauth1.Platform(
                'https://api.twitter.com/oauth/request_token',
                'https://api.twitter.com/oauth/authorize',
                'https://api.twitter.com/oauth/access_token',
                oauth1.SignatureMethods.hmacSha1)
            .signatureMethod,
        clientCredentials,
        credentials,
        'POST',
        mediaEndpoint);

    debugPrint(signature);

    final uri = Uri.parse(mediaEndpoint);
    final req = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] = signature;
    req.files.add(await http.MultipartFile.fromPath('media', filepath));

    try {
      final response = await req.send();
      final rawRes = await response.stream.bytesToString();
      final res = json.decode(rawRes);
      return res['media_id_string'];
    } catch(e) {
      print(e);
      throw HttpException('Image post to twitter was failed.');
    }
  }

  // 本文を投稿する処理
  Future<bool> _tweet() async {
    TwitterSession session = await twitterLogin.currentSession;

    final client = getClient(twitterConsumerKey, twitterConsumerSecret,
        session.token, session.secret);

    final clientCredentials =
        ClientCredentials(twitterConsumerKey, twitterConsumerSecret);
    final credentials = Credentials(session.token, session.secret);
    final mediaId = await _putImageFile(
        clientCredentials, credentials, client, _imageFile.path);

    Map<String, String> body = {
      'status': _txtController.text,
      'media_ids': mediaId,
    };

    final res = await client.post(baseUrl + tweetEndpoint, body: body);
    if (res.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('画像付きツイート'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(50.0),
          width: 400.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _imageFile == null
                  ? new Text("no image selected")
                  : new Image.file(_imageFile),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _txtController,
                ),
              ),
              RaisedButton(
                child: Text('画像を選択する'),
                onPressed: () {
                  print('画像を選択する');
                  _getImage();
                },
              ),
              RaisedButton(
                child: Text('ツイートする'),
                onPressed: () async {
                  print('画像付きツイート');
                  final isPosted = await _tweet();
                  if (isPosted) {
                    print('ツイートしました');
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
