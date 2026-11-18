import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Long-press a qubit label to open this "Qubit Inspector".
void showBlochSheet(BuildContext context, int qubit, Map<String, dynamic> circuit) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BlochSheet(qubit: qubit, circuit: circuit),
  );
}

class BlochView extends StatelessWidget {
  final int qubit;
  final double x;
  final double y;
  final double z;
  final double size;
  final bool showHeader;

  const BlochView({
    super.key,
    required this.qubit,
    required this.x,
    required this.y,
    required this.z,
    this.size = 190,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final len = math.sqrt(x * x + y * y + z * z);
    final isEntangled = len < 0.98;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Qubit q$qubit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEntangled ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isEntangled ? 'Entangled (Mixed)' : 'Pure State',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isEntangled ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: BlochPainter(x: x, y: y, z: z)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _coordChip('x', x),
            _coordChip('y', y),
            _coordChip('z', z),
            _coordChip('|r|', len),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isEntangled
              ? 'Vector length is ${len.toStringAsFixed(2)} < 1: this qubit is entangled with another qubit.'
              : 'Pure state (length = 1.00). Shown projected: x across, z up, y into/out of plane.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _coordChip(String label, double val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label = ${val.toStringAsFixed(2)}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _BlochSheet extends StatelessWidget {
  final int qubit;
  final Map<String, dynamic> circuit;
  const _BlochSheet({required this.qubit, required this.circuit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: api.bloch(circuit),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return SizedBox(
                height: 120, child: Center(child: Text('${snap.error}', textAlign: TextAlign.center)));
          }
          final v = snap.data!.firstWhere((e) => e['qubit'] == qubit);
          final x = (v['x'] as num).toDouble();
          final y = (v['y'] as num).toDouble();
          final z = (v['z'] as num).toDouble();
          return BlochView(qubit: qubit, x: x, y: y, z: z);
        },
      ),
    );
  }
}

class BlochPainter extends CustomPainter {
  final double x;
  final double y;
  final double z;
  BlochPainter({required this.x, required this.z, this.y = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 16;

    // Sphere background fill
    final sphereBg = Paint()
      ..color = const Color(0xFFF8F9FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, sphereBg);

    // Outer circle
    final line = Paint()
      ..color = AppColors.ink.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, r, line);

    // Equator dashed/faded ellipse for 3D sphere depth
    final equatorPaint = Paint()
      ..color = AppColors.ink.withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 2, height: r * 0.55),
      equatorPaint,
    );

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.ink.withAlpha(55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), axisPaint);
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), axisPaint);

    // y-axis diagonal projection
    final yOffset = Offset(-r * 0.35, r * 0.25);
    final yPaint = Paint()
      ..color = AppColors.ink.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(c - yOffset, c + yOffset, yPaint);

    void label(String t, Offset o, {FontWeight weight = FontWeight.w600}) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(color: AppColors.ink.withAlpha(180), fontSize: 11, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    label('|0>', c + Offset(0, -r - 10), weight: FontWeight.w700);
    label('|1>', c + Offset(0, r + 10), weight: FontWeight.w700);
    label('+x', c + Offset(r + 11, 0));
    label('-x', c + Offset(-r - 11, 0));
    label('+y', c - yOffset - const Offset(8, 6));

    // Vector tip calculation (with slight y perspective)
    // x along X-axis, -z along Y-canvas (upwards), y gives slight perspective skew
    final tipX = x * r - y * r * 0.18;
    final tipY = -z * r + y * r * 0.12;
    final tip = c + Offset(tipX, tipY);

    // Vector shadow/stem
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = AppColors.indigo
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow tip
    canvas.drawCircle(tip, 6.5, Paint()..color = AppColors.indigo);
    canvas.drawCircle(tip, 3, Paint()..color = Colors.white);

    // Center origin
    canvas.drawCircle(c, 3, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant BlochPainter old) =>
      old.x != x || old.y != y || old.z != z;
}
