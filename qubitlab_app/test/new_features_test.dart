import 'package:flutter_test/flutter_test.dart';
import 'package:qubitlab_app/data/daily_challenges_data.dart';
import 'package:qubitlab_app/data/guided_labs_data.dart';
import 'package:qubitlab_app/models/gate.dart';
import 'package:qubitlab_app/services/api_service.dart';

void main() {
  group('DailyChallengesData', () {
    test('contains well-formed daily challenges', () {
      expect(dailyChallenges.length, greaterThanOrEqualTo(5));
      for (final ch in dailyChallenges) {
        expect(ch.id, isNotEmpty);
        expect(ch.title, isNotEmpty);
        expect(ch.concept, isNotEmpty);
        expect(ch.options.length, greaterThanOrEqualTo(2));
        expect(ch.circuitSummary, isNotEmpty);

        // Exactly one option is correct
        final correctOptions = ch.options.where((o) => o.isCorrect).toList();
        expect(correctOptions.length, equals(1));

        // Every option has a non-empty explanation
        for (final opt in ch.options) {
          expect(opt.label, isNotEmpty);
          expect(opt.explanation, isNotEmpty);
        }
      }
    });

    test('getTodayChallenge returns a valid challenge with choices', () {
      final today = getTodayChallenge();
      expect(today.id, isNotEmpty);
      expect(today.options.any((o) => o.isCorrect), isTrue);
    });
  });

  group('GuidedLabsData', () {
    test('contains all 4 key quantum phenomena', () {
      expect(guidedLabs.length, equals(4));

      final labIds = guidedLabs.map((l) => l.id).toList();
      expect(labIds, containsAll(['superposition', 'interference', 'entanglement', 'teleportation']));

      // Check Superposition
      final sup = guidedLabs.firstWhere((l) => l.id == 'superposition');
      expect(sup.qubits, equals(1));
      expect(sup.steps.length, equals(3));

      // Check Interference
      final intf = guidedLabs.firstWhere((l) => l.id == 'interference');
      expect(intf.qubits, equals(1));
      expect(intf.steps.length, equals(3));

      // Check Entanglement
      final ent = guidedLabs.firstWhere((l) => l.id == 'entanglement');
      expect(ent.qubits, equals(2));
      expect(ent.steps.length, equals(3));

      // Check Teleportation
      final tel = guidedLabs.firstWhere((l) => l.id == 'teleportation');
      expect(tel.qubits, equals(3));
      expect(tel.steps.length, equals(4));
    });

    test('each step has prompt, objective, explanation, and validator', () {
      for (final lab in guidedLabs) {
        for (final step in lab.steps) {
          expect(step.title, isNotEmpty);
          expect(step.objective, isNotEmpty);
          expect(step.physicsExplanation, isNotEmpty);
          expect(step.hintIfWrong, isNotEmpty);
        }
      }
    });

    test('step validators correctly validate gate placements', () {
      // Superposition step 1 requires an H gate on qubit 0
      final supStep1 = guidedLabs.firstWhere((l) => l.id == 'superposition').steps[0];
      expect(supStep1.validator([]), isFalse);
      expect(
        supStep1.validator([
          const PlacedGate(id: '1', type: GateType.x, column: 0, target: 0),
        ]),
        isFalse,
      );
      expect(
        supStep1.validator([
          const PlacedGate(id: '1', type: GateType.h, column: 0, target: 0),
        ]),
        isTrue,
      );

      // Entanglement step 2 requires H on q0 and CNOT from q0 to q1
      final entStep2 = guidedLabs.firstWhere((l) => l.id == 'entanglement').steps[1];
      expect(
        entStep2.validator([
          const PlacedGate(id: '1', type: GateType.h, column: 0, target: 0),
        ]),
        isFalse,
      );
      expect(
        entStep2.validator([
          const PlacedGate(id: '1', type: GateType.h, column: 0, target: 0),
          const PlacedGate(id: '2', type: GateType.cnot, column: 1, target: 1, control: 0),
        ]),
        isTrue,
      );
    });
  });

  group('MathBreakdown Model', () {
    test('parses from JSON correctly', () {
      final json = {
        'qubits': 2,
        'dimension': 4,
        'input_state_latex': r'\begin{bmatrix} 1 \\ 0 \\ 0 \\ 0 \end{bmatrix}',
        'steps': [
          {
            'step_index': 1,
            'title': 'Step 1: Column 0',
            'description': 'Apply H to q0',
            'gate_label': 'H(q0)',
            'operator_latex': r'\frac{1}{\sqrt{2}}\begin{bmatrix} 1 & 0 & 1 & 0 \\ 0 & 1 & 0 & 1 \\ 1 & 0 & -1 & 0 \\ 0 & 1 & 0 & -1 \end{bmatrix}',
            'input_state_latex': r'\begin{bmatrix} 1 \\ 0 \\ 0 \\ 0 \end{bmatrix}',
            'output_state_latex': r'\begin{bmatrix} \frac{1}{\sqrt{2}} \\ 0 \\ \frac{1}{\sqrt{2}} \\ 0 \end{bmatrix}',
            'calculation_latex': r'U_1 \times |\psi_0\rangle = |\psi_1\rangle',
            'dirac_latex': r'\frac{1}{\sqrt{2}}|00\rangle + \frac{1}{\sqrt{2}}|10\rangle',
            'probabilities': {'00': 0.5, '10': 0.5},
          }
        ],
      };

      final breakdown = MathBreakdown.fromJson(json);
      expect(breakdown.qubits, equals(2));
      expect(breakdown.dimension, equals(4));
      expect(breakdown.steps.length, equals(1));
      expect(breakdown.steps.first.gateLabel, equals('H(q0)'));
      expect(breakdown.steps.first.probabilities['00'], equals(0.5));
      expect(breakdown.steps.first.diracLatex, contains(r'|00\rangle'));
    });
  });
}
