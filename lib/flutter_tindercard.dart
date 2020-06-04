library flutter_tindercard;

import 'package:flutter/material.dart';
import 'dart:math';

List<Size> _cardSizes = new List();
List<Alignment> _cardAligns = new List();

/// A Tinder-Like Widget.
class TinderSwapCard extends StatefulWidget {
  CardBuilder _cardBuilder;
  int _totalNum;
  int _stackNum;
  int _animDuration;
  double _swipeEdge;
  double _swipeEdgeVertical;
  bool _swipeUp;
  bool _swipeDown;
  bool _allowVerticalMovement;
  CardSwipeCompleteCallback swipeCompleteCallback;
  CardDragUpdateCallback swipeUpdateCallback;
  CardController cardController;

//  double _maxWidth;
//  double _minWidth;
//  double _maxHeight;
//  double _minHeight;

  @override
  _TinderSwapCardState createState() => _TinderSwapCardState();

  /// Constructor requires Card Widget Builder [cardBuilder] & your card count [totalNum]
  /// , option includes: stack orientation [orientation], number of card display in same time [stackNum]
  /// , [swipeEdge] is the edge to determine action(recover or swipe) when you release your swiping card
  /// it is the value of alignment, 0.0 means middle, so it need bigger than zero.
  /// , and size control params;
  TinderSwapCard(
      {@required CardBuilder cardBuilder,
      @required int totalNum,
      AmassOrientation orientation = AmassOrientation.BOTTOM,
      int stackNum = 3,
      int animDuration = 800,
      double swipeEdge = 3.0,
      double swipeEdgeVertical = 8.0,
      bool swipeUp = false,
      bool swipeDown = false,
      double maxWidth,
      double maxHeight,
      double minWidth,
      double minHeight,
      bool allowVerticalMovement = true,
      this.cardController,
      this.swipeCompleteCallback,
      this.swipeUpdateCallback})
      : this._cardBuilder = cardBuilder,
        this._totalNum = totalNum,
        assert(stackNum > 1),
        this._stackNum = stackNum,
        this._animDuration = animDuration,
        assert(swipeEdge > 0),
        this._swipeEdge = swipeEdge,
        assert(swipeEdgeVertical > 0),
        this._swipeEdgeVertical = swipeEdgeVertical,
        this._swipeUp = swipeUp,
        this._swipeDown = swipeDown,
        assert(maxWidth > minWidth && maxHeight > minHeight),
        this._allowVerticalMovement = allowVerticalMovement
//        this._maxWidth = maxWidth,
//        this._minWidth = minWidth,
//        this._maxHeight = maxHeight,
//        this._minHeight = minHeight
  {
    double widthGap = maxWidth - minWidth;
    double heightGap = maxHeight - minHeight;

    _cardAligns = new List();
    _cardSizes = new List();

    for (int i = 0; i < _stackNum; i++) {
      _cardSizes.add(new Size(minWidth + (widthGap / _stackNum) * i,
          minHeight + (heightGap / _stackNum) * i));

      switch (orientation) {
        case AmassOrientation.BOTTOM:
          _cardAligns.add(
              new Alignment(0.0, (0.5 / (_stackNum - 1)) * (stackNum - i)));
          break;
        case AmassOrientation.TOP:
          _cardAligns.add(
              new Alignment(0.0, (-0.5 / (_stackNum - 1)) * (stackNum - i)));
          break;
        case AmassOrientation.LEFT:
          _cardAligns.add(
              new Alignment((-0.5 / (_stackNum - 1)) * (stackNum - i), 0.0));
          break;
        case AmassOrientation.RIGHT:
          _cardAligns.add(
              new Alignment((0.5 / (_stackNum - 1)) * (stackNum - i), 0.0));
          break;
      }
    }
  }
}

