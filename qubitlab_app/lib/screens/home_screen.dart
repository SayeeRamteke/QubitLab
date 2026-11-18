import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/daily_challenges_data.dart';
import '../data/lessons_data.dart';
import '../data/modules.dart';
import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../providers/saved_circuits_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'app_shell.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedPredictIndex;
  bool _predictSubmitted = false;
  late int _challengeIndex;

  @override
  void initState() {
    super.initState();
    final today = getTodayChallenge();
    final idx = dailyChallenges.indexWhere((c) => c.id == today.id);
    _challengeIndex = idx >= 0 ? idx : 0;
  }

  void _resetChallenge() {
    setState(() {
      _selectedPredictIndex = null;
      _predictSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saved = context.watch<SavedCircuitsProvider>();
    final currentChallenge = dailyChallenges[_challengeIndex % dailyChallenges.length];

    // Find next uncompleted lesson
    Lesson? nextLesson;
    for (final l in lessonsData) {
      if (!auth.completedLessons.contains(l.id)) {
        nextLesson = l;
        break;
      }
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _resetChallenge();
          await auth.refreshUser();
          await auth.refreshProgress();
          await saved.load(auth.userId!);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // User Greeting
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.ink,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text(auth.username,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Log out',
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Stats Grid (4 items)
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.bolt_rounded,
                    color: AppColors.orange,
                    value: '${auth.xp} XP',
                    label: 'Total points',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.pink,
                    value: '${auth.streak} day${auth.streak == 1 ? '' : 's'}',
                    label: 'Streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.school_rounded,
                    color: AppColors.indigo,
                    value: '${auth.completedLessons.length}/${lessonsData.length}',
                    label: 'Lessons done',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    icon: Icons.science_rounded,
                    color: AppColors.teal,
                    value: '${saved.circuits.length}',
                    label: 'Circuits built',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. "Resume Learning" Hero Card
            if (nextLesson != null) ...[
              const Text('Continue Learning',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 10),
              _ResumeHeroCard(lesson: nextLesson),
              const SizedBox(height: 24),
            ],

            // 3. Daily Predict Challenge
            Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, size: 20, color: AppColors.indigo),
                const SizedBox(width: 8),
                const Text('Daily Predict Challenge',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const Spacer(),
                if (_predictSubmitted || _selectedPredictIndex != null) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _resetChallenge,
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${currentChallenge.xpReward} XP',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DailyPredictCard(
              challenge: currentChallenge,
              selectedIndex: _selectedPredictIndex,
              submitted: _predictSubmitted,
              challengeNumber: (_challengeIndex % dailyChallenges.length) + 1,
              totalChallenges: dailyChallenges.length,
              onPrevious: () {
                setState(() {
                  _challengeIndex =
                      (_challengeIndex - 1 + dailyChallenges.length) % dailyChallenges.length;
                  _selectedPredictIndex = null;
                  _predictSubmitted = false;
                });
              },
              onNext: () {
                setState(() {
                  _challengeIndex = (_challengeIndex + 1) % dailyChallenges.length;
                  _selectedPredictIndex = null;
                  _predictSubmitted = false;
                });
              },
              onSelect: (idx) {
                setState(() {
                  _selectedPredictIndex = idx;
                  _predictSubmitted = true;
                });
              },
              onReset: _resetChallenge,
            ),
            const SizedBox(height: 26),

            // 4. Progress by Module
            const Text('Your progress',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 10),
            SoftCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < modules.length; i++)
                    _Ring(
                      color: modules[i].color,
                      label: 'M${i + 1}',
                      value: _moduleProgress(auth, i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // 5. Recent Circuits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent circuits',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                TextButton(
                  onPressed: () => shellTab.value = 3, // jump to Lab tab
                  child: const Text('Open Lab'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (saved.loading && saved.circuits.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (saved.error != null)
              SoftCard(child: Text(saved.error!, style: const TextStyle(color: Colors.red)))
            else if (saved.circuits.isEmpty)
              SoftCard(
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No saved circuits yet',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          const Text(
                            'Design a circuit in the Lab or Guided Labs and tap Save to store it here.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: saved.circuits.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = saved.circuits[i];
                    final gates = (c['circuit_json'] as List);
                    final color = modules[i % modules.length].color;
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        context
                            .read<CircuitProvider>()
                            .loadFrom(c['name'] as String, c['qubits'] as int, gates);
                        shellTab.value = 3; // Lab tab
                      },
                      child: Container(
                        width: 155,
                        padding: const EdgeInsets.all(16),
                        decoration:
                            BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.science_rounded, color: Colors.white),
                            const Spacer(),
                            Text(c['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                            Text('${c['qubits']} qubits, ${gates.length} gates',
                                style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _moduleProgress(AuthProvider auth, int module) {
    final ls = lessonsOf(module).toList();
    if (ls.isEmpty) return 0;
    return ls.where((l) => auth.completedLessons.contains(l.id)).length / ls.length;
  }
}

class _ResumeHeroCard extends StatelessWidget {
  final Lesson lesson;
  const _ResumeHeroCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final mod = (lesson.module >= 0 && lesson.module < modules.length)
        ? modules[lesson.module]
        : null;
    final summaryText = lesson.goal.isNotEmpty
        ? lesson.goal
        : (lesson.paragraphs.isNotEmpty ? lesson.paragraphs.first : '');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ink, const Color(0xFF2C2C40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (mod?.color ?? AppColors.indigo).withAlpha(60),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mod?.title.toUpperCase() ?? 'NEXT LESSON',
                          style: TextStyle(
                            color: mod?.color ?? const Color(0xFFB9F6CA),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyPredictCard extends StatelessWidget {
  final DailyPredictChallenge challenge;
  final int? selectedIndex;
  final bool submitted;
  final int challengeNumber;
  final int totalChallenges;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;
  final VoidCallback onReset;

  const _DailyPredictCard({
    required this.challenge,
    required this.selectedIndex,
    required this.submitted,
    required this.challengeNumber,
    required this.totalChallenges,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = selectedIndex != null ? challenge.options[selectedIndex!] : null;
    final isCorrect = selectedOption?.isCorrect ?? false;

    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.concept,
                  style: const TextStyle(
                    color: AppColors.indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Demo Switcher Row
          Row(
            children: [
              Text(
                'Demo Question $challengeNumber of $totalChallenges',
                style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: 'Previous question',
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: 'Next question',
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 12),

          // Mini Circuit Schematic
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.linear_scale_rounded, color: AppColors.indigo, size: 18),
                const SizedBox(width: 10),
                const Text('Circuit: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final gate in challenge.circuitSummary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            challenge.question,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Options
          for (var i = 0; i < challenge.options.length; i++) ...[
            _optionTile(context, i, challenge.options[i]),
            const SizedBox(height: 8),
          ],

          // Feedback Explanation Box
          if (submitted && selectedOption != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 18,
                        color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? 'Correct! +${challenge.xpReward} XP' : 'Physics Insight',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onReset,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(
                          isCorrect ? 'Reset for demo' : 'Try another option',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedOption.explanation,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isCorrect ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, int index, PredictOption option) {
    final isSelected = selectedIndex == index;
    Color borderCol = Colors.black12;
    Color bgCol = Colors.white;

    if (submitted && isSelected) {
      borderCol = option.isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
      bgCol = option.isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    } else if (isSelected) {
      borderCol = AppColors.indigo;
      bgCol = AppColors.indigo.withAlpha(20);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: submitted ? null : () => onSelect(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (submitted
                        ? (option.isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
                        : AppColors.indigo)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.black26,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      submitted
                          ? (option.isCorrect ? Icons.check : Icons.close)
                          : Icons.circle,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  const _Ring({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: math.max(value, 0.001),
                  strokeWidth: 5.5,
                  color: color,
                  backgroundColor: color.withAlpha(35),
                ),
              ),
              Text('${(value * 100).round()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withAlpha(35), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
