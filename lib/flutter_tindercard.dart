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
    double swipeEdge = 75.0,
    double swipeEdgeVertical = 100.0,
    bool swipeUp = false,
    bool swipeDown = false,
    double maxWidth,
    double maxHeight,
    double scaleFactor = 0.8,
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
    double scale = 1;
    double dy = 0;
    for (int i = 0; i < stackNum; i++) {
      _cardScales.add(scale);

      switch (orientation) {
        case AmassOrientation.top:
          _cardAligns.add(
            Alignment(0.0, scale - (1 + dy)),
          );
          break;
        case AmassOrientation.bottom:
          _cardAligns.add(
            Alignment(0.0, 1 + dy - scale),
          );
          break;
        case AmassOrientation.left:
          _cardAligns.add(
            Alignment(
              -9 * (1 + dy - scale),
              0.0,
            ),
          );
          break;
        case AmassOrientation.right:
          _cardAligns.add(
            Alignment(
              9 * (1 + dy - scale),
              0,
            ),
          );
          break;
      }

      scale *= scaleFactor;
      dy += .05 * scale;
    }
  }
}

class _TinderSwapCardState extends State<TinderSwapCard>
    with TickerProviderStateMixin {
  Offset _dragPoint;

  Offset _offset = Offset.zero;

  AnimationController _animationController;

  static TriggerDirection _trigger;

  Widget _buildCard(BuildContext context, index) {
    final Widget card = SizedBox.fromSize(
        size: widget._cardSize, child: widget._cardBuilder(context, index));

    // When user likes/dislikes by button rotate about the card centre
    if (_dragPoint == null) {
      _dragPoint =
          Offset(widget._cardSize.width / 2, widget._cardSize.height / 2);
    }

    if (index == 0) {
      // Rotate about the user's finger, the opposite end has resistance
      final angle = (_dragPoint.dy > widget._cardSize.height / 2 ? -1 : 1) *
          .001 *
          (_animationController.status == AnimationStatus.forward
              ? CardAnimation.frontCardRota(_animationController, _offset.dx,
                      endRot: _offset.dx / 2)
                  .value
              : _offset.dx);

      _offset = _animationController.status == AnimationStatus.forward
          ? CardAnimation.frontCardOffset(
                  _animationController,
                  _offset,
                  Offset(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  widget._swipeEdge,
                  widget._swipeUp,
                  widget._swipeDown)
              .value
          : _offset;

      final transformation = Matrix4.identity();
      transformation.translate(_offset.dx, _offset.dy);
      transformation.translate(_dragPoint.dx, _dragPoint.dy);
      transformation.rotateZ(angle);
      transformation.translate(-_dragPoint.dx, -_dragPoint.dy);

      return Align(child: Transform(transform: transformation, child: card));
    }

    final prepareNextCard = _offset.dx > widget._swipeEdge ||
        _offset.dx < -widget._swipeEdge ||
        _offset.dy > widget._swipeEdgeVertical ||
        _offset.dy < -widget._swipeEdgeVertical;

    return Align(
      alignment: _animationController.status == AnimationStatus.forward &&
              prepareNextCard
          ? CardAnimation.backCardAlign(
              _animationController,
              widget._cardAligns[index],
              widget._cardAligns[index - 1],
            ).value
          : widget._cardAligns[index],
      child: Transform.scale(
        scale: _animationController.status == AnimationStatus.forward &&
                prepareNextCard
            ? CardAnimation.backCardScale(
                _animationController,
                widget._cardScales[index],
                widget._cardScales[index - 1],
              ).value
            : widget._cardScales[index],
        child: card,
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    final cards = <Widget>[];

    int i = min(widget._stackNum, widget._totalNum);
    while (i-- != 0) {
      cards.add(_buildCard(context, i));
    }

    cards.add(SizedBox.expand(
      child: GestureDetector(
        onPanStart: (DragStartDetails details) {
          _dragPoint = details.localPosition;
        },
        onPanUpdate: (final details) {
          setState(() {
            if (widget._allowVerticalMovement == true) {
              _offset += details.delta;
              // print('offset: $_offset');
            } else {
              _offset = Offset(_offset.dx + details.delta.dx, 0);
            }

            if (widget.swipeUpdateCallback != null) {
              widget.swipeUpdateCallback(details, _offset);
            }
          });
        },
        onPanEnd: (final DragEndDetails details) {
          animateCards(TriggerDirection.none);
        },
      ),
    ));
    return cards;
  }

  void animateCards(TriggerDirection trigger) {
    if (_animationController.isAnimating) {
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

  /// support for asynchronous data events
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
    _offset = Offset.zero;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget._animDuration,
      ),
    );

    _animationController.addListener(() => setState(() {}));

    _animationController.addStatusListener(
      (final status) {
        if (status == AnimationStatus.completed) {
          CardSwipeOrientation orientation;

          if (_offset.dx < -widget._swipeEdge) {
            orientation = CardSwipeOrientation.left;
          } else if (_offset.dx > widget._swipeEdge) {
            orientation = CardSwipeOrientation.right;
          } else if (_offset.dy < -widget._swipeEdgeVertical) {
            orientation = CardSwipeOrientation.up;
          } else if (_offset.dy > widget._swipeEdgeVertical) {
            orientation = CardSwipeOrientation.down;
          } else {
            orientation = CardSwipeOrientation.recover;
          }

          if (widget.swipeCompleteCallback != null) {
            widget.swipeCompleteCallback(orientation);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.cardController?.addListener(triggerSwap);

    return Stack(clipBehavior: Clip.none, children: _buildCards(context));
  }
}

typedef CardBuilder = Widget Function(BuildContext context, int index);

enum CardSwipeOrientation { left, right, recover, up, down }

/// swipe card to [CardSwipeOrientation.left] or [CardSwipeOrientation.right]
/// , [CardSwipeOrientation.recover] means back to start.
typedef CardSwipeCompleteCallback = void Function(
    CardSwipeOrientation orientation);

/// [DragUpdateDetails] of swiping card.
typedef CardDragUpdateCallback = void Function(
    DragUpdateDetails details, Offset offset);

enum AmassOrientation { top, bottom, left, right }

class CardAnimation {
  static Animation<Offset> frontCardOffset(
    AnimationController controller,
    Offset beginOffset,
    Offset screenOffset,
    double swipeEdge,
    bool swipeUp,
    bool swipeDown,
  ) {
    double endX, endY;

    // onPanEnd
    if (_TinderSwapCardState._trigger == TriggerDirection.none) {
      // need to multiply screenOffset.dx so that the trailing corner doesn't hang around
      endX = beginOffset.dx > 0
          ? (beginOffset.dx > swipeEdge ? screenOffset.dx * 1.5 : 0)
          : (beginOffset.dx < -swipeEdge ? -screenOffset.dx * 1.5 : 0);
      endY = beginOffset.dx > swipeEdge || beginOffset.dx < -swipeEdge
          ? beginOffset.dy
          : 0;

      if (swipeUp || swipeDown) {
        if (beginOffset.dy < 0) {
          if (swipeUp) {
            endY = beginOffset.dy < -swipeEdge
                ? beginOffset.dy - screenOffset.dy
                : 0;
          }
        } else if (beginOffset.dy > 0) {
          if (swipeDown) {
            endY = beginOffset.dy > swipeEdge
                ? beginOffset.dy + screenOffset.dy
                : 0;
          }
        }
      }
    } else if (_TinderSwapCardState._trigger == TriggerDirection.left) {
      endX = -screenOffset.dx * 1.5;
      endY = beginOffset.dy + 0.5;
    }
    /* Trigger Swipe Up or Down */
    else if (_TinderSwapCardState._trigger == TriggerDirection.up ||
        _TinderSwapCardState._trigger == TriggerDirection.down) {
      var beginY =
          _TinderSwapCardState._trigger == TriggerDirection.up ? -10 : 10;

      endY = beginY < -swipeEdge ? beginY - 10.0 : screenOffset.dy;

      endX = beginOffset.dx > 0
          ? (beginOffset.dx > swipeEdge
              ? beginOffset.dx + 10.0
              : screenOffset.dx)
          : (beginOffset.dx < -swipeEdge
              ? beginOffset.dx - 10.0
              : screenOffset.dx);
    } else {
      endX = screenOffset.dx * 1.5;
      endY = beginOffset.dy + 0.5;
    }

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
      AnimationController controller, double beginRot,
      {double endRot = 0.0}) {
    return Tween(begin: beginRot, end: endRot).animate(
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
