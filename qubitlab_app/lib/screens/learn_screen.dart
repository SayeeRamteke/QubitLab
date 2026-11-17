import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lessons_data.dart';
import '../data/modules.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'lesson_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final done = context.watch<AuthProvider>().completedLessons;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Learn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Four modules from qubits to algorithms.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          for (var m = 0; m < modules.length; m++) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: modules[m].color, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Module ${m + 1}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(modules[m].title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(modules[m].subtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(modules[m].icon, size: 40, color: Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final l in lessonsOf(m))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          done.contains(l.id)
                              ? Icons.check_circle_rounded
                              : Icons.play_circle_outline_rounded,
                          color: done.contains(l.id) ? AppColors.green : AppColors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(l.title,
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
