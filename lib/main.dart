import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert' as convert;

import 'package:flutter/cupertino.dart';
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
  double widthScreen;
  GlobalKey _keyImage = GlobalKey();
  String text = 'Loading...';
  StateSetter _setState;
  String coordinates ="";
  final picker = ImagePicker();


  _showAlertDialog(BuildContext context) {

    var pressed = false ;
    showDialog(
      context: context,
      barrierColor: Colors.white.withOpacity(0.1),
      builder: (BuildContext context) {

          return StatefulBuilder(  // You need this, notice the parameters below:
            builder: (BuildContext context, StateSetter setState) {
              _setState = setState;
              return AlertDialog (
                backgroundColor: Colors.black.withOpacity(0.7),
                title: Center(child: Text(text, style: TextStyle(color: Colors.lightBlue)),),
                actions:  <Widget>[
                  FlatButton(onPressed: pressed? null: (){Clipboard.setData(new ClipboardData(text:text));
                  setState((){
                    pressed = !pressed ; // update the state of the class to show color change
                  });
                  }, child: pressed? null : Text("Zkopírovat"),color: pressed ? Colors.transparent : Colors.green,)
                ],
              );
            },
          );
      },
    );
  }

  String _coordinates(){
    for (int i = 0; i < points.length-1; i=i+2) {
      int x1 = (points[i].points.dx).toInt();
      int x2 = (points[i+1].points.dx).toInt();
      int y1 = (points[i].points.dy).toInt();
      int y2 = (points[i+1].points.dy).toInt();
      int odklad;
      if(x2<x1){
        odklad = x1;
        x1 = x2;
        x2 = odklad;
      }
      if(y2<y1){
        odklad = y1;
        y1 = y2;
        y2 = odklad;
      }

      coordinates = coordinates + x1.toString() + "," + y1.toString() + "," + x2.toString() + "," + y2.toString() + "," ;
    }
    coordinates = coordinates.substring(0, coordinates.length - 1);
    return coordinates;
  }

  Future _getText() async {
    text="Loading...";
    coordinates = "";


    if(points.length > 0) {
     coordinates = _coordinates();
     print(coordinates);
    }
    var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://georgian101.herokuapp.com/api/v1/extract_text"));
    if(coordinates.isNotEmpty) {
      request.fields['coordinates'] = coordinates;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image.path,
    ));
    _showAlertDialog(context);
    request.send().then((result) async {
      http.Response.fromStream(result)
          .then((response) {
        if (response.statusCode == 404)
        {
          _setState(() {
            text = "Chyba spojení";
          });
        }
        else if (response.statusCode == 200)
        {
          Map mapJson = json.decode(utf8.decode(response.bodyBytes));
          print(mapJson["text"]);
          _setState(() {
            text = mapJson["text"];
          });
        }
        else{
          _setState(() {
            text = "Chyba, kontaktujte svého poskytovatele";
          });
        }
      });
    }).catchError((err) => print('error : '+err.toString()))
        .whenComplete(()
    {});
  }

  Future _getImage() async {
    double widthScreen = MediaQuery.of(context).size.width;
    final pickedFile = await picker.getImage(source: ImageSource.gallery, maxWidth: widthScreen);
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
        points.clear();
        _image = File(pickedFile.path);
        print('_image: $_image');
      } else {
        print('No image selected');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white70,
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
                backgroundColor: Colors.green,
                onPressed: () async{await _getImage();},
                tooltip: 'Vybrat obrazek',
                child: Icon(Icons.add),
              ),
              SizedBox(height: 5),
              FloatingActionButton(
                  heroTag: "erase",
                  child: Icon(Icons.clear),
                  tooltip: "Erase",
                  backgroundColor: points.length == 0 ? Colors.blueGrey.withOpacity(0.5): Colors.green,
                  onPressed: points.length == 0 ? null : () {
                    setState(() {
                      points.clear();
                    });
                  }),
              SizedBox(height: 5),
              FloatingActionButton(
                  heroTag: "stepBack",
                  child: Icon(Icons.keyboard_backspace),
                  tooltip: "Step back",
                  backgroundColor: points.length < 2 ? Colors.blueGrey.withOpacity(0.5): Colors.green,
                  onPressed: points.length < 2 ? null : () {
                    setState(() {
                      points.removeLast();
                      points.removeLast();
                    });
                  }),
              SizedBox(height: 5),
              FloatingActionButton(
                backgroundColor: _image == null ? Colors.blueGrey.withOpacity(0.5): Colors.green,
                onPressed: _image == null
                    ? null
                    : () async { await _getText();
                },
                tooltip: 'Odeslat',
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
      print(pointsList[i+1].points.dx);print(pointsList[i+1].points.dy);
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        //Drawing line when two consecutive points are available
        canvas.drawRect(
          new Rect.fromLTRB(
              pointsList[i].points.dx, pointsList[i].points.dy, pointsList[i+1].points.dx, pointsList[i+1].points.dy
          ),
          new Paint()..color = new Color.fromRGBO(0, 127, 255, 0.7)
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

















