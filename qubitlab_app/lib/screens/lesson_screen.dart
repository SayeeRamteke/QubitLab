
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data/lessons_data.dart';
import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/circuit_workspace.dart';
import '../widgets/soft_card.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  YoutubePlayerController? _yt;
  late final CircuitProvider _circuit;

  bool _labOk = false;
  String? _labMsg;
  int? _picked;
  bool _busy = false;

  Lesson get l => widget.lesson;

  @override
  void initState() {
    super.initState();

    _circuit = CircuitProvider(qubits: l.qubits);

    if (l.youtubeId.isNotEmpty) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: l.youtubeId,
        autoPlay: false,
        params: const YoutubePlayerParams(),
      );
    }
  }

  @override
  void dispose() {
    _yt?.close();
    _circuit.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);

    try {
      final r = await api.simulate(_circuit.toJson());
      final ok = matchesTarget(l.target, r);

      if (!mounted) return;

      setState(() {
        _labOk = ok;
        _labMsg = ok
            ? 'Matches the goal!'
            : 'Not yet. You got: ${describeResults(r)}';
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _labMsg = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _complete() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _busy = true);

    try {
      await api.completeLesson(l.id, auth.userId!);
      await auth.refreshUser();
      await auth.refreshProgress();

      messenger.showSnackBar(
        const SnackBar(content: Text('Lesson complete! +5 XP')),
      );

      nav.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );

      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizOk = _picked == l.correct;
    final canFinish = _labOk && quizOk && !_busy;

    final already =
        context.watch<AuthProvider>().completedLessons.contains(l.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.title),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (_yt != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: YoutubePlayer(controller: _yt!),
            )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Video placeholder: add a YouTube ID in data/lessons_data.dart',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 18),

          for (final p in l.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: const TextStyle(height: 1.5),
              ),
            ),

          const SizedBox(height: 10),

          const Text(
            'Mini-lab',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            l.goal,
            style: const TextStyle(color: AppColors.muted),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 400,
            child: ChangeNotifierProvider.value(
              value: _circuit,
              child: const CircuitWorkspace(),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _busy ? null : _check,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Check circuit'),
          ),

          if (_labMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _labMsg!,
                style: TextStyle(
                  color: _labOk ? AppColors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 24),

          const Text(
            'Quiz',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            l.question,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          for (var i = 0; i < l.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _picked = i),
                child: SoftCard(
                  color: _picked == i
                      ? (i == l.correct
                          ? const Color(0xFFDDF6E9)
                          : const Color(0xFFFDE2E2))
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.options[i])),
                      if (_picked == i)
                        Icon(
                          i == l.correct
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: i == l.correct
                              ? AppColors.green
                              : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 18),

          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                shape: const StadiumBorder(),
              ),
              onPressed: canFinish ? _complete : null,
              child: Text(
                already
                    ? 'Completed. Finish again'
                    : 'Complete lesson (+5 XP)',
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Needs: mini-lab matched and quiz answered correctly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
