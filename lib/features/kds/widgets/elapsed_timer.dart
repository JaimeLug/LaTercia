import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ElapsedTimer extends StatefulWidget {
  final DateTime startTime;
  final int warnYellowMinutes;
  final int warnRedMinutes;
  final double fontSize;

  const ElapsedTimer({
    super.key,
    required this.startTime,
    this.warnYellowMinutes = 5,
    this.warnRedMinutes = 10,
    this.fontSize = 20,
  });

  /// Color de estado según el tiempo transcurrido, compartido con la UI que
  /// replica el código de color del KDS (ej. la cola del POS).
  static Color colorFor(Duration elapsed, int warnYellow, int warnRed) {
    final minutes = elapsed.inMinutes;
    if (minutes >= warnRed) return LaTerciaColors.timerLate;
    if (minutes >= warnYellow) return LaTerciaColors.timerWarn;
    return LaTerciaColors.timerOk;
  }

  @override
  State<ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<ElapsedTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnimation =
        Tween<double>(begin: 1, end: 0.35).animate(_blinkController);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startTime);
    final minutes = elapsed.inMinutes;
    final color = ElapsedTimer.colorFor(
        elapsed, widget.warnYellowMinutes, widget.warnRedMinutes);

    final text = Text(
      formatElapsed(elapsed),
      style: TextStyle(
        fontFamily: 'DM Serif Display',
        color: color,
        fontSize: widget.fontSize,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (minutes >= widget.warnRedMinutes) {
      return FadeTransition(opacity: _blinkAnimation, child: text);
    }
    return text;
  }
}
