import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'soft_card.dart';

class MathBreakdownView extends StatefulWidget {
  final Map<String, dynamic> circuit;
  const MathBreakdownView({super.key, required this.circuit});

  @override
  State<MathBreakdownView> createState() => _MathBreakdownViewState();
}

class _MathBreakdownViewState extends State<MathBreakdownView> {
  late Future<MathBreakdown> _future;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant MathBreakdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.circuit != oldWidget.circuit) {
      _fetch();
    }
  }

  void _fetch() {
    _future = api.getMathBreakdown(widget.circuit);
  }

  @override
  Widget build(BuildContext context) {
    final gates = (widget.circuit['gates'] as List? ?? []);
    if (gates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate_outlined, size: 40, color: AppColors.indigo),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Gates on Circuit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Place some gates on the circuit wires, then flip to Math Mode to reveal the matrix multiplication for each time step.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<MathBreakdown>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(height: 16),
                Text(
                  'Computing unitary matrices & statevectors...',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => setState(_fetch),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Overview banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E2E), Color(0xFF2D2B55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.functions_rounded, color: Color(0xFFB9F6CA), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'State Evolution',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${data.qubits} Qubit${data.qubits > 1 ? 's' : ''} • Dim ${data.dimension}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Time Step 0 (Initial State):',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      r'\vert \psi_0 \rangle = ' + data.inputStateLatex,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB9F6CA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step by step breakdown cards
            for (final step in data.steps) ...[
              _MathStepCard(step: step, dimension: data.dimension),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _MathStepCard extends StatelessWidget {
  final MathStep step;
  final int dimension;

  const _MathStepCard({required this.step, required this.dimension});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Step ${step.stepIndex}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.gateLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Unitary Operator Matrix
          const Text(
            'Unitary Operator Matrix U:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'U = ' + step.operatorLatex,
                textStyle: TextStyle(
                  fontSize: dimension > 4 ? 12 : 14,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Matrix Calculation
          const Text(
            r'Calculation (U × |ψ_in⟩ = |ψ_out⟩):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                step.calculationLatex,
                textStyle: TextStyle(
                  fontSize: dimension > 4 ? 11 : 13,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Resulting State
          const Text(
            'Resulting Quantum State (Dirac Notation):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\vert \psi_' '${step.stepIndex}' r'\rangle = ' '${step.diracLatex}',
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB9F6CA),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Probabilities chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in step.probabilities.entries)
                if (entry.value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.indigo.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '|${entry.key}⟩: ${(entry.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
