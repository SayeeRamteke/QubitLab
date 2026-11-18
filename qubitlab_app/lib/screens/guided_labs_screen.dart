import 'package:flutter/material.dart';
import '../data/guided_labs_data.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'guided_lab_session_screen.dart';

class GuidedLabsScreen extends StatelessWidget {
  const GuidedLabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guided Labs',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Interactive step-by-step quantum phenomena',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2C40), Color(0xFF1E1E2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Master Quantum Mechanics Hands-On',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Build iconic circuits step-by-step with real-time validation and physics guidance whenever you make a mistake.',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB9F6CA), size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text('Select a Phenomenon',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          for (final lab in guidedLabs) ...[
            _LabCard(lab: lab),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _LabCard extends StatelessWidget {
  final GuidedLab lab;
  const _LabCard({required this.lab});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lab.color.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(lab.icon, color: lab.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lab.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(lab.subtitle,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lab.description,
            style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _badge(lab.difficulty, _diffColor(lab.difficulty)),
                    _badge('${lab.qubits} Qubit${lab.qubits > 1 ? 's' : ''}', AppColors.ink),
                    _badge('${lab.steps.length} Steps', AppColors.indigo),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GuidedLabSessionScreen(lab: lab)),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _diffColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return AppColors.green;
      case 'intermediate':
        return AppColors.indigo;
      case 'advanced':
        return AppColors.orange;
      default:
        return AppColors.ink;
    }
  }
}
