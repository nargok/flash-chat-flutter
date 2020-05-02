import 'package:flutter/material.dart';

class ImageTweetScreen extends StatefulWidget {
  static String id = 'image_tweet_screen';

  @override
  State<StatefulWidget> createState() => _ImageTweetState();

}

class _ImageTweetState extends State {
  TextEditingController _txtController = TextEditingController();

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
              Image.asset('images/logo.png'),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _txtController,
                ),
              ),
              RaisedButton(
                child: Text('ツイートする'),
                onPressed: () {
                  print('画像付きツイート');
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
