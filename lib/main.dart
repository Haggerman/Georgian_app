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
  double opacity = 1.0;
  StrokeCap strokeType = StrokeCap.round;
  double strokeWidth = 3.0;
  Color selectedColor = Colors.black;
  File _image;
  int height;
  int width;
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
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
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


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body:RepaintBoundary(
          key: globalKey,
          child: Stack(
            children: <Widget>[
              Center(
                child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _image == null
                            ? MemoryImage(kTransparentImage)
                            : FileImage(_image),
                      ),
                    )
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: MyPainter(
                  pointsList: points,
                ),
              ),

            ],
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
                onPressed: _getImage,
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

  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 8.0),
          height: 36,
          width: 36,
          color: color,
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
    for (int i = 0; i < pointsList.length - 1; i++) {
      print(pointsList[i].points.dx);print(pointsList[i].points.dy);
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        //Drawing line when two consecutive points are available
        canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
            pointsList[i].paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i].points);
        offsetPoints.add(Offset(
            pointsList[i].points.dx + 0.1, pointsList[i].points.dy + 0.1));

        //Draw points when two points are not next to each other
        canvas.drawPoints(
            ui.PointMode.points, offsetPoints, pointsList[i].paint);
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
  Paint paint;
  Offset points;
  TouchPoints({this.points, this.paint});
}




















