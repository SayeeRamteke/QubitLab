import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/guided_labs_data.dart';
import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_workspace.dart';
import '../widgets/results_sheet.dart';
import '../services/api_service.dart';
import 'app_shell.dart';

class GuidedLabSessionScreen extends StatefulWidget {
  final GuidedLab lab;
  const GuidedLabSessionScreen({super.key, required this.lab});

  @override
  State<GuidedLabSessionScreen> createState() => _GuidedLabSessionScreenState();
}

class _GuidedLabSessionScreenState extends State<GuidedLabSessionScreen> {
  late final CircuitProvider _circuit;
  late final ConfettiController _confetti;
  int _currentStepIndex = 0;
  bool _stepPassed = false;
  String? _hintMessage;
  bool _showExplanation = true;
  bool _busy = false;

  GuidedLab get lab => widget.lab;
  LabStep get currentStep => lab.steps[_currentStepIndex];

  @override
  void initState() {
    super.initState();
    _circuit = CircuitProvider(qubits: lab.qubits);
    _circuit.addListener(_onCircuitChanged);
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _validateCurrentStep();
  }

  @override
  void dispose() {
    _circuit.removeListener(_onCircuitChanged);
    _circuit.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onCircuitChanged() {
    _validateCurrentStep();
  }

  void _validateCurrentStep() {
    final passed = currentStep.validator(_circuit.gates);
    setState(() {
      _stepPassed = passed;
      if (!passed && _circuit.gates.isNotEmpty) {
        _hintMessage = currentStep.hintIfWrong;
      } else {
        _hintMessage = null;
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < lab.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _stepPassed = false;
        _hintMessage = null;
      });
      _validateCurrentStep();
    } else {
      _completeLab();
    }
  }

  Future<void> _completeLab() async {
    _confetti.play();
    final auth = context.read<AuthProvider>();
    // Award 25 XP
    await auth.refreshUser();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            const Text('Lab Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You successfully completed the ${lab.title} guided experience!',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDFD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.orange, size: 22),
                  SizedBox(width: 8),
                  Text('+25 XP Awarded', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Labs'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              // Load circuit into sandbox and navigate to Lab
              context.read<CircuitProvider>().loadFrom(
                    lab.title,
                    _circuit.qubits,
                    _circuit.toStorageGates(),
                  );
              shellTab.value = 3; // Lab tab
            },
            child: const Text('Open in Sandbox'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulate() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final sim = await api.simulateDetailed(_circuit.toJson());
      if (mounted) showResultsSheet(context, sim.probabilities, sim.blochVectors);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStepIndex + 1) / lab.steps.length;

    return ChangeNotifierProvider.value(
      value: _circuit,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lab.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text(
                'Step ${_currentStepIndex + 1} of ${lab.steps.length} • ${lab.difficulty}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              color: lab.color,
              backgroundColor: lab.color.withAlpha(40),
              minHeight: 4,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Reset circuit',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _circuit.clear(),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Step Guidance Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _stepPassed
                          ? const Color(0xFF81C784)
                          : (_hintMessage != null ? const Color(0xFFFFB74D) : Colors.black12),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _stepPassed
                                  ? const Color(0xFFE8F5E9)
                                  : lab.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _stepPassed
                                  ? 'STEP ${_currentStepIndex + 1} READY'
                                  : 'STEP ${_currentStepIndex + 1} GOAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _stepPassed
                                    ? const Color(0xFF2E7D32)
                                    : lab.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentStep.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _showExplanation = !_showExplanation),
                            child: Icon(
                              _showExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.muted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentStep.objective,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                      if (_showExplanation) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.school_rounded, size: 16, color: AppColors.indigo),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentStep.physicsExplanation,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_hintMessage != null && !_stepPassed) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFE65100)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hintMessage!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFBF360C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Interactive Workspace
                Expanded(
                  child: CircuitWorkspace(
                    overlay: FloatingActionButton.extended(
                      heroTag: 'simulate_guided',
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      onPressed: _busy ? null : _simulate,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text('Simulate'),
                    ),
                  ),
                ),

                // Bottom Step Action Bar
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _stepPassed ? 'Objective fulfilled!' : 'Complete the step above',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _stepPassed ? const Color(0xFF2E7D32) : AppColors.muted,
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _stepPassed ? lab.color : Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: _stepPassed ? _nextStep : null,
                          icon: Icon(
                            _currentStepIndex == lab.steps.length - 1
                                ? Icons.emoji_events_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _currentStepIndex == lab.steps.length - 1
                                ? 'Finish Lab'
                                : 'Next Step',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
