import 'package:flutter/material.dart';

class SlideToConfirmButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String text;
  final bool isLoading;

  const SlideToConfirmButton({
    super.key,
    required this.onSlideComplete,
    required this.text,
    this.isLoading = false,
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

  double _dragValue = 0.0;
  bool _isDragging = false;

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

    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isLoading) return;

    setState(() {
      _isDragging = true;
      _dragValue = (details.localPosition.dx /
              (MediaQuery.of(context).size.width - 80))
          .clamp(0.0, 1.0);
    });
    _floatingController.stop();
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isLoading) return;

    if (_dragValue > 0.8) {
      _controller.forward().then((_) {
        widget.onSlideComplete();
        _controller.reset();
        setState(() {
          _dragValue = 0.0;
          _isDragging = false;
        });
        _floatingController.repeat(reverse: true);
      });
    } else {
      setState(() {
        _dragValue = 0.0;
        _isDragging = false;
      });
      _floatingController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: widget.isLoading ? Colors.grey : Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Texto de fundo
          Center(
            child:
                widget.isLoading
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Processando...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),

          if (!widget.isLoading)
            AnimatedBuilder(
              animation: Listenable.merge([
                _slideAnimation,
                _floatingAnimation,
              ]),
              builder: (context, child) {
                double slidePosition =
                    _isDragging ? _dragValue : _slideAnimation.value;

                double floatingOffset =
                    (!_isDragging && slidePosition == 0)
                        ? _floatingAnimation.value
                        : 0;

                return Positioned(
                  left:
                      4 +
                      slidePosition * (MediaQuery.of(context).size.width - 90) +
                      floatingOffset,
                  top: 6,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
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
                      child: Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFE91E63),
                        size: 24,
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
