// splash animation: cream B on green, the m piece turns yellow, slides out
// and becomes the M of "BHoardMate", then green fades to cream.
// timings and positions: docs/design/splash/SPLASH-ANIMATION.md
// usage: BHoardMateSplash(onFinished: () => /* open the login screen */)

import 'dart:math' as math;

import 'package:flutter/material.dart';

class BHoardMateSplash extends StatefulWidget {
  const BHoardMateSplash({super.key, this.onFinished});

  // Called once the animation has reached its last frame.
  final VoidCallback? onFinished;

  @override
  State<BHoardMateSplash> createState() => _BHoardMateSplashState();
}

class _BHoardMateSplashState extends State<BHoardMateSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashTimeline.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished?.call();
      });
    } else {
      _controller.forward().then((_) {
        if (mounted) widget.onFinished?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: BHoardMateSplashPainter(_controller),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// Paints one frame of the splash for [progress] (0..1 of the whole 3.2 s).
class BHoardMateSplashPainter extends CustomPainter {
  BHoardMateSplashPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = SplashTimeline.at(progress.value * SplashTimeline.seconds);
    final k = size.width / SplashTimeline.designWidth;
    final anchor = Offset(size.width / 2, size.height * s.anchorYFraction);

    canvas.drawRect(Offset.zero & size, Paint()..color = s.background);

    // ---- world: the wordmark's own coordinates, moved by a zoom + pan "camera"
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(s.zoom * k);
    canvas.translate(-s.camera.dx, -s.camera.dy);

    canvas.save();
    canvas.scale(SplashTimeline.bScale);
    canvas.drawPath(LogoPaths.stem, Paint()..color = s.bhoardColor);
    if (s.bowls > 0) {
      canvas.save();
      canvas.translate(218, 0);
      canvas.rotate(math.pi / 2);
      final stroke = _stroke(s.bhoardColor);
      for (final bowl in [LogoPaths.bowlTop, LogoPaths.bowlBottom]) {
        canvas.drawPath(s.bowls >= 1 ? bowl : _trim(bowl, s.bowls), stroke);
      }
      canvas.restore();
    }
    canvas.restore();

    for (var i = 0; i < LogoPaths.letters.length; i++) {
      final (path, isBHoard) = LogoPaths.letters[i];
      final l = s.letters[i];
      if (l.opacity <= 0) continue;
      final colour = isBHoard ? s.bhoardColor : SplashTimeline.yellow;
      canvas.save();
      canvas.translate(l.dx, 0);
      canvas.drawPath(
        path,
        Paint()..color = colour.withValues(alpha: colour.a * l.opacity),
      );
      canvas.restore();
    }
    canvas.restore();

    // ---- the yellow m / M (positioned relative to the anchor, in design px)
    canvas.save();
    canvas.translate(
      anchor.dx + s.mOffset.dx * k,
      anchor.dy + s.mOffset.dy * k,
    );
    canvas.rotate(s.mRotationDeg * math.pi / 180);
    canvas.scale(s.mScale * k);
    canvas.translate(-SplashTimeline.mPivot.dx, -SplashTimeline.mPivot.dy);
    canvas.drawPath(LogoPaths.m, _stroke(s.mColor));
    canvas.restore();
  }

  static Paint _stroke(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = 50
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter;

  static Path _trim(Path p, double t) {
    final out = Path();
    for (final metric in p.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(BHoardMateSplashPainter old) => old.progress != progress;
}

// One letter of "Hoard" / "ate": horizontal slide offset (world units) + opacity.
class LetterState {
  const LetterState(this.dx, this.opacity);
  final double dx;
  final double opacity;
}

// Everything needed to draw one frame.
class SplashState {
  const SplashState({
    required this.background,
    required this.bhoardColor,
    required this.zoom,
    required this.camera,
    required this.anchorYFraction,
    required this.bowls,
    required this.mColor,
    required this.mOffset,
    required this.mScale,
    required this.mRotationDeg,
    required this.letters,
  });

  final Color background;
  final Color bhoardColor; // B + "Hoard" (cream -> green during the hand-off)
  final double zoom; // world units -> design px
  final Offset camera; // world point shown at the anchor
  final double anchorYFraction; // anchor = (50% width, this * height)
  final double bowls; // 0..1 draw-on of the B's cream bowls
  final Color mColor;
  final Offset mOffset; // m centre relative to the anchor, design px
  final double mScale; // m-local units -> design px
  final double mRotationDeg; // clockwise; 90 = sideways in the B, 0 = upright M
  final List<LetterState> letters; // H o a r d a t e
}

// The choreography. Times in seconds; curves are Flutter Cubic(x1, y1, x2, y2),
// the same values as CSS cubic-bezier().
abstract final class SplashTimeline {
  static const double seconds = 3.2;
  static const Duration duration = Duration(milliseconds: 3200);

  static const Color green = Color(0xFF2E6B4F);
  static const Color cream = Color(0xFFFAF6EE);
  static const Color yellow = Color(0xFFF2B544);

  // ---- design canvas + logo geometry (from the SVG files)
  static const double designWidth = 1080, designHeight = 2400;
  static const double bScale = 3.0042; // B group scale in the wordmark SVG
  static const double mScaleWord = 4.4313; // M group scale in the wordmark SVG
  static const Offset mPivot = Offset(118, 80); // centre of the m stroke
  static const Offset bCenterW = Offset(109 * bScale, 118 * bScale);
  static const Offset wordCenterW = Offset(6758 / 2 - 120, 949 / 2 - 120);
  static const Offset mStartW = Offset((218 - 80) * bScale, 118 * bScale);
  static const Offset mEndW = Offset(3792 + 118 * mScaleWord, 80 * mScaleWord);

  // ---- framing (design px)
  static const double bStartHeight = 360.0; // B height on frame 1
  static const double z0 =
      bStartHeight / (236 * bScale); // camera zoom at start
  static const double z1 = 892 / 6758; // dark wordmark: viewBox 892 px wide
  static const double z2 = 800 / 6758; // login: viewBox 800 px wide
  static const double startCenterY = 1200; // 50%
  static const double loginCenterY =
      604 + 800 * 949 / 6758 / 2; // 660.17 px = 27.5%

  static final Offset mStartOffset = Offset((mStartW.dx - bCenterW.dx) * z0, 0);
  static final Offset mEndOffset = Offset(
    (mEndW.dx - wordCenterW.dx) * z1,
    (mEndW.dy - wordCenterW.dy) * z1,
  );
  static const double mStartScale = bScale * z0;
  static const double mEndScale = mScaleWord * z1;

  // ---- timing (seconds)
  static const (double, double) colour = (0.3, 0.7); // m cream -> yellow
  static const (double, double) swell = (0.36, 0.7); // m scale x1.035
  static const (double, double) windup = (
    0.7,
    0.84,
  ); // m nudges left -10.0 px, rotates +5.0 deg
  static const (double, double) travel = (
    0.84,
    1.7,
  ); // m slides out, turns upright, shrinks
  static const (double, double) landUp = (1.7, 1.82); // M pop x1 -> x1.06
  static const (double, double) landDown = (1.82, 2.04); // M settles back to x1
  static const (double, double) cameraMove = (
    0.92,
    1.7,
  ); // B shrinks + moves left
  static const (double, double) bowlsDraw = (
    1.24,
    1.52,
  ); // B's cream bowls draw back on
  static const double hoardStart = 1.38, ateStart = 1.72;
  static const double letterStagger = 0.05, letterDuration = 0.34;
  static const double letterSlide = -120.0; // world units
  static const (double, double) handoff = (2.56, 3.16); // to the login screen
  static const (double, double) invert = (
    2.758333,
    2.791667,
  ); // BHoard cream -> green (2 frames @60fps)
  static const double swellAmount = 1.035,
      windupDx = -10.0,
      windupRotation = 5.0;
  static const double arc = 56.0, landPop = 1.06;

  // ---- curves
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve glide = Cubic(0.45, 0.0, 0.25, 1.0);
  static const Curve cameraCurve = Cubic(0.65, 0.0, 0.35, 1.0);
  static const Curve rotateCurve = Cubic(
    0.5,
    0.0,
    0.3,
    1.18,
  ); // ~2 deg overshoot
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);
  static const Curve letterCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  // Where the light wordmark ends up, i.e. where the login screen should draw
  // bhoardmate-wordmark-transparent.svg (its full 6758 x 949 viewBox) so the
  // hand-off is seamless. On 1080 x 2400: Rect.fromLTWH(140, 604, 800, 112.34).
  static Rect loginWordmarkRect(Size screen) {
    final k = screen.width / designWidth;
    final w = 800 * k;
    return Rect.fromCenter(
      center: Offset(
        screen.width / 2,
        screen.height * loginCenterY / designHeight,
      ),
      width: w,
      height: w * 949 / 6758,
    );
  }

  static double _seg(double t, (double, double) iv, Curve c) {
    final (a, b) = iv;
    if (t <= a) return 0;
    if (t >= b) return 1;
    return c.transform((t - a) / (b - a));
  }

  static double _lerp(double a, double b, double p) => a + (b - a) * p;

  static SplashState at(double t) {
    final ph = _seg(t, handoff, standard);
    final p = _seg(t, cameraMove, cameraCurve);
    final zoom = z0 * math.pow(z1 / z0, p) * math.pow(z2 / z1, ph);
    final camera = Offset.lerp(bCenterW, wordCenterW, p)!;

    final pw = _seg(t, windup, standard);
    final pt = _seg(t, travel, glide);
    final pr = _seg(t, travel, rotateCurve);
    final grow = _lerp(1, swellAmount, _seg(t, swell, standard));
    var pop = _lerp(1, landPop, _seg(t, landUp, decelerate));
    pop = _lerp(pop, 1, _seg(t, landDown, standard));

    Offset mOffset;
    double mScale;
    if (t < travel.$2) {
      // flying, relative to the screen centre
      final x0 = mStartOffset.dx + windupDx * pw;
      mOffset = Offset(
        _lerp(x0, mEndOffset.dx, pt),
        -arc * math.sin(math.pi * pt),
      );
      mScale = _lerp(mStartScale * grow, mEndScale, pt);
    } else {
      // landed: locked into the wordmark
      mOffset = (mEndW - camera) * zoom;
      mScale = mScaleWord * zoom * pop;
    }

    final letters = <LetterState>[
      for (var i = 0; i < 8; i++)
        () {
          final start = i < 5
              ? hoardStart + i * letterStagger
              : ateStart + (i - 5) * letterStagger;
          final pl = _seg(t, (start, start + letterDuration), letterCurve);
          return LetterState(letterSlide * (1 - pl), pl);
        }(),
    ];

    return SplashState(
      background: Color.lerp(green, cream, ph)!,
      bhoardColor: Color.lerp(cream, green, _seg(t, invert, Curves.linear))!,
      zoom: zoom.toDouble(),
      camera: camera,
      anchorYFraction: _lerp(startCenterY, loginCenterY, ph) / designHeight,
      bowls: _seg(t, bowlsDraw, standard),
      mColor: Color.lerp(cream, yellow, _seg(t, colour, standard))!,
      mOffset: mOffset,
      mScale: mScale,
      mRotationDeg: _lerp(90 + windupRotation * pw, 0, pr),
      letters: letters,
    );
  }
}

// Exact logo geometry, converted 1:1 from the SVG path data.
abstract final class LogoPaths {
  // The B's straight left bar (B units, 0..60 x 0..236).
  static final Path stem = Path()
    ..moveTo(12.0, 0.0)
    ..lineTo(60.0, 0.0)
    ..lineTo(60.0, 236.0)
    ..lineTo(12.0, 236.0)
    ..arcToPoint(
      Offset(0.0, 224.0),
      radius: Radius.circular(12.0),
      largeArc: false,
      clockwise: true,
    )
    ..lineTo(0.0, 12.0)
    ..arcToPoint(
      Offset(12.0, 0.0),
      radius: Radius.circular(12.0),
      largeArc: false,
      clockwise: true,
    )
    ..close();

  // The m stroke (m-local units, 236 x 160 upright). Stroke width 50, butt caps.
  static final Path m = Path()
    ..moveTo(25.0, 160.0)
    ..lineTo(25.0, 71.5)
    ..arcToPoint(
      Offset(118.0, 71.5),
      radius: Radius.circular(46.5),
      largeArc: false,
      clockwise: true,
    )
    ..lineTo(118.0, 160.0)
    ..moveTo(118.0, 71.5)
    ..arcToPoint(
      Offset(211.0, 71.5),
      radius: Radius.circular(46.5),
      largeArc: false,
      clockwise: true,
    )
    ..lineTo(211.0, 160.0);

  // The B's own bowls = the m stroke split in two, each starting at the stem (for the draw-on).
  static final Path bowlTop = Path()
    ..moveTo(25.0, 160.0)
    ..lineTo(25.0, 71.5)
    ..arcToPoint(
      Offset(118.0, 71.5),
      radius: Radius.circular(46.5),
      largeArc: false,
      clockwise: true,
    )
    ..lineTo(118.0, 160.0);

  static final Path bowlBottom = Path()
    ..moveTo(211.0, 160.0)
    ..lineTo(211.0, 71.5)
    ..arcToPoint(
      Offset(118.0, 71.5),
      radius: Radius.circular(46.5),
      largeArc: false,
      clockwise: false,
    );

  static final Path hoardH = Path()
    ..moveTo(1378.0, 4.0)
    ..lineTo(1378.0, 709.0)
    ..lineTo(1182.0, 709.0)
    ..lineTo(1182.0, 426.0)
    ..lineTo(943.0, 426.0)
    ..lineTo(943.0, 709.0)
    ..lineTo(747.0, 709.0)
    ..lineTo(747.0, 4.0)
    ..lineTo(943.0, 4.0)
    ..lineTo(943.0, 269.0)
    ..lineTo(1182.0, 269.0)
    ..lineTo(1182.0, 4.0)
    ..lineTo(1378.0, 4.0)
    ..close();

  static final Path hoardO = Path()
    ..moveTo(1439.0, 428.0)
    ..quadraticBezierTo(1439.0, 341.0, 1477.5, 276.0)
    ..quadraticBezierTo(1516.0, 211.0, 1582.5, 176.0)
    ..quadraticBezierTo(1649.0, 141.0, 1733.0, 141.0)
    ..quadraticBezierTo(1817.0, 141.0, 1883.5, 176.0)
    ..quadraticBezierTo(1950.0, 211.0, 1988.5, 276.0)
    ..quadraticBezierTo(2027.0, 341.0, 2027.0, 428.0)
    ..quadraticBezierTo(2027.0, 515.0, 1988.5, 580.5)
    ..quadraticBezierTo(1950.0, 646.0, 1883.0, 681.0)
    ..quadraticBezierTo(1816.0, 716.0, 1732.0, 716.0)
    ..quadraticBezierTo(1648.0, 716.0, 1581.5, 681.0)
    ..quadraticBezierTo(1515.0, 646.0, 1477.0, 581.0)
    ..quadraticBezierTo(1439.0, 516.0, 1439.0, 428.0)
    ..close()
    ..moveTo(1828.0, 428.0)
    ..quadraticBezierTo(1828.0, 371.0, 1800.5, 341.0)
    ..quadraticBezierTo(1773.0, 311.0, 1733.0, 311.0)
    ..quadraticBezierTo(1693.0, 311.0, 1666.0, 341.0)
    ..quadraticBezierTo(1639.0, 371.0, 1639.0, 428.0)
    ..quadraticBezierTo(1639.0, 486.0, 1665.0, 516.0)
    ..quadraticBezierTo(1691.0, 546.0, 1732.0, 546.0)
    ..quadraticBezierTo(1773.0, 546.0, 1800.5, 515.5)
    ..quadraticBezierTo(1828.0, 485.0, 1828.0, 428.0)
    ..close();

  static final Path hoardA = Path()
    ..moveTo(2295.0, 141.0)
    ..quadraticBezierTo(2353.0, 141.0, 2395.0, 164.0)
    ..quadraticBezierTo(2437.0, 187.0, 2460.0, 226.0)
    ..lineTo(2460.0, 148.0)
    ..lineTo(2656.0, 148.0)
    ..lineTo(2656.0, 709.0)
    ..lineTo(2460.0, 709.0)
    ..lineTo(2460.0, 631.0)
    ..quadraticBezierTo(2437.0, 670.0, 2394.5, 693.0)
    ..quadraticBezierTo(2352.0, 716.0, 2295.0, 716.0)
    ..quadraticBezierTo(2228.0, 716.0, 2173.5, 681.0)
    ..quadraticBezierTo(2119.0, 646.0, 2087.5, 580.5)
    ..quadraticBezierTo(2056.0, 515.0, 2056.0, 428.0)
    ..quadraticBezierTo(2056.0, 341.0, 2087.5, 276.0)
    ..quadraticBezierTo(2119.0, 211.0, 2173.5, 176.0)
    ..quadraticBezierTo(2228.0, 141.0, 2295.0, 141.0)
    ..close()
    ..moveTo(2358.0, 312.0)
    ..quadraticBezierTo(2314.0, 312.0, 2285.0, 342.5)
    ..quadraticBezierTo(2256.0, 373.0, 2256.0, 428.0)
    ..quadraticBezierTo(2256.0, 482.0, 2285.0, 513.5)
    ..quadraticBezierTo(2314.0, 545.0, 2358.0, 545.0)
    ..quadraticBezierTo(2401.0, 545.0, 2430.5, 514.0)
    ..quadraticBezierTo(2460.0, 483.0, 2460.0, 428.0)
    ..quadraticBezierTo(2460.0, 374.0, 2430.5, 343.0)
    ..quadraticBezierTo(2401.0, 312.0, 2358.0, 312.0)
    ..close();

  static final Path hoardR = Path()
    ..moveTo(3126.0, 143.0)
    ..lineTo(3126.0, 352.0)
    ..lineTo(3071.0, 352.0)
    ..quadraticBezierTo(3007.0, 352.0, 2976.0, 377.0)
    ..quadraticBezierTo(2945.0, 402.0, 2945.0, 464.0)
    ..lineTo(2945.0, 709.0)
    ..lineTo(2749.0, 709.0)
    ..lineTo(2749.0, 148.0)
    ..lineTo(2945.0, 148.0)
    ..lineTo(2945.0, 247.0)
    ..quadraticBezierTo(2978.0, 199.0, 3025.0, 171.0)
    ..quadraticBezierTo(3072.0, 143.0, 3126.0, 143.0)
    ..close();

  static final Path hoardD = Path()
    ..moveTo(3385.0, 141.0)
    ..quadraticBezierTo(3439.0, 141.0, 3481.5, 163.5)
    ..quadraticBezierTo(3524.0, 186.0, 3548.0, 225.0)
    ..lineTo(3548.0, -31.0)
    ..lineTo(3745.0, -31.0)
    ..lineTo(3745.0, 709.0)
    ..lineTo(3548.0, 709.0)
    ..lineTo(3548.0, 631.0)
    ..quadraticBezierTo(3525.0, 670.0, 3483.0, 693.0)
    ..quadraticBezierTo(3441.0, 716.0, 3384.0, 716.0)
    ..quadraticBezierTo(3317.0, 716.0, 3262.5, 681.0)
    ..quadraticBezierTo(3208.0, 646.0, 3176.5, 580.5)
    ..quadraticBezierTo(3145.0, 515.0, 3145.0, 428.0)
    ..quadraticBezierTo(3145.0, 341.0, 3176.5, 276.0)
    ..quadraticBezierTo(3208.0, 211.0, 3263.0, 176.0)
    ..quadraticBezierTo(3318.0, 141.0, 3385.0, 141.0)
    ..close()
    ..moveTo(3447.0, 312.0)
    ..quadraticBezierTo(3403.0, 312.0, 3374.0, 342.5)
    ..quadraticBezierTo(3345.0, 373.0, 3345.0, 428.0)
    ..quadraticBezierTo(3345.0, 482.0, 3374.0, 513.5)
    ..quadraticBezierTo(3403.0, 545.0, 3447.0, 545.0)
    ..quadraticBezierTo(3490.0, 545.0, 3519.5, 514.0)
    ..quadraticBezierTo(3549.0, 483.0, 3549.0, 428.0)
    ..quadraticBezierTo(3549.0, 374.0, 3519.5, 343.0)
    ..quadraticBezierTo(3490.0, 312.0, 3447.0, 312.0)
    ..close();

  static final Path mateA = Path()
    ..moveTo(5121.0, 141.0)
    ..quadraticBezierTo(5179.0, 141.0, 5221.0, 164.0)
    ..quadraticBezierTo(5263.0, 187.0, 5286.0, 226.0)
    ..lineTo(5286.0, 148.0)
    ..lineTo(5482.0, 148.0)
    ..lineTo(5482.0, 709.0)
    ..lineTo(5286.0, 709.0)
    ..lineTo(5286.0, 631.0)
    ..quadraticBezierTo(5263.0, 670.0, 5220.5, 693.0)
    ..quadraticBezierTo(5178.0, 716.0, 5121.0, 716.0)
    ..quadraticBezierTo(5054.0, 716.0, 4999.5, 681.0)
    ..quadraticBezierTo(4945.0, 646.0, 4913.5, 580.5)
    ..quadraticBezierTo(4882.0, 515.0, 4882.0, 428.0)
    ..quadraticBezierTo(4882.0, 341.0, 4913.5, 276.0)
    ..quadraticBezierTo(4945.0, 211.0, 4999.5, 176.0)
    ..quadraticBezierTo(5054.0, 141.0, 5121.0, 141.0)
    ..close()
    ..moveTo(5184.0, 312.0)
    ..quadraticBezierTo(5140.0, 312.0, 5111.0, 342.5)
    ..quadraticBezierTo(5082.0, 373.0, 5082.0, 428.0)
    ..quadraticBezierTo(5082.0, 482.0, 5111.0, 513.5)
    ..quadraticBezierTo(5140.0, 545.0, 5184.0, 545.0)
    ..quadraticBezierTo(5227.0, 545.0, 5256.5, 514.0)
    ..quadraticBezierTo(5286.0, 483.0, 5286.0, 428.0)
    ..quadraticBezierTo(5286.0, 374.0, 5256.5, 343.0)
    ..quadraticBezierTo(5227.0, 312.0, 5184.0, 312.0)
    ..close();

  static final Path mateT = Path()
    ..moveTo(5906.0, 542.0)
    ..lineTo(5906.0, 709.0)
    ..lineTo(5821.0, 709.0)
    ..quadraticBezierTo(5606.0, 709.0, 5606.0, 496.0)
    ..lineTo(5606.0, 311.0)
    ..lineTo(5537.0, 311.0)
    ..lineTo(5537.0, 148.0)
    ..lineTo(5606.0, 148.0)
    ..lineTo(5606.0, 12.0)
    ..lineTo(5803.0, 12.0)
    ..lineTo(5803.0, 148.0)
    ..lineTo(5905.0, 148.0)
    ..lineTo(5905.0, 311.0)
    ..lineTo(5803.0, 311.0)
    ..lineTo(5803.0, 499.0)
    ..quadraticBezierTo(5803.0, 522.0, 5813.5, 532.0)
    ..quadraticBezierTo(5824.0, 542.0, 5849.0, 542.0)
    ..lineTo(5906.0, 542.0)
    ..close();

  static final Path mateE = Path()
    ..moveTo(6510.0, 468.0)
    ..lineTo(6139.0, 468.0)
    ..quadraticBezierTo(6142.0, 514.0, 6164.5, 536.5)
    ..quadraticBezierTo(6187.0, 559.0, 6222.0, 559.0)
    ..quadraticBezierTo(6271.0, 559.0, 6292.0, 515.0)
    ..lineTo(6501.0, 515.0)
    ..quadraticBezierTo(6488.0, 573.0, 6450.5, 618.5)
    ..quadraticBezierTo(6413.0, 664.0, 6356.0, 690.0)
    ..quadraticBezierTo(6299.0, 716.0, 6230.0, 716.0)
    ..quadraticBezierTo(6147.0, 716.0, 6082.5, 681.0)
    ..quadraticBezierTo(6018.0, 646.0, 5981.5, 581.0)
    ..quadraticBezierTo(5945.0, 516.0, 5945.0, 428.0)
    ..quadraticBezierTo(5945.0, 340.0, 5981.0, 275.5)
    ..quadraticBezierTo(6017.0, 211.0, 6081.5, 176.0)
    ..quadraticBezierTo(6146.0, 141.0, 6230.0, 141.0)
    ..quadraticBezierTo(6313.0, 141.0, 6377.0, 175.0)
    ..quadraticBezierTo(6441.0, 209.0, 6477.0, 272.5)
    ..quadraticBezierTo(6513.0, 336.0, 6513.0, 422.0)
    ..quadraticBezierTo(6513.0, 445.0, 6510.0, 468.0)
    ..close()
    ..moveTo(6313.0, 373.0)
    ..quadraticBezierTo(6313.0, 337.0, 6289.0, 316.5)
    ..quadraticBezierTo(6265.0, 296.0, 6229.0, 296.0)
    ..quadraticBezierTo(6193.0, 296.0, 6170.0, 315.5)
    ..quadraticBezierTo(6147.0, 335.0, 6140.0, 373.0)
    ..lineTo(6313.0, 373.0)
    ..close();

  // (path, isBHoard) in wordmark order H o a r d a t e. World units, baseline 709.
  static final List<(Path, bool)> letters = [
    (hoardH, true),
    (hoardO, true),
    (hoardA, true),
    (hoardR, true),
    (hoardD, true),
    (mateA, false),
    (mateT, false),
    (mateE, false),
  ];
}
