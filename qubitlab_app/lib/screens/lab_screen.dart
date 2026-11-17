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
import '../widgets/results_sheet.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            _LabHeader(),
            SizedBox(height: 10),
            Expanded(child: CircuitWorkspace(overlay: _SimulateButton())),
          ],
        ),
      ),
    );
  }
}

class _LabHeader extends StatefulWidget {
  const _LabHeader();

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
    final code = c.toQiskitCode();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qiskit code'),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF1C1C28), borderRadius: BorderRadius.circular(12)),
            child: SelectableText(code,
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12, color: Color(0xFFB9F6CA))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
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
                tooltip: 'View Qiskit code',
                onPressed: () => _showCode(c),
                icon: const Icon(Icons.data_object_rounded)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'json') _showJson(c);
                if (v == 'clear') c.clear();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'json', child: Text('View request JSON')),
                PopupMenuItem(value: 'clear', child: Text('Clear circuit')),
              ],
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
        ),
      ],
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
      final results = await api.simulate(c.toJson());
      if (mounted) showResultsSheet(context, results);
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
