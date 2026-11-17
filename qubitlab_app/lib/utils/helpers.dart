/// Same +/-0.05 tolerance rule the backend uses for the Arena.
bool matchesTarget(Map<String, double> target, Map<String, double> actual,
    {double tol = 0.05}) {
  final keys = {...target.keys, ...actual.keys};
  return keys.every((k) => ((target[k] ?? 0) - (actual[k] ?? 0)).abs() <= tol);
}

String describeResults(Map<String, double> r) {
  final keys = r.keys.toList()..sort();
  return keys.map((k) => '|$k> ${(r[k]! * 100).round()}%').join('  ');
}
