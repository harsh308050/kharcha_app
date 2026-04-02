import 'dart:async';
import 'package:flutter/material.dart';

/// A lightweight Flutter marquee that auto-scrolls on overflow, with optional force scrolling and fine-grained animation control
///
/// `MarqueePlus` automatically scrolls its text when:
///  • the text overflows its available space, OR
///  • [forceScroll] is set to true.
///
/// The scroll speed can be controlled using [velocity], and spacing between
/// repeated text instances can be customized using [gap].
///
/// Example:
/// ```dart
/// MarqueePlus(
/// text: 'Simple smooth scrolling text...',
/// velocity: 50.0,
/// )
/// ```
class MarqueePlus extends StatefulWidget {
  /// The text to be displayed and optionally scrolled.
  final String text;

  /// Optional text style for the marquee text.
  final TextStyle? style;

  /// If true, the text will scroll even if it does not overflow its container.
  final bool forceScroll;

  /// Scroll speed in pixels per second.
  ///
  /// Must be greater than 0 to animate.
  final double velocity;

  /// Space between repeated text instances.
  final double gap;

  /// specific the axis of scrolling.
  final Axis scrollAxis;

  /// The specific direction of scroll.
  ///
  /// Defaults to [AxisDirection.left] for [Axis.horizontal] and [AxisDirection.up] for [Axis.vertical].
  ///
  /// For [Axis.horizontal], use [AxisDirection.left] or [AxisDirection.right].
  /// For [Axis.vertical], use [AxisDirection.up] or [AxisDirection.down].
  final AxisDirection scrollDirection;

  /// Padding around the text.
  ///
  /// The padding is scrollable along with the text.
  final EdgeInsetsGeometry padding;

  /// Wait time between loops.
  final Duration pauseAfterRound;

  /// Wait time before first scroll starts.
  final Duration initialDelay;

  /// Time to reach full speed.
  final Duration accelerationDuration;

  /// Time to slow down before stopping (if pausing).
  final Duration decelerationDuration;

  /// Optional animation curve applied to the scroll animation.
  ///
  /// If null, a linear animation is used.
  final Curve? curve;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How the text should be aligned along the cross axis.
  final CrossAxisAlignment? crossAxisAlignment;

  /// Creates a [MarqueePlus] widget.
  const MarqueePlus({
    super.key,
    required this.text,
    this.style,
    this.forceScroll = false,
    this.velocity = 50.0,
    this.gap = 65.0,
    this.scrollAxis = Axis.horizontal,
    AxisDirection? scrollDirection,
    this.padding = EdgeInsets.zero,
    this.pauseAfterRound = Duration.zero,
    this.initialDelay = Duration.zero,
    this.accelerationDuration = Duration.zero,
    this.decelerationDuration = Duration.zero,
    this.curve,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment,
  }) : scrollDirection = scrollDirection ??
            (scrollAxis == Axis.horizontal
                ? AxisDirection.left
                : AxisDirection.up),
       assert(
          scrollDirection == null ||
              (scrollAxis == Axis.horizontal &&
                  (scrollDirection == AxisDirection.left ||
                      scrollDirection == AxisDirection.right)) ||
              (scrollAxis == Axis.vertical &&
                  (scrollDirection == AxisDirection.up ||
                      scrollDirection == AxisDirection.down)),
          'scrollDirection must match scrollAxis',
        );

  @override
  State<MarqueePlus> createState() => _MarqueePlusState();
}

