import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageTweetScreen extends StatefulWidget {
  static String id = 'image_tweet_screen';

  @override
  State<StatefulWidget> createState() => _ImageTweetState();

}

class _ImageTweetState extends State {
  File _imageFile;
  TextEditingController _txtController = TextEditingController();

  Future _getImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = image;
    });
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
              _imageFile == null ? new Text("no image selected") : new Image
                  .file(_imageFile),
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
