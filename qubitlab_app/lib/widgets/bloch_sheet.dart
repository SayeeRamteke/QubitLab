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
          final len = math.sqrt(x * x + y * y + z * z);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Qubit q$qubit',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(painter: _BlochPainter(x, z)),
              ),
              const SizedBox(height: 12),
              Text('x = ${x.toStringAsFixed(2)}    y = ${y.toStringAsFixed(2)}    z = ${z.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                len < 0.98
                    ? 'The vector is shorter than 1: this qubit is entangled with another one.'
                    : 'Pure state (vector length 1). Shown: x across, z up. y points out of the screen.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BlochPainter extends CustomPainter {
  final double x;
  final double z;
  _BlochPainter(this.x, this.z);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 14;
    final line = Paint()
      ..color = AppColors.ink.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, r, line);
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), line);
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), line);

    void label(String t, Offset o) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    label('|0>', c + Offset(0, -r - 10));
    label('|1>', c + Offset(0, r + 10));
    label('+x', c + Offset(r + 10, 0));

    final tip = c + Offset(x * r, -z * r);
    canvas.drawLine(c, tip, Paint()
      ..color = AppColors.indigo
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(tip, 7, Paint()..color = AppColors.indigo);
    canvas.drawCircle(c, 3, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _BlochPainter old) => old.x != x || old.z != z;
}
