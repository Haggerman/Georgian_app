import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:translator/translator.dart';

void main() {
  runApp(MaterialApp(home: GeorgianApp()));
}

class GeorgianApp extends StatefulWidget {
  @override
  _GeorgianApp createState() => _GeorgianApp();

}

class _GeorgianApp extends State<GeorgianApp> {
  ScreenshotController screenshotController = ScreenshotController();
  GlobalKey globalKey = GlobalKey();
  List<TouchPoints> points = List();
  List<TouchPoints> tempPoints = List();
  List<TouchPoints> rectangles = List();
  final translator = GoogleTranslator();
  File _image;
  File imagePath;
  bool httpRequest = false;
  int height = 0;
  int width = 0;
  double widthScreen;
  GlobalKey _keyImage = GlobalKey();
  String text = 'Dešifruji...';
  StateSetter _setState;
  String coordinates ="";
  final picker = ImagePicker();
  double heightScreen;
  int rectCount = 1;

  _showAlertDialog(BuildContext context) {
    var pressed = false ;
    var translated = false;
    showDialog(
      context: context,
      barrierColor: Colors.white.withOpacity(0.1),
      builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              _setState = setState;
              return AlertDialog (
                backgroundColor: Colors.black.withOpacity(0.7),
                content: Container(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                      SizedBox(
                      height: 20,
                    ),
                    Text(text, style: TextStyle(color: Colors.lightBlue)),
                      ],
                    ),
                  ),
                ),
                actions: !httpRequest? null : <Widget>[
                  FlatButton(onPressed: pressed? null: (){Clipboard.setData(new ClipboardData(text:text));
                  setState((){
                    pressed = !pressed ;
                  });
                  }, child: pressed? null : Text("Zkopírovat"),color: pressed ? Colors.transparent : Colors.green,),
                  FlatButton(onPressed: translated? null : () async{translator.translate(text, from: 'ka', to: 'cs').then((s) {
                    setState(() {
                      text = s.text;
                      translated = !translated;
                    });
                  });},
                    child: translated? null : Text("Přeložit"),color: pressed ? Colors.transparent : Colors.green,)
                ],
              );
            },
          );
      },
    );
  }

  String _coordinates(){
    for (int i = 0; i < rectangles.length-1; i=i+2) {
      int x1 = (rectangles[i].points.dx).toInt();
      int x2 = (rectangles[i+1].points.dx).toInt();
      int y1 = (rectangles[i].points.dy).toInt();
      int y2 = (rectangles[i+1].points.dy).toInt();
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
    text="Dešifruji...";
    httpRequest=false;
    coordinates = "";
      setState(() {
        tempPoints = List.from(rectangles);
        rectangles.clear();
      });

    screenshotController
        .capture()
        .then((File image) async {
      setState(() {
        imagePath = image;
        rectangles= List.from(tempPoints);
        tempPoints.clear();
      });

      _request();

    }).catchError((onError) {
      print(onError);
    });
  }

  Future _request() async{
    if(rectangles.length > 0) {
      coordinates = _coordinates();
    }
    var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://georgian101.herokuapp.com/api/v1/extract_text"));
    if(coordinates.isNotEmpty) {
      request.fields['coordinates'] = coordinates;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imagePath.path,
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
          _setState(() {
            text = mapJson["text"];
            httpRequest = true;
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
    widthScreen = MediaQuery.of(context).size.width;
    heightScreen = MediaQuery.of(context).size.height;
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      var decodedImage = await decodeImageFromList(_image.readAsBytesSync());
      if(decodedImage.width + 20 < widthScreen)
      width= decodedImage.width + 20;
      else
        width = decodedImage.width;
      if(decodedImage.height + 20 < heightScreen)
      height= decodedImage.height + 20;
      else
        height= decodedImage.height;

    }
    setState(() {
      if (pickedFile != null) {
        rectangles.clear();
        _image = File(pickedFile.path);
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
        body: RepaintBoundary(
            key: globalKey,
            child: Center(
              child: Screenshot(
                controller: screenshotController,
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
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject();

                        if(details.localPosition.dx > 0 && details.localPosition.dx < width && details.localPosition.dy > 0 && details.localPosition.dy < height) {
                          points.add(TouchPoints(
                            points: renderBox.globalToLocal(
                                details.localPosition),));
                          if (points.length == 3)
                            points.removeAt(points.length - 2);
                        }
                      });
                    },
                    onPanStart: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject();
                        points.add(TouchPoints(
                          points: renderBox.globalToLocal(details.localPosition),));
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                            rectCount++;
                            rectangles.add(TouchPoints(points: points[0].points));
                            rectangles.add(TouchPoints(points: points[1].points));
                            points.clear();

                        }
                      );
                    },
                    child:CustomPaint(
                      size: Size.infinite,
                      painter: MyPainter(
                        pointsList: points,
                        rectangles: rectangles
                      ),
                    ),
                  ),
                  ),
              ),
              ),
            ),
        floatingActionButton: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () async{await _getImage();},
                tooltip: 'Vybrat obrazek',
                child: Icon(Icons.photo),
              ),
              SizedBox(width: 5),
              FloatingActionButton(
                  heroTag: "erase",
                  child: Icon(Icons.clear),
                  tooltip: "Erase",
                  backgroundColor: rectangles.length == 0 ? Colors.blueGrey.withOpacity(0.5): Colors.green,
                  onPressed: rectangles.length == 0 ? null : () {
                    setState(() {
                      rectangles.clear();
                    });
                  }),
              SizedBox(width: 5),
              FloatingActionButton(
                  heroTag: "stepBack",
                  child: Icon(Icons.keyboard_backspace),
                  tooltip: "Step back",
                  backgroundColor: rectangles.length < 2 ? Colors.blueGrey.withOpacity(0.5): Colors.green,
                  onPressed: rectangles.length < 2 ? null : () {
                    setState(() {
                      rectangles.removeLast();
                      rectangles.removeLast();
                    });
                  }),
              SizedBox(width: 5),
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
  MyPainter({this.pointsList, this.rectangles});
  List<TouchPoints> pointsList;
  List<TouchPoints> rectangles;
  List<Offset> offsetPoints = List();

  @override
  void paint(Canvas canvas, Size size) {
      for (int i = 0; i < pointsList.length-1; i = i + 2) {
        if (pointsList[i] != null && pointsList[i + 1] != null) {
          canvas.drawRect(
              new Rect.fromLTRB(
                  pointsList[i].points.dx, pointsList[i].points.dy,
                  pointsList[i + 1].points.dx, pointsList[i + 1].points.dy
              ),
              new Paint()..color = new Color.fromRGBO(0, 127, 255, 0.7)
          );
        }
      }

      for (int i = 0; i < rectangles.length-1; i = i + 2) {
        if (rectangles[i] != null && rectangles[i + 1] != null) {
          canvas.drawRect(
              new Rect.fromLTRB(
                  rectangles[i].points.dx, rectangles[i].points.dy,
                  rectangles[i + 1].points.dx, rectangles[i + 1].points.dy
              ),
              new Paint()..color = new Color.fromRGBO(0, 127, 255, 0.7)
          );
        }
      }
  }


  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;
}

class TouchPoints {
  Offset points;
  TouchPoints({this.points});
}















