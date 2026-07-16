import 'package:flutter/material.dart';
import 'pin_gate.dart';

class SessionGuard extends StatelessWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PinGate(adminOnly: true, child: child);
  }
}