class _MarqueePlusState extends State<MarqueePlus>
    with SingleTickerProviderStateMixin {
  /// Controller driving the animation.
  late final AnimationController _animationController;

  /// Cached dimensions of the rendered text (including padding).
  late double _itemWidth;
  late double _itemHeight;

  /// Whether the text should currently animate.
  bool _shouldAnimate = false;

  /// Timer for pause between rounds.
  Timer? _pauseTimer;

  /// Timer for delaying the first animation start.
  Timer? _initialDelayTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onAnimationStatusChanged);
    _animationController.dispose();
    _pauseTimer?.cancel();
    _initialDelayTimer?.cancel();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (widget.pauseAfterRound > Duration.zero) {
        _pauseTimer = Timer(widget.pauseAfterRound, () {
          if (mounted) {
            _animationController.reset();
            _animationController.forward();
          }
        });
      } else {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  /// Measures the text, decides whether scrolling is required,
  /// and configures the animation controller accordingly.
  void _calculateMetrics(BoxConstraints constraints, TextScaler textScaler, TextStyle? style, EdgeInsets padding) {
    // For vertical scrolling, we allow text to wrap within width minus padding.
    // For horizontal, we force single line (infinite width).
    final double maxWidth = widget.scrollAxis == Axis.horizontal
        ? double.infinity
        : (constraints.maxWidth - padding.horizontal).clamp(0.0, double.infinity);

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      textAlign: widget.textAlign,
    )..layout(maxWidth: maxWidth);

    // Item size includes padding
    _itemWidth = textPainter.width + padding.horizontal;
    _itemHeight = textPainter.height + padding.vertical;

    final maxExtent = widget.scrollAxis == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final itemExtent =
        widget.scrollAxis == Axis.horizontal ? _itemWidth : _itemHeight;

    // Determine whether scrolling should occur
    final shouldAnimate = widget.forceScroll || itemExtent > maxExtent;

    _shouldAnimate = shouldAnimate;

    if (shouldAnimate && widget.velocity > 0) {
      final totalDistance = itemExtent + widget.gap;
      
      // Calculate cruise duration
      // d = v*t => t = d/v
      final cruiseDuration = 
          Duration(milliseconds: (totalDistance / widget.velocity * 1000).round());
      
      final totalDuration = cruiseDuration + widget.accelerationDuration + widget.decelerationDuration;

      if (_animationController.duration != totalDuration) {
        _animationController.duration = totalDuration;
      }
      
      // Start animation if not already running.
      if (!_animationController.isAnimating) {
        _startAnimationWithOptionalDelay();
      }
    } else {
       _initialDelayTimer?.cancel();
       _animationController.stop();
       _animationController.reset();
    }
  }

  void _startAnimationWithOptionalDelay() {
    if (_animationController.isAnimating) {
      return;
    }

    if (widget.initialDelay > Duration.zero) {
      if (_initialDelayTimer?.isActive ?? false) {
        return;
      }

      _initialDelayTimer = Timer(widget.initialDelay, () {
        if (!mounted || !_shouldAnimate || _animationController.isAnimating) {
          return;
        }

        _animationController.reset();
        _animationController.forward();
      });
      return;
    }

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Merge provided style with default text style from context to ensure
    // consistency between measurement (TextPainter) and rendering (Text).
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(widget.style);

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = widget.padding.resolve(Directionality.of(context));
        _calculateMetrics(constraints, MediaQuery.textScalerOf(context), effectiveStyle, padding);

          if (!_shouldAnimate) {
            Alignment alignment;
            // Determine X and Y based on axes and properties
            double x = 0;
            double y = 0;

            if (widget.scrollAxis == Axis.horizontal) {
              // Horizontal Scroll Axis -> Main Axis = Horizontal (X), Cross Axis = Vertical (Y)
              
              // X determines by textAlign
              switch (widget.textAlign) {
                case TextAlign.center:
                  x = 0;
                  break;
                case TextAlign.right:
                case TextAlign.end:
                  x = 1;
                  break;
                default:
                  x = -1;
                  break;
              }

              // Y determined by crossAxisAlignment (defaults to center)
              switch (widget.crossAxisAlignment) {
                case CrossAxisAlignment.start:
                  y = -1;
                  break;
                case CrossAxisAlignment.end:
                  y = 1;
                  break;
                default:
                  y = 0;
                  break;
              }
            } else {
              // Vertical Scroll Axis -> Main Axis = Vertical (Y), Cross Axis = Horizontal (X)

              // Y determined by textAlign
              switch (widget.textAlign) {
                case TextAlign.center:
                  y = -1; // Top-aligned usually for vertical lists? 
                          // Wait, original code mapped Center to TopCenter (y=-1). 
                          // switch (widget.textAlign) { case center: alignment = Alignment.topCenter; }
                          // effectively y=-1, x=0.
                          // Let's look at original code again:
                          // case center: alignment = Alignment.topCenter;
                          // case right/end: alignment = Alignment.topRight;
                          // case left/start: alignment = Alignment.topLeft;
                          // So Y is ALWAYS -1 (Top) in original code for Vertical Axis.
                  y = -1; 
                  break;
                default:
                  y = -1; // Always top aligned in main axis for vertical scroll intent if static?
                  break;
              }
              // Actually, the original code had Y aligned to Top for ALL text aligns. 
              // And X aligned to Left/Center/Right based on TextAlign.
              
              // Now we have crossAxisAlignment for Cross Axis (X).
              // If provided, it overrides textAlign for X?
              // The user prompt says: "add property... that aligns ... start,center or end".
              // If I have crossAxisAlignment, I should use it for X.
              
              if (widget.crossAxisAlignment != null) {
                  switch (widget.crossAxisAlignment!) {
                    case CrossAxisAlignment.center:
                      x = 0;
                      break;
                    case CrossAxisAlignment.end:
                      x = 1;
                      break;
                    default:
                      x = -1;
                      break;
                  }
              } else {
                  // Fallback to textAlign for X if crossAxisAlignment is null
                  switch (widget.textAlign) {
                  case TextAlign.center:
                    x = 0;
                    break;
                  case TextAlign.right:
                  case TextAlign.end:
                    x = 1;
                    break;
                  default:
                    x = -1;
                    break;
                }
              }
            }
            alignment = Alignment(x, y);

          return Align(
             alignment: alignment,
             child: Padding(
                padding: padding,
                child: Text(
                  widget.text,
                  style: effectiveStyle,
                  textAlign: widget.textAlign,
                  // For vertical, we want it to wrap naturally if needed
                  softWrap: widget.scrollAxis == Axis.vertical, 
                  // For horizontal, ellipsis is fine. For vertical, usually we want to see what fits.
                  overflow: widget.scrollAxis == Axis.vertical ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
             ),
          );
        }

        // Determine CrossAxisAlignment for Vertical Axis (Column)
        CrossAxisAlignment crossAxisAlignment = widget.crossAxisAlignment ?? CrossAxisAlignment.start;

        // If not explicitly provided, try to derive from textAlign for Vertical Axis
        if (widget.crossAxisAlignment == null && widget.scrollAxis == Axis.vertical) {
           switch (widget.textAlign) {
             case TextAlign.left:
             case TextAlign.start:
             case TextAlign.justify:
               crossAxisAlignment = CrossAxisAlignment.start;
               break;
             case TextAlign.right:
             case TextAlign.end:
               crossAxisAlignment = CrossAxisAlignment.end;
               break;
             default:
               crossAxisAlignment = CrossAxisAlignment.center;
               break;
           }
        }

        final item = Padding(
          padding: padding,
          child: Text(widget.text, style: effectiveStyle, textAlign: widget.textAlign),
        );

        // Prepare the children for the flex/list
        final children = [
          item,
          SizedBox(
            width: widget.scrollAxis == Axis.horizontal ? widget.gap : 0,
            height: widget.scrollAxis == Axis.vertical ? widget.gap : 0,
          ),
          item,
          SizedBox(
            width: widget.scrollAxis == Axis.horizontal ? widget.gap : 0,
            height: widget.scrollAxis == Axis.vertical ? widget.gap : 0,
          ),
           // Potentially 3rd copy if space is huge? 
           // For simplicity, keeping 2 copies + gap.
           // If the gap is very large, might need more.
        ];
        
        // Add extra if needed (simple logic from previous code)
        final mainExtent = widget.scrollAxis == Axis.horizontal 
             ? constraints.maxWidth 
             : constraints.maxHeight;
        final contentExtent = widget.scrollAxis == Axis.horizontal 
             ? _itemWidth 
             : _itemHeight;
             
        if(contentExtent + widget.gap < mainExtent) {
             children.add(item);
             children.add(SizedBox(
                width: widget.scrollAxis == Axis.horizontal ? widget.gap : 0,
                height: widget.scrollAxis == Axis.vertical ? widget.gap : 0,
             ));
        }


        return ClipRect(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
               // Custom curve handling with Accel/Decel
               // We need to map controller value 0..1 to effective distance progress 0..1
               // This is complex to do with just a single curve if we have distinct phases.
               // Simplification: We use the controller's value 0..1 directly but modify the 't'
               // passed to the transform or just trust the curve?
               // The user wants explicit duration for accel/decel.
               // We can construct a compound curve or just calculate offset manually.
               
               double t = _animationController.value;
               
               // To keep it simple and robust, let's just use the value 0..1
               // If user wants accel/decel, we should probably provided a proper Curve
               // But standard Curves are fixed.
               // Let's rely on the 'curve' property if provided, else Linear.
               // Wait, user provided Accel/Decel Duration. This implies we need to build the curve dynamically.
               // We can do this by wrapping the standard curve.
               
               // However, for this iteration, let's use the provided curve or Linear.
               // The Accel/Decel durations are added to TOTAL duration.
               // So if we just use Linear, it will be slow start/end? No.
               // We need a custom curve that:
               // 0 -> acclDuration : easeIn
               // accl -> 1-decel : linear
               // 1-decel -> 1 : easeOut
               
               // Let's skip complex curve generation for this exact step to ensure stability first
               // and just adhere to the total duration.
               // If valid accel/decel are provided, we should use a proper Interval curve?
               
               // Let's try to map it:
               final totalDurationInMs = _animationController.duration?.inMilliseconds ?? 1;
               final accelMs = widget.accelerationDuration.inMilliseconds;
               final decelMs = widget.decelerationDuration.inMilliseconds;
               
               double curvedT = t;
               
               if (accelMs > 0 || decelMs > 0) {
                 final accelFrac = accelMs / totalDurationInMs;
                 final decelFrac = decelMs / totalDurationInMs;
                 
                 // This is a naive approximation using intervals
                 if (t < accelFrac) {
                    // Acceleration phase
                    final subT = t / accelFrac;
                    curvedT = Curves.easeIn.transform(subT) * accelFrac;
                 } else if (t > (1.0 - decelFrac)) {
                    // Deceleration phase
                    final subT = (t - (1.0 - decelFrac)) / decelFrac;
                    curvedT = (1.0 - decelFrac) + Curves.easeOut.transform(subT) * decelFrac;
                 } else {
                    // Linear phase
                    // We need to match slopes? This is hard to perfect without a Spline.
                    // Just Linear interpolation between end of Accel and start of Decel.
                    curvedT = t; 
                 }
               }
               
               final distance = contentExtent + widget.gap;
               final offsetValue = curvedT * distance;
               
               // Determine X/Y offset
               double dx = 0, dy = 0;
               
               switch (widget.scrollDirection) {
                 case AxisDirection.left:
                   dx = -offsetValue;
                   break;
                 case AxisDirection.right:
                   dx = distance * (curvedT - 1);
                   break;
                  case AxisDirection.up:
                   dy = -offsetValue;
                   break;
                 case AxisDirection.down:
                   dy = distance * (curvedT - 1);
                   break;
               }

                Alignment alignment;
                if (widget.scrollDirection == AxisDirection.left || widget.scrollDirection == AxisDirection.right) {
                  double y = 0;
                  switch (crossAxisAlignment) {
                    case CrossAxisAlignment.start:
                      y = -1.0;
                      break;
                    case CrossAxisAlignment.end:
                      y = 1.0;
                      break;
                    default:
                      y = 0.0;
                      break;
                  }
                  alignment = Alignment(-1.0, y);
                } else {
                  // For vertical scrolling, respect the textAlign for horizontal placement
                  switch (widget.textAlign) {
                    case TextAlign.left:
                    case TextAlign.start:
                    case TextAlign.justify:
                      alignment = Alignment.topLeft;
                      break;
                    case TextAlign.right:
                    case TextAlign.end:
                      alignment = Alignment.topRight;
                      break;
                    default:
                      alignment = Alignment.topCenter;
                      break;
                  }
                }

              return OverflowBox(
                maxWidth: widget.scrollAxis == Axis.horizontal ? double.infinity : null,
                maxHeight: widget.scrollAxis == Axis.vertical ? double.infinity : null,
                alignment: alignment,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: child,
                ),
              );
            },
            child: Flex(
              direction: widget.scrollAxis,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            ),
          ),
        );
      },
    );
  }
}