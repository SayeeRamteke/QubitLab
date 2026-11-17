import 'package:flutter/material.dart';
import '../models/gate.dart';
import '../theme/app_theme.dart';
import 'gate_tile.dart';
import 'soft_card.dart';

class GatePalette extends StatelessWidget {
  const GatePalette({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gates',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in GateType.values)
                Draggable<DragPayload>(
                  data: DragPayload(t),
                  feedback: GateTile(type: t, size: 56, lifted: true),
                  childWhenDragging: Opacity(opacity: 0.3, child: GateTile(type: t, size: 52)),
                  child: GateTile(type: t, size: 52),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
