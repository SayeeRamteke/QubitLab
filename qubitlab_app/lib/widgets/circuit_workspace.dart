import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/circuit_provider.dart';
import '../theme/app_theme.dart';
import 'circuit_canvas.dart';
import 'gate_palette.dart';
import 'soft_card.dart';

/// Canvas + gate palette. Works with whichever CircuitProvider is above it
/// (global one in the Lab, a local one in lessons and Arena challenges).
class CircuitWorkspace extends StatelessWidget {
  final Widget? overlay; // e.g. the Simulate button
  const CircuitWorkspace({super.key, this.overlay});

  @override
  Widget build(BuildContext context) {
    final empty = context.select<CircuitProvider, bool>((c) => c.isEmpty);
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Stack(
                    children: [
                      const CircuitCanvas(),
                      if (empty)
                        const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Drag a gate onto a wire. Tap a gate to edit, long-press to move.\nLong-press a qubit label to inspect it.',
                              style: TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (overlay != null) Positioned(right: 14, bottom: 14, child: overlay!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GatePalette(),
      ],
    );
  }
}
