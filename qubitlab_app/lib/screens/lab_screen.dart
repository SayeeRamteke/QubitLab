import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/circuit_provider.dart';
import '../providers/saved_circuits_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_workspace.dart';
import '../widgets/math_breakdown_view.dart';
import '../widgets/results_sheet.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  bool _isMathMode = false;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CircuitProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            _LabHeader(
              isMathMode: _isMathMode,
              onToggleMode: (val) => setState(() => _isMathMode = val),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final isMath = child.key == const ValueKey('math');
                  final offsetTween = Tween<Offset>(
                    begin: Offset(isMath ? 1.0 : -1.0, 0.0),
                    end: Offset.zero,
                  );
                  return SlideTransition(
                    position: animation.drive(offsetTween),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _isMathMode
                    ? MathBreakdownView(
                        key: const ValueKey('math'),
                        circuit: c.toJson(),
                      )
                    : const CircuitWorkspace(
                        key: ValueKey('canvas'),
                        overlay: _SimulateButton(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabHeader extends StatefulWidget {
  final bool isMathMode;
  final ValueChanged<bool> onToggleMode;

  const _LabHeader({
    required this.isMathMode,
    required this.onToggleMode,
  });

  @override
  State<_LabHeader> createState() => _LabHeaderState();
}

class _LabHeaderState extends State<_LabHeader> {
  final _nameCtl = TextEditingController();
  CircuitProvider? _circuit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _circuit ??= context.read<CircuitProvider>()..addListener(_syncName);
    _syncName();
  }

  void _syncName() {
    final n = _circuit!.name;
    if (_nameCtl.text != n) _nameCtl.text = n; // happens when a saved circuit is loaded
  }

  @override
  void dispose() {
    _circuit?.removeListener(_syncName);
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = context.read<CircuitProvider>();
    final auth = context.read<AuthProvider>();
    final saved = context.read<SavedCircuitsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (c.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Add a gate before saving')));
      return;
    }
    try {
      await api.saveCircuit(
        userId: auth.userId!,
        name: _nameCtl.text.trim().isEmpty ? 'Untitled circuit' : _nameCtl.text.trim(),
        qubits: c.qubits,
        gates: c.toStorageGates(),
      );
      await saved.load(auth.userId!);
      messenger.showSnackBar(const SnackBar(content: Text('Circuit saved')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showCode(CircuitProvider c) {
    showDialog(
      context: context,
      builder: (ctx) => _CircuitCodeDialog(circuit: c),
    );
  }

  void _showJson(CircuitProvider c) {
    final text = const JsonEncoder.withIndent('  ').convert(c.toJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request JSON'),
        content: SingleChildScrollView(
          child: SelectableText(text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CircuitProvider>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtl,
                onChanged: c.setName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Circuit name',
                  isDense: true,
                ),
              ),
            ),
            IconButton(tooltip: 'Save', onPressed: _save, icon: const Icon(Icons.save_outlined)),
            IconButton(
                tooltip: 'Circuit Code (Export & Generate)',
                onPressed: () => _showCode(c),
                icon: const Icon(Icons.code_rounded)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'code') _showCode(c);
                if (v == 'json') _showJson(c);
                if (v == 'clear') c.clear();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'code',
                  child: Row(
                    children: [
                      Icon(Icons.code_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Generate from code'),
                    ],
                  ),
                ),
                PopupMenuItem(value: 'json', child: Text('View request JSON')),
                PopupMenuItem(value: 'clear', child: Text('Clear circuit')),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: c.qubits > 1 ? c.removeQubit : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text('${c.qubits} qubit${c.qubits == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: c.qubits < CircuitProvider.maxQubits ? c.addQubit : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeButton(
                    title: 'Canvas',
                    icon: Icons.grid_view_rounded,
                    isSelected: !widget.isMathMode,
                    onTap: () => widget.onToggleMode(false),
                  ),
                  const SizedBox(width: 4),
                  _modeButton(
                    title: 'Math',
                    icon: Icons.functions_rounded,
                    isSelected: widget.isMathMode,
                    onTap: () => widget.onToggleMode(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircuitCodeDialog extends StatefulWidget {
  final CircuitProvider circuit;
  const _CircuitCodeDialog({required this.circuit});

  @override
  State<_CircuitCodeDialog> createState() => _CircuitCodeDialogState();
}

class _CircuitCodeDialogState extends State<_CircuitCodeDialog> {
  late final TextEditingController _codeCtl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeCtl = TextEditingController(text: widget.circuit.toQiskitCode());
  }

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  void _generateCircuit() {
    final code = _codeCtl.text;
    final res = widget.circuit.loadFromCode(code);
    if (!res.isSuccess) {
      setState(() => _error = res.error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Circuit generated successfully (${res.qubits} qubits, ${res.gates.length} gates)'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  void _applySnippet(String code) {
    setState(() {
      _error = null;
      _codeCtl.text = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: AppColors.indigo),
                      SizedBox(width: 8),
                      Text('Circuit Code',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'View generated Qiskit code or edit/paste code to generate the circuit.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Snippet presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Presets: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    _presetChip('Bell State', '''from qiskit import QuantumCircuit
qc = QuantumCircuit(2)
qc.h(0)
qc.cx(0, 1)'''),
                    const SizedBox(width: 6),
                    _presetChip('GHZ State', '''from qiskit import QuantumCircuit
qc = QuantumCircuit(3)
qc.h(0)
qc.cx(0, 1)
qc.cx(1, 2)'''),
                    const SizedBox(width: 6),
                    _presetChip('Superposition', '''from qiskit import QuantumCircuit
qc = QuantumCircuit(2)
qc.h(0)
qc.h(1)'''),
                    const SizedBox(width: 6),
                    _presetChip('Grover Step', '''from qiskit import QuantumCircuit
qc = QuantumCircuit(2)
qc.h(0)
qc.h(1)
qc.cz(0, 1)
qc.h(0)
qc.h(1)'''),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Code Editor Box
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _error != null ? Colors.redAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _codeCtl,
                  maxLines: null,
                  expands: true,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFFB9F6CA),
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Enter Qiskit code (e.g. qc.h(0), qc.cx(0, 1))...',
                    hintStyle: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _codeCtl.text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                      }
                    },
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    onPressed: _generateCircuit,
                    label: const Text('Generate Circuit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, String code) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () => _applySnippet(code),
    );
  }
}

class _SimulateButton extends StatefulWidget {
  const _SimulateButton();

  @override
  State<_SimulateButton> createState() => _SimulateButtonState();
}

class _SimulateButtonState extends State<_SimulateButton> {
  bool _busy = false;

  Future<void> _run() async {
    final c = context.read<CircuitProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final sim = await api.simulateDetailed(c.toJson());
      if (mounted) showResultsSheet(context, sim.probabilities, sim.blochVectors);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'simulate',
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.play_arrow_rounded),
      label: const Text('Simulate'),
    );
  }
}