class _TinderSwapCardState extends State<TinderSwapCard>
    with TickerProviderStateMixin {
  Alignment frontCardAlign;
  AnimationController _animationController;
  int _currentFront;
  static int _trigger; // 0: no trigger; -1: trigger left; 1: trigger right

  Widget _buildCard(BuildContext context, int realIndex) {
    if (realIndex < 0) {
      return Container();
    }
    int index = realIndex - _currentFront;

    if (index == widget._stackNum - 1) {
      return Align(
        alignment: _animationController.status == AnimationStatus.forward
            ? frontCardAlign = CardAnimation.frontCardAlign(
                    _animationController,
                    frontCardAlign,
                    _cardAligns[widget._stackNum - 1],
                    widget._swipeEdge,
                    widget._swipeUp,
                    widget._swipeDown)
                .value
            : frontCardAlign,
        child: Transform.rotate(
            angle: (pi / 180.0) *
                (_animationController.status == AnimationStatus.forward
                    ? CardAnimation.frontCardRota(
                            _animationController, frontCardAlign.x)
                        .value
                    : frontCardAlign.x),
            child: new SizedBox.fromSize(
              size: _cardSizes[index],
              child: widget._cardBuilder(
                  context, widget._totalNum - realIndex - 1),
            )),
      );
    }

    return Align(
      alignment: _animationController.status == AnimationStatus.forward &&
              (frontCardAlign.x > 3.0 || frontCardAlign.x < -3.0)
          ? CardAnimation.backCardAlign(_animationController,
                  _cardAligns[index], _cardAligns[index + 1])
              .value
          : _cardAligns[index],
      child: new SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward &&
                (frontCardAlign.x > 3.0 || frontCardAlign.x < -3.0)
            ? CardAnimation.backCardSize(_animationController,
                    _cardSizes[index], _cardSizes[index + 1])
                .value
            : _cardSizes[index],
        child: widget._cardBuilder(context, widget._totalNum - realIndex - 1),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    List<Widget> cards = new List();
    for (int i = _currentFront; i < _currentFront + widget._stackNum; i++) {
      cards.add(_buildCard(context, i));
    }

    cards.add(new SizedBox.expand(
      child: new GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            if (widget._allowVerticalMovement == true) {
              frontCardAlign = new Alignment(
                  frontCardAlign.x +
                      details.delta.dx * 20 / MediaQuery.of(context).size.width,
                  frontCardAlign.y +
                      details.delta.dy *
                          30 /
                          MediaQuery.of(context).size.height);
            } else {
              frontCardAlign = new Alignment(
                  frontCardAlign.x +
                      details.delta.dx * 20 / MediaQuery.of(context).size.width,
                  0);

              if (widget.swipeUpdateCallback != null) {
                widget.swipeUpdateCallback(details, frontCardAlign);
              }
            }

            if (widget.swipeUpdateCallback != null) {
              widget.swipeUpdateCallback(details, frontCardAlign);
            }
          });
        },
        onPanEnd: (DragEndDetails details) {
          animateCards(0);
        },
      ),
    ));
    return cards;
  }

  animateCards(int trigger) {
    if (_animationController.isAnimating ||
        _currentFront + widget._stackNum == 0) {
      return;
    }
    _trigger = trigger;
    _animationController.stop();
    _animationController.value = 0.0;
    _animationController.forward();
  }

  void triggerSwap(int trigger) {
    animateCards(trigger);
  }

  // support for asynchronous data events 
  @override
  void didUpdateWidget(covariant TinderSwapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._totalNum != oldWidget._totalNum) {
      _initState();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() {
    _currentFront = widget._totalNum - widget._stackNum;

    frontCardAlign = _cardAligns[_cardAligns.length - 1];
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: widget._animDuration));
    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener((AnimationStatus status) {
      int index = widget._totalNum - widget._stackNum - _currentFront;
      if (status == AnimationStatus.completed) {
        CardSwipeOrientation orientation;
        if(frontCardAlign.x < -widget._swipeEdge) orientation = CardSwipeOrientation.LEFT;
        else if(frontCardAlign.x > widget._swipeEdge) orientation = CardSwipeOrientation.RIGHT;
        else if(frontCardAlign.y < -widget._swipeEdgeVertical) orientation = CardSwipeOrientation.UP;
        else if(frontCardAlign.y > widget._swipeEdgeVertical) orientation = CardSwipeOrientation.DOWN;
        else {
          frontCardAlign = _cardAligns[widget._stackNum - 1];
          orientation = CardSwipeOrientation.RECOVER;
        }
        if (widget.swipeCompleteCallback != null) widget.swipeCompleteCallback(orientation, index);
        if(orientation != CardSwipeOrientation.RECOVER) changeCardOrder();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.cardController?.addListener((trigger) => triggerSwap(trigger));

    return Stack(children: _buildCards(context));
  }

  changeCardOrder() {
    setState(() {
      _currentFront--;
      frontCardAlign = _cardAligns[widget._stackNum - 1];
    });
  }
}

typedef Widget CardBuilder(BuildContext context, int index);

enum CardSwipeOrientation { LEFT, RIGHT, RECOVER, UP, DOWN }

/// swipe card to [CardSwipeOrientation.LEFT] or [CardSwipeOrientation.RIGHT]
/// , [CardSwipeOrientation.RECOVER] means back to start.
typedef CardSwipeCompleteCallback = void Function(
    CardSwipeOrientation orientation, int index);

/// [DragUpdateDetails] of swiping card.
typedef CardDragUpdateCallback = void Function(
    DragUpdateDetails details, Alignment align);

enum AmassOrientation { TOP, BOTTOM, LEFT, RIGHT }

class CardAnimation {
  static Animation<Alignment> frontCardAlign(AnimationController controller,
      Alignment beginAlign, Alignment baseAlign, double swipeEdge, 
      bool swipeUp, bool swipeDown) {
    double endX, endY;

    if (_TinderSwapCardState._trigger == 0) {
      endX = beginAlign.x > 0
          ? (beginAlign.x > swipeEdge ? beginAlign.x + 10.0 : baseAlign.x)
          : (beginAlign.x < -swipeEdge ? beginAlign.x - 10.0 : baseAlign.x);
      endY = beginAlign.x > 3.0 || beginAlign.x < -swipeEdge
          ? beginAlign.y
          : baseAlign.y;

      if (swipeUp || swipeDown) {
        if (beginAlign.y < 0) {
          if (swipeUp) endY = beginAlign.y < -swipeEdge ? beginAlign.y - 10.0 : baseAlign.y;
        } else if (beginAlign.y > 0) {
          if (swipeDown) endY = beginAlign.y > swipeEdge ? beginAlign.y + 10.0 : baseAlign.y;
        } 
      }
    } else if (_TinderSwapCardState._trigger == -1) {
      endX = beginAlign.x - swipeEdge;
      endY = beginAlign.y + 0.5;
    } else {
      endX = beginAlign.x + swipeEdge;
      endY = beginAlign.y + 0.5;
    }
    return new AlignmentTween(begin: beginAlign, end: new Alignment(endX, endY))
        .animate(
            new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  static Animation<double> frontCardRota(
      AnimationController controller, double beginRot) {
    return new Tween(begin: beginRot, end: 0.0).animate(
        new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  static Animation<Size> backCardSize(
      AnimationController controller, Size beginSize, Size endSize) {
    return new SizeTween(begin: beginSize, end: endSize).animate(
        new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  static Animation<Alignment> backCardAlign(AnimationController controller,
      Alignment beginAlign, Alignment endAlign) {
    return new AlignmentTween(begin: beginAlign, end: endAlign).animate(
        new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }
}

typedef TriggerListener = void Function(int trigger);

class CardController {
  TriggerListener _listener;

  void triggerLeft() {
    if (_listener != null) {
      _listener(-1);
    }
  }

  void triggerRight() {
    if (_listener != null) {
      _listener(1);
    }
  }

  void addListener(listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }
}
