RepaintBoundary(
key: globalKey,
child: Stack(
children: <Widget>[
Center(
child: Container(
child:
GestureDetector(
onPanUpdate: (details) {
setState(() {
RenderBox renderBox = context.findRenderObject();
points.add(TouchPoints(
points: renderBox.globalToLocal(details.globalPosition),
paint: Paint()
..strokeCap = strokeType
..isAntiAlias = true
..color = selectedColor.withOpacity(opacity)
..strokeWidth = strokeWidth));
});
},
onPanStart: (details) {
setState(() {
RenderBox renderBox = context.findRenderObject();
points.add(TouchPoints(
points: renderBox.globalToLocal(details.globalPosition),
paint: Paint()
..strokeCap = strokeType
..isAntiAlias = true
..color = selectedColor.withOpacity(opacity)
..strokeWidth = strokeWidth));
});
},
onPanEnd: (details) {
setState(() {
points.add(null);
});
},
),
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