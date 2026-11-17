import 'package:flutter/material.dart';
import '../models/gate.dart';

class GateTile extends StatelessWidget {
  final GateType type;
  final double size;
  final bool lifted;
  const GateTile({super.key, required this.type, this.size = 48, this.lifted = false});

  @override
  Widget build(BuildContext context) {
    final label = type.apiName;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: lifted
            ? const [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: label.length > 2 ? 11 : 18,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
