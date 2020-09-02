import 'package:flutter/material.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AsyncDataExampleHomePage(),
    );
  }
}

// support for asynchronous data events
class AsyncDataExampleHomePage extends StatefulWidget {
  @override
  _AsyncDataExampleHomePageState createState() => _AsyncDataExampleHomePageState();
}

class _AsyncDataExampleHomePageState extends State<AsyncDataExampleHomePage> with TickerProviderStateMixin {
  StreamController<List<String>> _streamController;

  List<String> welcomeImages = [
    "assets/welcome0.png",
    "assets/welcome1.png",
    "assets/welcome2.png",
    "assets/welcome2.png",
    "assets/welcome1.png",
    "assets/welcome1.png"
  ];

  @override
  initState() {
    super.initState();
    _streamController = StreamController<List<String>>();
  }

  void _addToStream() {
    Random random = new Random();
    int index = random.nextInt(3);
    welcomeImages.add('assets/welcome$index.png');
    _streamController.add(welcomeImages);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("asynchronous data events test"),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'Added image appears on top:',
            ),
            StreamBuilder<List<String>>(
              stream: _streamController.stream,
              initialData: welcomeImages,
              builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                print('snapshot.data.length: ${snapshot.data.length}');
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return Text('Add image');
                  case ConnectionState.waiting: /*return Text('Awaiting images...');*/
                  case ConnectionState.active:
                    return _AsyncDataExample(
                      context,
                      snapshot.data,
                      (CardSwipeOrientation orientation, int index) {
                        // you can send data to backend service vie orientation
                        welcomeImages.removeAt(index);
                        _streamController.add(welcomeImages);
                      },
                    );
                  case ConnectionState.done:
                    return Text('\$${snapshot.data} (closed)');
                }
                return null; // unreachable
              },
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addToStream,
        tooltip: 'Add image',
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget _AsyncDataExample(BuildContext context, List<String> imageList, Function onSwipe) {
    CardController controller; //Use this to trigger swap.

    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: TinderSwapCard(
          orientation: AmassOrientation.BOTTOM,
          totalNum: imageList.length,
          stackNum: 4,
          swipeEdge: 4.0,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.width * 0.9,
          minWidth: MediaQuery.of(context).size.width * 0.8,
          minHeight: MediaQuery.of(context).size.width * 0.8,
          cardBuilder: (context, index) => Card(
            child: Image.asset('${imageList[index]}'),
          ),
          cardController: controller = CardController(),
          swipeUpdateCallback: (DragUpdateDetails details, Alignment align) {
            /// Get swiping card's alignment
            if (align.x < 0) {
              //Card is LEFT swiping
            } else if (align.x > 0) {
              //Card is RIGHT swiping
            }
          },
          swipeCompleteCallback: (CardSwipeOrientation orientation, int index) {
            if (orientation != CardSwipeOrientation.RECOVER) {
              onSwipe(orientation, index);
            }

            /// Get orientation & index of swiped card!
          },
        ),
      ),
    );
  }
}
