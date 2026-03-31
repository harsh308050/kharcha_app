import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

class SyncProgressCircle extends StatefulWidget {
  final double progress;
  final String statusText;
  final bool animate;
  final double size;
  final double strokeWidth;
  final Color ringColor;
  final Color fillColor;
  final Color percentColor;
  final Color statusBackgroundColor;
  final Color statusTextColor;

  const SyncProgressCircle({
    super.key,
    required this.progress,
    this.statusText = 'Scanning...',
    this.animate = true,
    this.size = 320,
    this.strokeWidth = 16,
    this.ringColor = AppColors.primary,
    this.fillColor = AppColors.grey,
    this.percentColor = AppColors.black,
    this.statusBackgroundColor = AppColors.transparent,
    this.statusTextColor = AppColors.primaryDark,
  });

  @override
  State<SyncProgressCircle> createState() => _SyncProgressCircleState();
}

class _SyncProgressCircleState extends State<SyncProgressCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.animate) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SyncProgressCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_rotationController.isAnimating) {
      _rotationController.repeat();
      return;
    }

    if (!widget.animate && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double safeProgress = widget.progress.clamp(0.0, 1.0);
    final int percent = (safeProgress * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CircleProgressPainter(
              progress: safeProgress,
              strokeWidth: widget.strokeWidth,
              ringColor: widget.ringColor,
              fillColor: widget.fillColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonText(
                '$percent%',
                style: TextStyle(
                  fontSize: widget.size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: widget.percentColor,
                  height: 0.95,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.statusBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: Icon(
                        Icons.sync,
                        size: 26,
                        color: widget.statusTextColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    CommonText(
                      widget.statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: widget.statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color ringColor;
  final Color fillColor;

  _CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.ringColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide / 2) - (strokeWidth / 2);

    final Paint fillPaint = Paint()..color = fillColor;
    canvas.drawCircle(center, radius - (strokeWidth / 2), fillPaint);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withValues(alpha: 0.25);

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = ringColor;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.fillColor != fillColor;
  }
}