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

  final List<Size> _cardSizes = [];

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
    double minWidth,
    double minHeight,
    bool allowVerticalMovement = true,
    this.cardController,
    this.swipeCompleteCallback,
    this.swipeUpdateCallback,
  })  : assert(stackNum > 1),
        assert(swipeEdge > 0),
        assert(swipeEdgeVertical > 0),
        assert(maxWidth > minWidth && maxHeight > minHeight),
        _cardBuilder = cardBuilder,
        _totalNum = totalNum,
        _stackNum = stackNum,
        _animDuration = animDuration,
        _swipeEdge = swipeEdge,
        _swipeEdgeVertical = swipeEdgeVertical,
        _swipeUp = swipeUp,
        _swipeDown = swipeDown,
        _allowVerticalMovement = allowVerticalMovement {
    final widthGap = maxWidth - minWidth;
    final heightGap = maxHeight - minHeight;

    for (var i = 0; i < _stackNum; i++) {
      _cardSizes.add(
        Size(minWidth + (widthGap / _stackNum) * i,
            minHeight + (heightGap / _stackNum) * i),
      );

      switch (orientation) {
        case AmassOrientation.bottom:
          _cardAligns.add(
            Alignment(
              0.0,
              (0.5 / (_stackNum - 1)) * (stackNum - i),
            ),
          );
          break;
        case AmassOrientation.top:
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

  AnimationController _animationController;

  int _currentFront;

  static TriggerDirection _trigger;

  Widget _buildCard(BuildContext context, int realIndex) {
    if (realIndex < 0) {
      return Container();
    }
    final index = realIndex - _currentFront;

    if (index == widget._stackNum - 1) {
      return Align(
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
        child: Transform.rotate(
          angle: (pi / 180.0) *
              (_animationController.status == AnimationStatus.forward
                  ? CardAnimation.frontCardRota(
                          _animationController, frontCardAlign.x)
                      .value
                  : frontCardAlign.x),
          child: SizedBox.fromSize(
            size: widget._cardSizes[index],
            child: widget._cardBuilder(
              context,
              widget._totalNum - realIndex - 1,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: _animationController.status == AnimationStatus.forward &&
              (frontCardAlign.x > 3.0 ||
                  frontCardAlign.x < -3.0 ||
                  frontCardAlign.y > 3 ||
                  frontCardAlign.y < -3)
          ? CardAnimation.backCardAlign(
              _animationController,
              widget._cardAligns[index],
              widget._cardAligns[index + 1],
            ).value
          : widget._cardAligns[index],
      child: SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward &&
                (frontCardAlign.x > 3.0 ||
                    frontCardAlign.x < -3.0 ||
                    frontCardAlign.y > 3 ||
                    frontCardAlign.y < -3)
            ? CardAnimation.backCardSize(
                _animationController,
                widget._cardSizes[index],
                widget._cardSizes[index + 1],
              ).value
            : widget._cardSizes[index],
        child: widget._cardBuilder(
          context,
          widget._totalNum - realIndex - 1,
        ),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    final cards = <Widget>[];

    for (var i = _currentFront; i < _currentFront + widget._stackNum; i++) {
      cards.add(_buildCard(context, i));
    }

    cards.add(SizedBox.expand(
      child: GestureDetector(
        onPanUpdate: (final details) {
          setState(() {
            if (widget._allowVerticalMovement == true) {
              frontCardAlign = Alignment(
                frontCardAlign.x +
                    details.delta.dx * 20 / MediaQuery.of(context).size.width,
                frontCardAlign.y +
                    details.delta.dy * 30 / MediaQuery.of(context).size.height,
              );
            } else {
              frontCardAlign = Alignment(
                frontCardAlign.x +
                    details.delta.dx * 20 / MediaQuery.of(context).size.width,
                0,
              );

              if (widget.swipeUpdateCallback != null) {
                widget.swipeUpdateCallback(details, frontCardAlign);
              }
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

    return Stack(children: _buildCards(context));
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
  static Animation<Alignment> frontCardAlign(
    AnimationController controller,
    Alignment beginAlign,
    Alignment baseAlign,
    double swipeEdge,
    bool swipeUp,
    bool swipeDown,
  ) {
    double endX, endY;

    if (_TinderSwapCardState._trigger == TriggerDirection.none) {
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
    /* Trigger Swipe Up or Down */
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

  static Animation<Size> backCardSize(
    AnimationController controller,
    Size beginSize,
    Size endSize,
  ) {
    return SizeTween(begin: beginSize, end: endSize).animate(
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
