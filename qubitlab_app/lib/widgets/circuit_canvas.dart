import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gate.dart';
import '../providers/circuit_provider.dart';
import '../theme/app_theme.dart';
import 'bloch_sheet.dart';
import 'gate_tile.dart';

class CircuitCanvas extends StatelessWidget {
  static const double rowH = 72;
  static const double cellW = 64;
  static const double labelW = 44;

  const CircuitCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CircuitProvider>();
    final width = cellW * CircuitProvider.columns;
    final height = rowH * c.qubits;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelW,
            child: Column(
              children: [
                for (var q = 0; q < c.qubits; q++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => showBlochSheet(context, q, c.toJson()),
                    child: SizedBox(
                      height: rowH,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('q$q', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Text('|0>',
                              style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _WirePainter(c.qubits, c.gates)),
                    ),
                    for (var q = 0; q < c.qubits; q++)
                      for (var col = 0; col < CircuitProvider.columns; col++)
                        Positioned(
                          left: col * cellW,
                          top: q * rowH,
                          width: cellW,
                          height: rowH,
                          child: _Slot(qubit: q, column: col),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  final int qubits;
  final List<PlacedGate> gates;
  _WirePainter(this.qubits, this.gates);

  @override
  void paint(Canvas canvas, Size size) {
    final wire = Paint()
      ..color = AppColors.ink.withAlpha(70)
      ..strokeWidth = 2;
    for (var q = 0; q < qubits; q++) {
      final y = CircuitCanvas.rowH * (q + 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), wire);
    }
    for (final g in gates) {
      if (g.control == null) continue;
      final x = CircuitCanvas.cellW * (g.column + 0.5);
      final y1 = CircuitCanvas.rowH * (g.control! + 0.5);
      final y2 = CircuitCanvas.rowH * (g.target + 0.5);
      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        Paint()
          ..color = g.type.color
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WirePainter old) => true;
}

class _Slot extends StatelessWidget {
  final int qubit;
  final int column;
  const _Slot({required this.qubit, required this.column});

  @override
  Widget build(BuildContext context) {
    final circuit = context.read<CircuitProvider>();
    final gate = circuit.gateAt(qubit, column);

    return DragTarget<DragPayload>(
      onWillAcceptWithDetails: (d) =>
          circuit.canPlace(d.data.type, qubit, column, ignoreId: d.data.fromId),
      onAcceptWithDetails: (d) =>
          circuit.place(d.data.type, qubit, column, moveId: d.data.fromId),
      builder: (context, accepted, rejected) {
        final hovering = accepted.isNotEmpty;
        final blocked = rejected.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: hovering
                ? AppColors.indigo.withAlpha(45)
                : blocked
                    ? Colors.red.withAlpha(35)
                    : Colors.transparent,
            border: Border.all(
              color: hovering
                  ? AppColors.indigo
                  : blocked
                      ? Colors.red.withAlpha(120)
                      : AppColors.ink.withAlpha(14),
              width: hovering ? 2 : 1,
            ),
          ),
          child: gate == null ? null : Center(child: _placedGate(context, gate)),
        );
      },
    );
  }

  Widget _placedGate(BuildContext context, PlacedGate g) {
    final visual = _visual(g);
    return LongPressDraggable<DragPayload>(
      data: DragPayload(g.type, g.id),
      delay: const Duration(milliseconds: 180),
      feedback: GateTile(type: g.type, size: 56, lifted: true),
      childWhenDragging: Opacity(opacity: 0.25, child: visual),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showGateSheet(context, g),
        child: visual,
      ),
    );
  }

  Widget _visual(PlacedGate g) {
    if (!g.type.isTwoQubit) return GateTile(type: g.type, size: 44);
    final isControl = qubit == g.control;
    if (isControl || g.type == GateType.cz) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(shape: BoxShape.circle, color: g.type.color),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: g.type.color, width: 3),
      ),
      child: Icon(Icons.add, size: 20, color: g.type.color),
    );
  }
}

void showGateSheet(BuildContext context, PlacedGate g) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final circuit = ctx.read<CircuitProvider>();
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GateTile(type: g.type, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.type.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(
                        g.control == null
                            ? 'on q${g.target}, step ${g.column + 1}'
                            : 'control q${g.control} -> target q${g.target}, step ${g.column + 1}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(g.type.description),
            const SizedBox(height: 20),
            Row(
              children: [
                if (g.type.isTwoQubit) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        circuit.swapControlTarget(g.id);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.swap_vert_rounded),
                      label: const Text('Swap'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                    onPressed: () {
                      circuit.removeGate(g.id);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
