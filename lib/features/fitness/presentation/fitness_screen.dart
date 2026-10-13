import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF0E9F87);
  static const _targetReps = 10;

  late final AnimationController _animation;
  bool _isRunning = false;
  int _repetitions = 0;
  bool _returningToStand = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (!_isRunning) return;
    if (status == AnimationStatus.reverse) {
      _returningToStand = true;
    } else if (status == AnimationStatus.forward && _returningToStand) {
      _returningToStand = false;
      setState(() {
        _repetitions++;
        if (_repetitions >= _targetReps) {
          _isRunning = false;
          _animation.stop();
        }
      });
    }
  }

  void _toggleWorkout() {
    if (_isRunning) {
      setState(() => _isRunning = false);
      _animation.stop();
      return;
    }

    if (_repetitions >= _targetReps) {
      _repetitions = 0;
      _animation.value = 0;
    }
    setState(() => _isRunning = true);
    _animation.repeat(reverse: true);
  }

  void _restartWorkout() {
    setState(() {
      _isRunning = false;
      _repetitions = 0;
      _returningToStand = false;
    });
    _animation
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _animation
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _repetitions / _targetReps;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FA),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour à l’accueil',
        ),
        title: const Text(
          'Me mettre en forme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On bouge ? ',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Suivez le personnage et avancez à votre rythme.',
                style: TextStyle(color: Color(0xFF778196), fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D172033),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: _green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Squats',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Exercice débutant · sans matériel',
                                style: TextStyle(
                                  color: Color(0xFF8992A3),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFFFB547),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FAF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder:
                            (context, _) => CustomPaint(
                              painter: _SquatPersonPainter(
                                progress: Curves.easeInOut.transform(
                                  _animation.value,
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 188),
                                  child: Text(
                                    _isRunning
                                        ? 'Suivez le mouvement'
                                        : _repetitions == _targetReps
                                        ? 'Bravo, séance terminée !'
                                        : 'Touchez « Démarrer » pour commencer',
                                    style: const TextStyle(
                                      color: Color(0xFF738278),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Répétitions',
                          style: TextStyle(
                            color: Color(0xFF697386),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_repetitions / $_targetReps',
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE9F0EE),
                        valueColor: const AlwaysStoppedAnimation(_green),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _toggleWorkout,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: Icon(
                              _isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              _isRunning
                                  ? 'Mettre en pause'
                                  : _repetitions == _targetReps
                                  ? 'Recommencer'
                                  : 'Démarrer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          onPressed: _restartWorkout,
                          tooltip: 'Réinitialiser',
                          icon: const Icon(Icons.refresh_rounded),
                          style: IconButton.styleFrom(
                            foregroundColor: _green,
                            backgroundColor: _green.withValues(alpha: .1),
                            minimumSize: const Size(52, 52),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFE4A22B),
                      size: 21,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Gardez le dos droit et descendez doucement. Arrêtez si vous ressentez une douleur.',
                        style: TextStyle(
                          color: Color(0xFF796743),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquatPersonPainter extends CustomPainter {
  const _SquatPersonPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final cx = size.width / 2;
    final scale = math.min(size.width / 320, size.height / 250);
    final groundY = size.height * .83;
    final shoulderY = size.height * (.34 + .13 * p);
    final hipY = size.height * (.55 + .17 * p);
    final shoulderX = cx + 10 * p * scale;
    final hipX = cx + 3 * p * scale;
    final kneeY = size.height * (.72 + .04 * p);
    final kneeSpread = 21 + 11 * p;

    final floorPaint =
        Paint()
          ..color = const Color(0xFFD8EBE5)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .25, groundY),
      Offset(size.width * .75, groundY),
      floorPaint,
    );

    final shadowPaint = Paint()..color = const Color(0x160E9F87);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 2),
        width: 82 * scale,
        height: 12 * scale,
      ),
      shadowPaint,
    );

    final limbPaint =
        Paint()
          ..color = const Color(0xFF157A70)
          ..strokeWidth = 9 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final skinPaint = Paint()..color = const Color(0xFFF2B58C);
    final bodyPaint =
        Paint()
          ..color = const Color(0xFF20AD94)
          ..strokeWidth = 13 * scale
          ..strokeCap = StrokeCap.round;

    final headRadius = 17 * scale;
    final headY = shoulderY - 25 * scale;
    canvas.drawCircle(Offset(shoulderX, headY), headRadius, skinPaint);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(shoulderX, headY - 1 * scale),
        radius: headRadius,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF263849)
        ..strokeWidth = 5 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(shoulderX, shoulderY),
      Offset(hipX, hipY),
      bodyPaint,
    );

    final elbowY = shoulderY + 19 * scale;
    final handY = shoulderY + (34 + 13 * p) * scale;
    final armReach = (28 + 18 * p) * scale;
    final arms =
        Path()
          ..moveTo(shoulderX, shoulderY + 3 * scale)
          ..lineTo(shoulderX - armReach * .45, elbowY)
          ..lineTo(shoulderX - armReach, handY)
          ..moveTo(shoulderX, shoulderY + 3 * scale)
          ..lineTo(shoulderX + armReach * .45, elbowY)
          ..lineTo(shoulderX + armReach, handY);
    canvas.drawPath(arms, limbPaint);

    final leftKnee = Offset(cx - kneeSpread * scale, kneeY);
    final rightKnee = Offset(cx + kneeSpread * scale, kneeY);
    final leftFoot = Offset(cx - 28 * scale, groundY - 1 * scale);
    final rightFoot = Offset(cx + 28 * scale, groundY - 1 * scale);
    final legs =
        Path()
          ..moveTo(hipX, hipY)
          ..lineTo(leftKnee.dx, leftKnee.dy)
          ..lineTo(leftFoot.dx, leftFoot.dy)
          ..moveTo(hipX, hipY)
          ..lineTo(rightKnee.dx, rightKnee.dy)
          ..lineTo(rightFoot.dx, rightFoot.dy);
    canvas.drawPath(legs, limbPaint);

    final shoePaint =
        Paint()
          ..color = const Color(0xFF263849)
          ..strokeWidth = 8 * scale
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftFoot, leftFoot + Offset(-9 * scale, 0), shoePaint);
    canvas.drawLine(rightFoot, rightFoot + Offset(9 * scale, 0), shoePaint);
  }

  @override
  bool shouldRepaint(covariant _SquatPersonPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
