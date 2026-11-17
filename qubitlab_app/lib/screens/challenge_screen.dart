import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_workspace.dart';
import '../widgets/soft_card.dart';

class ChallengeScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;
  const ChallengeScreen({super.key, required this.challenge});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final CircuitProvider _circuit;
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  bool _busy = false;

  Map<String, dynamic> get ch => widget.challenge;

  @override
  void initState() {
    super.initState();
    _circuit = CircuitProvider(qubits: ch['qubits'] as int);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _circuit.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final res = await api.submitChallenge(ch['id'] as int, auth.userId!, _circuit.toJson());
      if (res['passed'] == true) {
        _confetti.play();
        await auth.refreshUser();
        await auth.refreshProgress();
        if (!mounted) return;
        final xp = res['xp_awarded'] as int;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Challenge complete!'),
            content: Text(xp > 0 ? 'You earned +$xp XP.' : 'Already completed, so no extra XP this time.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nice'))],
          ),
        );
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(res['hint'] as String),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = Map<String, dynamic>.from(ch['target_json_state'] as Map);
    final keys = target.keys.toList()..sort();
    final targetText =
        keys.map((k) => '|$k> ${((target[k] as num) * 100).round()}%').join('   ');

    return Scaffold(
      appBar: AppBar(title: Text(ch['title'] as String), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: AppColors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ch['description'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Target: $targetText',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ChangeNotifierProvider.value(
                    value: _circuit,
                    child: const CircuitWorkspace(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink, shape: const StadiumBorder()),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit circuit'),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [
                AppColors.indigo,
                AppColors.orange,
                AppColors.pink,
                AppColors.green,
                AppColors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
