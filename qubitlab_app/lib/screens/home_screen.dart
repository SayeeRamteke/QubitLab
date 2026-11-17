import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/lessons_data.dart';
import '../data/modules.dart';
import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../providers/saved_circuits_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saved = context.watch<SavedCircuitsProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshUser();
          await auth.refreshProgress();
          await saved.load(auth.userId!);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
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
                      const Text('Welcome back',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text(auth.username,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
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
            Row(
              children: [
                Expanded(
                    child: _Stat(
                        icon: Icons.bolt_rounded,
                        color: AppColors.orange,
                        value: '${auth.xp} XP',
                        label: 'Total points')),
                const SizedBox(width: 14),
                Expanded(
                    child: _Stat(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.pink,
                        value: '${auth.streak} day${auth.streak == 1 ? '' : 's'}',
                        label: 'Streak')),
              ],
            ),
            const SizedBox(height: 26),
            const Text('Your progress',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
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
            const Text('Recent circuits',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            if (saved.loading && saved.circuits.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (saved.error != null)
              SoftCard(child: Text(saved.error!, style: const TextStyle(color: Colors.red)))
            else if (saved.circuits.isEmpty)
              const SoftCard(
                child: Text('No saved circuits yet. Build one in the Lab and tap Save.',
                    style: TextStyle(color: AppColors.muted)),
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
                        shellTab.value = 2;
                      },
                      child: Container(
                        width: 150,
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
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: math.max(value, 0.001),
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: color.withAlpha(40),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(40), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
