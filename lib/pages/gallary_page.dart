import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart';

class GalleryPage extends StatefulWidget {
  final String imagePath;
  GalleryPage({this.imagePath});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            color: Colors.red,
            child: PhotoView(
              imageProvider: NetworkImage(widget.imagePath),
            ),
          ),
          Container(
            height: 80,
            child: AppBar(
              backgroundColor: Color.fromRGBO(0, 0, 0, 0.2),
              elevation: 0.0,
            ),
          ),
        ],
      ),
    );
  }
}
