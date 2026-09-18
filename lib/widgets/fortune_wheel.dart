import 'dart:math';
import 'package:flutter/material.dart';

/// 转盘数据项
class WheelItem {
  final int id;
  final String label;
  final Color color;

  const WheelItem({
    required this.id,
    required this.label,
    required this.color,
  });
}

/// 转盘组件
class FortuneWheel extends StatefulWidget {
  final List<WheelItem> items;
  final ValueChanged<WheelItem>? onSpinEnd;
  final double size;

  const FortuneWheel({
    super.key,
    required this.items,
    this.onSpinEnd,
    this.size = 280,
  });

  @override
  State<FortuneWheel> createState() => _FortuneWheelState();
}

class _FortuneWheelState extends State<FortuneWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void spin() {
    if (_isSpinning || widget.items.isEmpty) return;

    setState(() => _isSpinning = true);

    // 随机旋转 3-6 圈 + 随机偏移
    final random = Random();
    final extraRotations = 3 + random.nextInt(4);
    final randomOffset = random.nextDouble() * 2 * pi;
    final targetAngle = _currentAngle + extraRotations * 2 * pi + randomOffset;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));

    _controller.reset();
    _controller.forward().then((_) {
      _currentAngle = targetAngle;
      setState(() => _isSpinning = false);

      // 计算选中的项目
      final selected = _getSelectedIndex();
      if (selected != null && widget.onSpinEnd != null) {
        widget.onSpinEnd!(widget.items[selected]);
      }
    });
  }

  int? _getSelectedIndex() {
    if (widget.items.isEmpty) return null;
    final sliceAngle = 2 * pi / widget.items.length;
    // 指针在顶部（-pi/2方向），需要调整角度
    final normalizedAngle = (_currentAngle % (2 * pi));
    final adjustedAngle = (2 * pi - normalizedAngle + pi / 2) % (2 * pi);
    final index = (adjustedAngle / sliceAngle).floor() % widget.items.length;
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 转盘
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _WheelPainter(items: widget.items),
                ),
              );
            },
          ),
          // 中心按钮
          GestureDetector(
            onTap: spin,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isSpinning ? '...' : 'GO',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          // 顶部指针
          Positioned(
            top: 0,
            child: Icon(
              Icons.arrow_drop_down,
              size: 32,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// 转盘绘制器
class _WheelPainter extends CustomPainter {
  final List<WheelItem> items;

  _WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / items.length;

    for (var i = 0; i < items.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      final sweepAngle = sliceAngle;

      // 绘制扇形
      final paint = Paint()
        ..color = items[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // 绘制文字
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final textCenter = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}