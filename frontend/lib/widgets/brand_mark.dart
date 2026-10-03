import 'package:flutter/material.dart';

const ubsBlue = Color(0xFF005A9C);

/// Marca única do UBS Rápida, desenhada sem caixa ou fundo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final contrast = Theme.of(context).brightness == Brightness.dark;
    final iconSize = compact ? 38.0 : 68.0;
    final titleSize = compact ? 22.0 : 34.0;
    return Semantics(
      image: true,
      label: 'UBS Rápida, saúde perto de você',
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: iconSize,
              height: iconSize,
              child: CustomPaint(painter: _BrandSymbolPainter(contrast))),
          SizedBox(width: compact ? 8 : 12),
          Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UBS',
                    style: TextStyle(
                        color: contrast ? Colors.yellow : ubsBlue,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: .88,
                        letterSpacing: -.8)),
                Text('RÁPIDA',
                    style: TextStyle(
                        color:
                            contrast ? Colors.white : const Color(0xFF167CC2),
                        fontSize: titleSize * .52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: titleSize * .13,
                        height: 1.25)),
              ]),
        ]),
      ),
    );
  }
}

class _BrandSymbolPainter extends CustomPainter {
  _BrandSymbolPainter(this.contrast);
  final bool contrast;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 68;
    final blue = Paint()
      ..color = contrast ? Colors.yellow : ubsBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * unit
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = contrast ? Colors.white : const Color(0xFF35A7DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(5 * unit, 5 * unit, 58 * unit, 58 * unit), .25,
        4.75, false, blue);
    canvas.drawPath(
        Path()
          ..moveTo(10 * unit, 50 * unit)
          ..cubicTo(
              24 * unit, 39 * unit, 39 * unit, 60 * unit, 59 * unit, 44 * unit),
        accent);
    final cross = Paint()..color = contrast ? Colors.yellow : ubsBlue;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(28 * unit, 17 * unit, 12 * unit, 35 * unit),
            Radius.circular(4 * unit)),
        cross);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(17 * unit, 28 * unit, 34 * unit, 12 * unit),
            Radius.circular(4 * unit)),
        cross);
  }

  @override
  bool shouldRepaint(covariant _BrandSymbolPainter oldDelegate) =>
      oldDelegate.contrast != contrast;
}
