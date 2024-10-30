import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class CustomCircularProgressBar extends StatelessWidget {
  final double progress; // Progress value from 0 to 100
  final double size;     // Size of the circular progress bar
  final double strokeWidth;  // Thickness of the circular progress bar
  final Color color;     // Color of the progress arc

  const CustomCircularProgressBar({
    required this.progress,
    required this.size,
    this.strokeWidth = 8.0,
    this.color = AppStyles.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _CircularProgressPainter(
            progress: progress,
            strokeWidth: strokeWidth,
            color: color,
          ),
        ),
         CircleAvatar(
            radius: size/3.3,
            backgroundColor: AppStyles.primaryColor,
            child: Text('${progress.toInt()}%', style: AppStyles.vifitTextTheme.headlineSmall?.copyWith(color: Colors.white))
         )
      ]
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;   // Percentage of progress (0 to 100)
  final double strokeWidth; // Stroke width of the circle
  final Color color;        // Color of the progress bar

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double radius = (size.width / 2) - strokeWidth / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // Draw background circle
    Paint backgroundPaint = Paint()
      ..color = AppStyles.buttonColor  // Background color
      ..strokeWidth = strokeWidth/2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    double pi = 3.14;
    double startAngle = -pi / 2;
    double sweepAngle = (2 * pi) * (progress / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}