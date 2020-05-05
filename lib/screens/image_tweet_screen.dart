import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:oauth1/oauth1.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import '../common.dart';
import 'dart:convert';
import 'package:http/http.dart';
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

  // todo 画像を登録する処理 => media_id
  Future<String> _putImageFile(oauth1.Client client, String filepath) async {
//    List<int> imageBytes = await image.readAsBytes();
//    print(imageBytes);
//    final imageBase64 = base64Encode(imageBytes);
//    print(imageBase64);
//
//    Map<String, String> body = {'media_data': imageBase64};

    // todo 結構はまっている...
    // todo ためしてみる httpパッケージでシンプルにマルチpartリクエストしてみる
    // todo 認証が云々寒雲とか言われたら、oauth1からトークンだけ取得する方法を考える

//
    final uri = Uri.parse('http://192.168.0.105:3000/upload'); // todo 一時的にlocalhostへ通信
//    final req = http.MultipartRequest("POST", uri)
//      ..fields['media_data'] = imageBase64
//      ..headers['Content-Transfer-Encoding'] = "base64";

    final req = http.MultipartRequest("POST", uri);
    req.files.add(await http.MultipartFile.fromPath('picture', filepath));
    final response = await req.send();
    print(response);

//    final res = await client.post(mediaEndpoint,
//      headers: {
//        "Content-Transfer-Encoding": "base64",
//        "Content-type": "application/x-www-form-urlencoded",
//      },
//      body: body,
//    ).catchError((e) {
//      print(e);
//    });

//    print(res.body);

    return 'aaaaa';
  }

  // todo 本文を投稿する処理
  Future<bool> _tweet() async {
    TwitterSession session = await twitterLogin.currentSession;

    final client = getClient(twitterConsumerKey, twitterConsumerSecret,
        session.token, session.secret);

    print('token is :' + session.token);
    print('secret is :' + session.secret);

    final mediaId = await _putImageFile(client, _imageFile.path);

    Map<String, String> body = {
      'status': _txtController.text,
      'media_id': mediaId,
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
