import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SlideToConfirmButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String text;
  final bool isLoading;
  final bool isEnabled;

  const SlideToConfirmButton({
    super.key,
    required this.onSlideComplete,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  SlideToConfirmButtonState createState() => SlideToConfirmButtonState();
}

class SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  late AnimationController _loadingController;
  late Animation<double> _loadingSlideAnimation;

  double _dragValue = 0.0;
  bool _isDragging = false;
  bool _wasLoading = false;
  ScrollHoldController? _scrollHold;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _floatingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _floatingAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _loadingController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _loadingSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SlideToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading && !_wasLoading) {
      _floatingController.stop();
      _wasLoading = true;
    }

    if (!widget.isLoading && _wasLoading) {
      _loadingController.reverse().then((_) {
        if (!widget.isLoading && mounted) {
          _floatingController.repeat(reverse: true);
        }
      });
      _wasLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color:
            widget.isLoading || !widget.isEnabled
                ? Colors.grey
                : Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Texto de fundo
          Center(
            child: Text(
              widget.isLoading ? "Processando..." : widget.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (widget.isEnabled)
            AnimatedBuilder(
              animation: Listenable.merge([
                _slideAnimation,
                _floatingAnimation,
                _loadingSlideAnimation,
              ]),
              builder: (context, child) {
                double slidePosition;

                if (_isDragging) {
                  slidePosition = _dragValue;
                } else if (widget.isLoading ||
                    _loadingSlideAnimation.value > 0) {
                  slidePosition = _loadingSlideAnimation.value;
                } else {
                  slidePosition = _slideAnimation.value;
                }

                double floatingOffset =
                    (!_isDragging &&
                            slidePosition == 0 &&
                            !widget.isLoading &&
                            _loadingSlideAnimation.value == 0)
                        ? _floatingAnimation.value
                        : 0;

                return Positioned(
                  left:
                      4 +
                      slidePosition * (MediaQuery.of(context).size.width - 90) +
                      floatingOffset,
                  top: 6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onHorizontalDragStart: (details) {
                      if (!widget.isLoading && widget.isEnabled) {
                        final scrollableState = Scrollable.maybeOf(context);
                        _scrollHold?.cancel();
                        _scrollHold = scrollableState?.position.hold(() {});
                      }
                    },
                    onHorizontalDragUpdate:
                        widget.isLoading || !widget.isEnabled
                            ? null
                            : (details) {
                              setState(() {
                                _isDragging = true;
                                _dragValue = (details.localPosition.dx /
                                        (MediaQuery.of(context).size.width -
                                            80))
                                    .clamp(0.0, 1.0);
                              });
                              _floatingController.stop();
                            },
                    onHorizontalDragEnd:
                        widget.isLoading || !widget.isEnabled
                            ? null
                            : (details) {
                              _scrollHold?.cancel();
                              _scrollHold = null;

                              if (_dragValue > 0.8) {
                                _controller.forward().then((_) {
                                  _loadingController.value = 1.0;
                                  widget.onSlideComplete();
                                  _controller.reset();
                                  setState(() {
                                    _dragValue = 0.0;
                                    _isDragging = false;
                                  });
                                });
                              } else {
                                setState(() {
                                  _dragValue = 0.0;
                                  _isDragging = false;
                                });
                                _floatingController.repeat(reverse: true);
                              }
                            },
                    child: Container(
                      width: 50,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child:
                            widget.isLoading
                                ? SizedBox(
                                  key: ValueKey('spinner'),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFE91E63),
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : Icon(
                                  key: ValueKey('arrow'),
                                  Icons.arrow_forward,
                                  color: Color(0xFFE91E63),
                                  size: 24,
                                ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
