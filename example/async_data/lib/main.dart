import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: AsyncDataExampleHomePage(),
    );
  }
}

class AsyncDataExampleHomePage extends StatefulWidget {
  @override
  _AsyncDataExampleHomePageState createState() =>
      _AsyncDataExampleHomePageState();
}

class _AsyncDataExampleHomePageState extends State<AsyncDataExampleHomePage>
    with TickerProviderStateMixin {
  StreamController<List<String>> _streamController;

  List<String> welcomeImages = [
    "assets/welcome0.png",
    "assets/welcome1.png",
    "assets/welcome2.png",
  ];

  @override
  initState() {
    super.initState();
    _streamController = StreamController<List<String>>();
  }

  void _addToStream() {
    Random random = Random();
    int index = random.nextInt(3);
    welcomeImages.add('assets/welcome$index.png');
    _streamController.add(welcomeImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("asynchronous data events demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Added image appears on top:',
            ),
            StreamBuilder<List<String>>(
              stream: _streamController.stream,
              initialData: welcomeImages,
              builder:
                  (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                print('snapshot.data.length: ${snapshot.data.length}');
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return Text('Add image');
                  case ConnectionState.waiting:
                  // TODO: Handle this case.
                  case ConnectionState.active:
                    return _asyncDataExample(
                      context,
                      snapshot.data,
                      (CardSwipeOrientation orientation) {
                        // welcomeImages[0] is the swiped card
                        // you can send to backend service in here
                        welcomeImages.removeAt(0);
                        _streamController.add(welcomeImages);
                      },
                    );
                  case ConnectionState.done:
                    return Text('\$${snapshot.data} (closed)');
                }
                return null;
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToStream,
        tooltip: 'Add image',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _asyncDataExample(
      BuildContext context, List<String> imageList, Function onSwipe) {
    CardController controller; //Use this to trigger swap.

    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: TinderSwapCard(
          orientation: AmassOrientation.bottom,
          totalNum: imageList.length,
          stackNum: 4,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.width * 0.9,
          cardBuilder: (context, index) => Card(
            child: Image.asset('${imageList[index]}'),
          ),
          cardController: controller = CardController(),
          swipeUpdateCallback: (DragUpdateDetails details, Offset offset) {
            /// Get swiping card's alignment
            if (offset.dx < 0) {
              //Card is LEFT swiping
            } else if (offset.dx > 0) {
              //Card is RIGHT swiping
            }
          },
          swipeCompleteCallback: (CardSwipeOrientation orientation, int index) {
            if (orientation != CardSwipeOrientation.recover) {
              onSwipe(orientation);
            }
          },
        ),
      ),
    );
  }
}
