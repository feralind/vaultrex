import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Rare Candy–style portfolio line chart: axes, dashed grid, dollar + date labels.
class PortfolioValueChart extends StatelessWidget {
  const PortfolioValueChart({
    super.key,
    required this.points,
    this.height = 168,
  });

  final List<CollectionValuePoint> points;
  final double height;

  static List<CollectionValuePoint> seriesForDisplay(
    List<CollectionValuePoint> history, {
    double currentValue = 0,
    DateTime? asOf,
  }) {
    final end = asOf ?? DateTime.now();
    if (history.length >= 2) return history;
    if (history.length == 1) {
      final p = history.first;
      return [
        CollectionValuePoint(
          date: p.date.subtract(const Duration(days: 1)),
          value: p.value,
        ),
        p,
      ];
    }
    // Empty / $0: flat series so chrome still renders like a real chart.
    final v = currentValue;
    return [
      CollectionValuePoint(
        date: end.subtract(const Duration(days: 6)),
        value: v,
      ),
      CollectionValuePoint(date: end, value: v),
    ];
  }

  String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 100) return '\$${v.toStringAsFixed(0)}';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final series = seriesForDisplay(points);
    var minV = series.map((p) => p.value).reduce(math.min);
    var maxV = series.map((p) => p.value).reduce(math.max);
    if ((maxV - minV).abs() < 0.01) {
      // Flat / empty: show $1.00 … $0.00 style frame (or pad around value).
      if (maxV <= 0.01) {
        minV = 0;
        maxV = 1;
      } else {
        final pad = math.max(0.5, maxV * 0.08);
        minV = math.max(0, minV - pad);
        maxV = maxV + pad;
      }
    } else {
      final pad = (maxV - minV) * 0.08;
      minV = math.max(0, minV - pad);
      maxV = maxV + pad;
    }
    final midV = (minV + maxV) / 2;
    final yLabels = [_money(maxV), _money(midV), _money(minV)];
    final mid = series[series.length ~/ 2];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 46,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final label in yLabels)
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CC.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _PortfolioChartPainter(
                      values: series.map((p) => p.value).toList(),
                      minV: minV,
                      maxV: maxV,
                      lineColor: CC.ink,
                      axisColor: CC.ink.withValues(alpha: 0.55),
                      gridColor: CC.ink.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateLabel(series.first.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CC.inkMuted,
                  ),
                ),
                Text(
                  _dateLabel(mid.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: CC.inkMuted,
                  ),
                ),
                Text(
                  _dateLabel(series.last.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CC.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioChartPainter extends CustomPainter {
  _PortfolioChartPainter({
    required this.values,
    required this.minV,
    required this.maxV,
    required this.lineColor,
    required this.axisColor,
    required this.gridColor,
  });

  final List<double> values;
  final double minV;
  final double maxV;
  final Color lineColor;
  final Color axisColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    // Dashed horizontal grid (3 bands including top/bottom).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Thin white axes (left + bottom).
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    if (values.length < 2) return;

    double yFor(double v) => size.height * (1 - (v - minV) / range);

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0.0),
          ],
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len <= 0) return;
    final ux = dx / len;
    final uy = dy / len;
    var drawn = 0.0;
    while (drawn < len) {
      final start = drawn;
      final end = math.min(drawn + dash, len);
      canvas.drawLine(
        Offset(a.dx + ux * start, a.dy + uy * start),
        Offset(a.dx + ux * end, a.dy + uy * end),
        paint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioChartPainter old) =>
      old.values != values ||
      old.minV != minV ||
      old.maxV != maxV ||
      old.lineColor != lineColor;
}
