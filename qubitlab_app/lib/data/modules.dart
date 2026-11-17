import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'lessons_data.dart';

class ModuleInfo {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const ModuleInfo(this.title, this.subtitle, this.color, this.icon);

  int get lessonCount => lessonsData.where((l) => l.module == modules.indexOf(this)).length;
}

const modules = <ModuleInfo>[
  ModuleInfo('The Qubit', '|0>, |1> and superposition', AppColors.orange,
      Icons.blur_circular_rounded),
  ModuleInfo('Single-Qubit Gates', 'Pauli gates, Hadamard, interference', AppColors.indigo,
      Icons.tune_rounded),
  ModuleInfo('Multi-Qubit Systems', 'CNOT, control/target, entanglement', AppColors.purple,
      Icons.link_rounded),
  ModuleInfo('Quantum Algorithms', 'Deutsch-Jozsa and Grover', AppColors.teal,
      Icons.auto_graph_rounded),
];
