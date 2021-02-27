library flutter_tindercard;

import 'dart:math';

import 'package:flutter/material.dart';

enum TriggerDirection { none, right, left, up, down }

/// A Tinder-Like Widget.
class TinderSwapCard extends StatefulWidget {
  final CardBuilder _cardBuilder;

  final int _totalNum;

  final int _stackNum;

  final int _animDuration;

  final double _swipeEdge;

  final double _swipeEdgeVertical;

  final bool _swipeUp;

  final bool _swipeDown;

  final bool _allowVerticalMovement;

  final CardSwipeCompleteCallback swipeCompleteCallback;

  final CardDragUpdateCallback swipeUpdateCallback;

  final CardController cardController;

  // final List<Size> _cardSizes = [];
  final Size _cardSize;
  final List<double> _cardScales = [];

  final List<Alignment> _cardAligns = [];

  @override
  _TinderSwapCardState createState() => _TinderSwapCardState();

  /// Constructor requires Card Widget Builder [cardBuilder] and
  /// your card count [totalNum]
  /// option includes:
  /// stack orientation [orientation], number of card display
  /// in same time [stackNum], [swipeEdge] is the edge to determine
  /// action(recover or swipe) when you release your swiping card it is the
  /// value of alignment, 0.0 means middle, so it need bigger than zero.
  /// and size control params;
  TinderSwapCard({
    @required CardBuilder cardBuilder,
    @required int totalNum,
    AmassOrientation orientation = AmassOrientation.bottom,
    int stackNum = 3,
    int animDuration = 800,
    double swipeEdge = 3.0,
    double swipeEdgeVertical = 8.0,
    bool swipeUp = false,
    bool swipeDown = false,
    double maxWidth,
    double maxHeight,
    double scaleFactor = 0.1,
    bool allowVerticalMovement = true,
    this.cardController,
    this.swipeCompleteCallback,
    this.swipeUpdateCallback,
  })  : assert(stackNum > 1),
        assert(swipeEdge > 0),
        assert(swipeEdgeVertical > 0),
        _cardBuilder = cardBuilder,
        _totalNum = totalNum,
        _stackNum = stackNum,
        _animDuration = animDuration,
        _swipeEdge = swipeEdge,
        _swipeEdgeVertical = swipeEdgeVertical,
        _swipeUp = swipeUp,
        _swipeDown = swipeDown,
        _allowVerticalMovement = allowVerticalMovement,
        _cardSize = Size(maxWidth, maxHeight) {
    int i = _stackNum;
    while (i-- != 0) {
      _cardScales.add(1 - scaleFactor * i);

      switch (orientation) {
        case AmassOrientation.top:
          _cardAligns.add(
            Alignment(
              0.0,
              (0.5 / (_stackNum - 1)) * (stackNum - i),
            ),
          );
          break;
        case AmassOrientation.bottom:
          _cardAligns.add(
            Alignment(
              0.0,
              (-0.5 / (_stackNum - 1)) * (stackNum - i),
            ),
          );
          break;
        case AmassOrientation.left:
          _cardAligns.add(
            Alignment(
              (-0.5 / (_stackNum - 1)) * (stackNum - i),
              0.0,
            ),
          );
          break;
        case AmassOrientation.right:
          _cardAligns.add(
            Alignment(
              (0.5 / (_stackNum - 1)) * (stackNum - i),
              0.0,
            ),
          );
          break;
      }
    }
  }
}

