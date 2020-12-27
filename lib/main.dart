import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';


void main() {
  runApp(MaterialApp(home: CanvasPainting()));
}

class CanvasPainting extends StatefulWidget {
  @override
  _CanvasPaintingState createState() => _CanvasPaintingState();
}

class _CanvasPaintingState extends State<CanvasPainting> {
  GlobalKey globalKey = GlobalKey();

  List<TouchPoints> points = List();
  File _image;
  int height = 0;
  int width = 0;
  GlobalKey _keyImage = GlobalKey();
  String text = 'Loading...';
  final picker = ImagePicker();

  _showAlertDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      title: Center(child: Text(text)),
      actions: <Widget>[
        new FlatButton(
          child: new Text("Copy"),
          onPressed: () {Clipboard.setData(new ClipboardData(text: text));},
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future _getText() async {
    String coordinates = "0,0,${height},${width}";
    var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://georgian101.herokuapp.com/api/v1/extract_text"));
    request.fields['coordinates'] = coordinates;
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image.path,
    ));

    request.send().then((result) async {
      http.Response.fromStream(result)
          .then((response) {
        if (response.statusCode == 200)
        {
          Map mapJson = json.decode(utf8.decode(response.bodyBytes));
          print(mapJson["text"]);
          setState(() {
            text= mapJson["text"];
          });
          _showAlertDialog(context);
        }
      });
    }).catchError((err) => print('error : '+err.toString()))
        .whenComplete(()
    {});
  }

  Future _getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery, maxHeight: 650);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      var decodedImage = await decodeImageFromList(_image.readAsBytesSync());
      width= decodedImage.width;
      height= decodedImage.height;
      print(width);
      print(height);
    }
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        print('_image: $_image');
      } else {
        print('No image selected');
      }
    });
  }

  _onTapDown(TapDownDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    // or user the local position method to get the offset
    print(details.localPosition);
    print("tap down " + x.toString() + ", " + y.toString());
  }

  _onTapUp(TapUpDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    // or user the local position method to get the offset
    print(details.localPosition);
    print("tap up " + x.toString() + ", " + y.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: RepaintBoundary(
            key: globalKey,
            child: Center(
              child: Container(
                key: _keyImage,
                width: width.toDouble(),
                height: height.toDouble(),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _image == null
                        ? MemoryImage(kTransparentImage)
                        : FileImage(_image),
                  ),
                ),
                child:
                GestureDetector(
                  onTapDown: (details) {
                    setState(() {
                      RenderBox renderBox = context.findRenderObject();
                      points.add(TouchPoints(
                          points: renderBox.globalToLocal(details.localPosition),));
                    });
                  },
                  child:                     CustomPaint(
                    size: Size.infinite,
                    painter: MyPainter(
                      pointsList: points,
                    ),
                  ),
                ),
                ),
              ),
            ),
        floatingActionButton: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                  heroTag: "erase",
                  child: Icon(Icons.clear),
                  tooltip: "Erase",
                  onPressed: () {
                    setState(() {
                      points.clear();
                    });
                  }),
              SizedBox(height: 5),
              FloatingActionButton(
                onPressed: () async{await _getImage();},
                tooltip: 'Increment',
                child: Icon(Icons.add),
              ),
              SizedBox(height: 5),
              FloatingActionButton(
                onPressed: () async { await _getText();
                },
                tooltip: 'Increment',
                child: Icon(Icons.send),
              ),
            ]
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({this.pointsList});

  //Keep track of the points tapped on the screen
  List<TouchPoints> pointsList;
  List<Offset> offsetPoints = List();

  //This is where we can draw on canvas.
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i= i+2) {
      print(pointsList[i].points.dx);print(pointsList[i].points.dy);
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        //Drawing line when two consecutive points are available
        canvas.drawRect(
          new Rect.fromLTRB(
              pointsList[i].points.dx, pointsList[i].points.dy, pointsList[i+1].points.dx, pointsList[i+1].points.dy
          ),
          new Paint()..color = new Color(0xFF0099FF),
        );
      }
    }
  }

  //Called when CustomPainter is rebuilt.
  //Returning true because we want canvas to be rebuilt to reflect new changes.
  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}

//Class to define a point touched at canvas
class TouchPoints {
  Offset points;
  TouchPoints({this.points});
}

















