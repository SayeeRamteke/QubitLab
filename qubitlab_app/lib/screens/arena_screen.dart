import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';
import 'challenge_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await api.challenges();
    } on ApiException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final done = context.watch<AuthProvider>().completedChallenges;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Arena', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Build the circuit that hits the target.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              SoftCard(
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else
              for (var i = 0; i < _items.length; i++) _tile(context, i, done),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, int i, Set<int> done) {
    final ch = _items[i];
    final id = ch['id'] as int;
    final completed = done.contains(id);
    final unlocked = i == 0 || completed || done.contains(_items[i - 1]['id'] as int);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: unlocked
            ? () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => ChallengeScreen(challenge: ch)))
            : () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complete the previous challenge to unlock this one'))),
        child: SoftCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: completed
                    ? AppColors.green
                    : unlocked
                        ? AppColors.indigo
                        : const Color(0xFFE9E9F2),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : unlocked
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                  color: unlocked ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ch['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(ch['description'] as String,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('+${ch['xp_reward']} XP',
                    style: const TextStyle(
                        color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