class _TinderSwapCardState extends State<TinderSwapCard>
    with TickerProviderStateMixin {
  Alignment frontCardAlign;
  // Matrix4 transformation; // = Matrix4.zero();
  // Matrix4 transformation = Matrix4.translationValues(0.0, 0.0, 0.0);
  // double x;
  // double y;
  Rect _positionRect;
  Offset _offset = Offset.zero;

  AnimationController _animationController;

  int _currentFront;

  static TriggerDirection _trigger;

  Widget _buildCard(BuildContext context, int realIndex) {
    if (realIndex < 0) {
      return Container();
    }
    final index = realIndex - _currentFront;

    final Widget card = SizedBox.fromSize(
        size: widget._cardSize,
        child: widget._cardBuilder(context, widget._totalNum - realIndex - 1));

    if (index == widget._stackNum - 1) {
      final angle = (pi / 180.0) *
          (_animationController.status == AnimationStatus.forward
              ? CardAnimation.frontCardRota(
                      _animationController, frontCardAlign.x)
                  .value
              : frontCardAlign.x);

      // final angle = 0.0;
      final transformation = Matrix4.identity(); //rotationZ(angle);
      transformation.rotateZ(angle * 2);
      // transformation.scale(widget._cardScales[index]);
      // transformation.translate(20.0, 20.0);
      // transformation.scale(1.5);

      // return Transform(transform: transformation, child: card);

      Offset offset = _animationController.status == AnimationStatus.forward
          ? CardAnimation.frontCardOffset(
                  _animationController,
                  _offset,
                  Offset.zero,
                  widget._swipeEdge,
                  widget._swipeUp,
                  widget._swipeDown)
              .value
          : _offset;

      Rect _positionRect = Rect.fromLTWH(offset.dx * 3, offset.dy * 3,
          widget._cardSize.width, widget._cardSize.height);
      return Positioned.fromRect(
          rect: _positionRect,
          child: Transform(transform: transformation, child: card));

      /*return Align(
        alignment: _animationController.status == AnimationStatus.forward
            ? frontCardAlign = CardAnimation.frontCardAlign(
                _animationController,
                frontCardAlign,
                widget._cardAligns[widget._stackNum - 1],
                widget._swipeEdge,
                widget._swipeUp,
                widget._swipeDown,
              ).value
            : frontCardAlign,
          child: Transform(
            transform: transformation,
            child: card,
          ));*/
    }

    return Align(
      alignment: _animationController.status == AnimationStatus.forward
          // && (frontCardAlign.x > 3.0 || frontCardAlign.x < -3.0 || frontCardAlign.y > 3 || frontCardAlign.y < -3)
          ? CardAnimation.backCardAlign(
              _animationController,
              widget._cardAligns[index],
              widget._cardAligns[index + 1],
            ).value
          : widget._cardAligns[index],
      child: Transform.scale(
        scale: _animationController.status == AnimationStatus.forward
            // && (frontCardAlign.x > 3.0 || frontCardAlign.x < -3.0 || frontCardAlign.y > 3 || frontCardAlign.y < -3)
            ? CardAnimation.backCardScale(
                _animationController,
                widget._cardScales[index],
                widget._cardScales[index + 1],
              ).value
            : widget._cardScales[index],
        child: card,
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    final cards = <Widget>[];
    final size = MediaQuery.of(context).size;

    // transformation = Matrix4.translationValues(0.0, 0.0, 0.0);
    // transformation = Matrix4.translationValues(50.0, 50.0, 0.0);
    // _positionRect = Rect.fromLTRB(0, 0, size.width, size.height);

    for (var i = _currentFront; i < _currentFront + widget._stackNum; i++) {
      cards.add(_buildCard(context, i));
    }

    cards.add(SizedBox.expand(
      child: GestureDetector(
        onPanStart: (DragStartDetails details) {},
        onPanUpdate: (final details) {
          // print('onPanUpdate: ${frontCardAlign.x} + ${details.delta.dx} * 20 / ${MediaQuery.of(context).size.width} '
          //     '= ${frontCardAlign.x + details.delta.dx * 20 / MediaQuery.of(context).size.width}');
          // print('onPanUpdate: ${details.globalPosition}');

          setState(() {
            if (widget._allowVerticalMovement == true) {
              frontCardAlign += Alignment(
                10 * details.delta.dx / (size.width / 2),
                15 * details.delta.dy / (size.height / 2),
              );

              // frontCardAlign = Alignment(
              //   frontCardAlign.x + details.delta.dx * 20 / MediaQuery.of(context).size.width,
              //   frontCardAlign.y + details.delta.dy * 30 / MediaQuery.of(context).size.height,
              // );

              // transformation.translate(-details.delta.dx * 10, details.delta.dy * 15);
              // transformation = Matrix4.translationValues(details.delta.dx * 10, details.delta.dy * 15, 0.0);
              // transformation.s
              // _positionRect = Rect.fromPoints(
              //     details.globalPosition, details.globalPosition);
              _positionRect = _positionRect.shift(details.delta * 100.0);
              _offset += details.delta;
              // print('Positioned:  $_positionRect');
            } else {
              frontCardAlign = Alignment(
                frontCardAlign.x +
                    details.delta.dx * 20 / MediaQuery.of(context).size.width,
                0,
              );
            }

            if (widget.swipeUpdateCallback != null) {
              widget.swipeUpdateCallback(details, frontCardAlign);
            }
          });
        },
        onPanEnd: (final details) {
          animateCards(TriggerDirection.none);
        },
      ),
    ));
    return cards;
  }

  void animateCards(TriggerDirection trigger) {
    if (_animationController.isAnimating ||
        _currentFront + widget._stackNum == 0) {
      return;
    }
    _trigger = trigger;
    _animationController.stop();
    _animationController.value = 0.0;
    _animationController.forward();
  }

  void triggerSwap(TriggerDirection trigger) {
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
    // print('------------------- initialise transformation 0,0,0');
    // transformation = Matrix4.translationValues(0.0, 0.0, 0.0);
    _offset = Offset.zero;
    _positionRect = Rect.fromLTRB(
        0.0, 0.0, widget._cardSize.width, widget._cardSize.height);

    _currentFront = widget._totalNum - widget._stackNum;

    frontCardAlign = widget._cardAligns[widget._cardAligns.length - 1];

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget._animDuration,
      ),
    );

    _animationController.addListener(() => setState(() {}));

    _animationController.addStatusListener(
      (final status) {
        final index = widget._totalNum - widget._stackNum - _currentFront;

        if (status == AnimationStatus.completed) {
          CardSwipeOrientation orientation;

          if (frontCardAlign.x < -widget._swipeEdge) {
            orientation = CardSwipeOrientation.left;
          } else if (frontCardAlign.x > widget._swipeEdge) {
            orientation = CardSwipeOrientation.right;
          } else if (frontCardAlign.y < -widget._swipeEdgeVertical) {
            orientation = CardSwipeOrientation.up;
          } else if (frontCardAlign.y > widget._swipeEdgeVertical) {
            orientation = CardSwipeOrientation.down;
          } else {
            frontCardAlign = widget._cardAligns[widget._stackNum - 1];
            orientation = CardSwipeOrientation.recover;
          }

          if (widget.swipeCompleteCallback != null) {
            widget.swipeCompleteCallback(orientation, index);
          }

          if (orientation != CardSwipeOrientation.recover) changeCardOrder();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.cardController?.addListener(triggerSwap);

    return Stack(
        // overflow: ,
        clipBehavior: Clip.none,
        children: _buildCards(context));
  }

  void changeCardOrder() {
    setState(() {
      _currentFront--;
      frontCardAlign = widget._cardAligns[widget._stackNum - 1];
    });
  }
}

typedef CardBuilder = Widget Function(BuildContext context, int index);

enum CardSwipeOrientation { left, right, recover, up, down }

/// swipe card to [CardSwipeOrientation.left] or [CardSwipeOrientation.right]
/// , [CardSwipeOrientation.recover] means back to start.
typedef CardSwipeCompleteCallback = void Function(
    CardSwipeOrientation orientation, int index);

/// [DragUpdateDetails] of swiping card.
typedef CardDragUpdateCallback = void Function(
    DragUpdateDetails details, Alignment align);

enum AmassOrientation { top, bottom, left, right }

class CardAnimation {
  /*static Animation<Alignment> frontCardAlign(
    AnimationController controller,
    Alignment beginAlign,
    Alignment baseAlign,
    double swipeEdge,
    bool swipeUp,
    bool swipeDown,
  ) {
    double endX, endY;

    if (_TinderSwapCardState._trigger == TriggerDirection.none) {
      // onPanEnd
      endX = beginAlign.x > 0
          ? (beginAlign.x > swipeEdge ? beginAlign.x + 10.0 : baseAlign.x)
          : (beginAlign.x < -swipeEdge ? beginAlign.x - 10.0 : baseAlign.x);
      endY = beginAlign.x > 3.0 || beginAlign.x < -swipeEdge
          ? beginAlign.y
          : baseAlign.y;

      if (swipeUp || swipeDown) {
        if (beginAlign.y < 0) {
          if (swipeUp) {
            endY =
                beginAlign.y < -swipeEdge ? beginAlign.y - 10.0 : baseAlign.y;
          }
        } else if (beginAlign.y > 0) {
          if (swipeDown) {
            endY = beginAlign.y > swipeEdge ? beginAlign.y + 10.0 : baseAlign.y;
          }
        }
      }
    } else if (_TinderSwapCardState._trigger == TriggerDirection.left) {
      endX = beginAlign.x - swipeEdge;
      endY = beginAlign.y + 0.5;
    }
    */ /* Trigger Swipe Up or Down */ /*
    else if (_TinderSwapCardState._trigger == TriggerDirection.up ||
        _TinderSwapCardState._trigger == TriggerDirection.down) {
      var beginY =
          _TinderSwapCardState._trigger == TriggerDirection.up ? -10 : 10;

      endY = beginY < -swipeEdge ? beginY - 10.0 : baseAlign.y;

      endX = beginAlign.x > 0
          ? (beginAlign.x > swipeEdge ? beginAlign.x + 10.0 : baseAlign.x)
          : (beginAlign.x < -swipeEdge ? beginAlign.x - 10.0 : baseAlign.x);
    } else {
      endX = beginAlign.x + swipeEdge;
      endY = beginAlign.y + 0.5;
    }
    return AlignmentTween(
      begin: beginAlign,
      end: Alignment(endX, endY),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }*/

  static Animation<Offset> frontCardOffset(
    AnimationController controller,
    Offset beginOffset,
    Offset baseOffset,
    double swipeEdge,
    bool swipeUp,
    bool swipeDown,
  ) {
    double endX, endY;

    if (_TinderSwapCardState._trigger == TriggerDirection.none) {
      // onPanEnd
      endX = beginOffset.dx > 0
          ? (beginOffset.dx > swipeEdge ? beginOffset.dx + 10.0 : baseOffset.dx)
          : (beginOffset.dx < -swipeEdge
              ? beginOffset.dx - 10.0
              : baseOffset.dx);
      endY = beginOffset.dx > 3.0 || beginOffset.dx < -swipeEdge
          ? beginOffset.dy
          : baseOffset.dy;

      if (swipeUp || swipeDown) {
        if (beginOffset.dy < 0) {
          if (swipeUp) {
            endY = beginOffset.dy < -swipeEdge
                ? beginOffset.dy - 10.0
                : baseOffset.dy;
          }
        } else if (beginOffset.dy > 0) {
          if (swipeDown) {
            endY = beginOffset.dy > swipeEdge
                ? beginOffset.dy + 10.0
                : baseOffset.dy;
          }
        }
      }
    } else if (_TinderSwapCardState._trigger == TriggerDirection.left) {
      endX = beginOffset.dx - swipeEdge;
      endY = beginOffset.dy + 0.5;
    }
    /* Trigger Swipe Up or Down */
    else if (_TinderSwapCardState._trigger == TriggerDirection.up ||
        _TinderSwapCardState._trigger == TriggerDirection.down) {
      var beginY =
          _TinderSwapCardState._trigger == TriggerDirection.up ? -10 : 10;

      endY = beginY < -swipeEdge ? beginY - 10.0 : baseOffset.dy;

      endX = beginOffset.dx > 0
          ? (beginOffset.dx > swipeEdge ? beginOffset.dx + 10.0 : baseOffset.dx)
          : (beginOffset.dx < -swipeEdge
              ? beginOffset.dx - 10.0
              : baseOffset.dx);
    } else {
      endX = beginOffset.dx + swipeEdge;
      endY = beginOffset.dy + 0.5;
    }

    // print('endX: $endX, begin.x: ${beginOffset.dx}, swipeEdge: $swipeEdge');

    return Tween<Offset>(
      begin: beginOffset,
      end: Offset(endX, endY),
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<double> frontCardRota(
      AnimationController controller, double beginRot) {
    return Tween(begin: beginRot, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<double> backCardScale(
    AnimationController controller,
    double beginScale,
    double endScale,
  ) {
    return Tween<double>(begin: beginScale, end: endScale).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  static Animation<Alignment> backCardAlign(
    AnimationController controller,
    Alignment beginAlign,
    Alignment endAlign,
  ) {
    return AlignmentTween(begin: beginAlign, end: endAlign).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }
}

typedef TriggerListener = void Function(TriggerDirection trigger);

class CardController {
  TriggerListener _listener;

  void triggerLeft() {
    if (_listener != null) {
      _listener(TriggerDirection.left);
    }
  }

  void triggerRight() {
    if (_listener != null) {
      _listener(TriggerDirection.right);
    }
  }

  void triggerUp() {
    if (_listener != null) {
      _listener(TriggerDirection.up);
    }
  }

  void triggerDown() {
    if (_listener != null) {
      _listener(TriggerDirection.down);
    }
  }

  // ignore: use_setters_to_change_properties
  void addListener(final TriggerListener listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }
}
