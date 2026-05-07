import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/skill_detail_sheet.dart';

// ─── App Theme Colors (matching HOOT app) ────────────────────────────────────
const kAppGreen      = Color(0xFF008738); // primary brand green
const kAppGreenBg    = Color(0xFFE6F4EC); // light green background
const kInsightBg     = Color(0xFFEEF7F2);
const kBlack         = Color(0xFF1A1A1A);
const kTextGrey      = Color(0xFF757575);
const kWhite         = Colors.white;
const kScaffoldBg    = Color(0xFFF5F5F5);

// ─── LSRW Skill Colors ────────────────────────────────────────────────────────
const kListeningColor = Color(0xFF008738); // green
const kSpeakingColor  = Color(0xFFFFBB00); // yellow/amber
const kReadingColor   = Color(0xFF72BD20); // lime green
const kWritingColor   = Color(0xFF2196F3); // blue

// Skill bg tints
const kListeningBg = Color(0xFFE6F4EC);
const kSpeakingBg  = Color(0xFFFFF8E1);
const kReadingBg   = Color(0xFFF2FAE6);
const kWritingBg   = Color(0xFFE3F2FD);

// ─── Analytics Screen ─────────────────────────────────────────────────────────
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelloCard(),
                    const SizedBox(height: 16),
                    _PerformanceCard(),
                    const SizedBox(height: 16),
                    _LearningPathCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _ContinueButton(),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kBlack,
            ),
          ),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: kBlack, size: 20),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: kAppGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Hello Card ───────────────────────────────────────────────────────────────
class _HelloCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hello, Shannu! 👋',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Keep practicing and improve every day.',
                  style: TextStyle(fontSize: 13, color: kTextGrey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kAppGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(painter: _BarChartIconPainter()),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Level',
                        style: TextStyle(fontSize: 11, color: kTextGrey)),
                    Text(
                      'Intermediate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kBlack,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Performance Card ─────────────────────────────────────────────────────────
class _PerformanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall LSRW Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(painter: _DonutChartPainter()),
              ),
              const SizedBox(width: 16),
              // Skills list
              Expanded(
                child: Builder(builder: (context) {
                  return Column(
                    children: [
                      _SkillRow(
                        icon: Icons.headphones_outlined,
                        iconColor: kListeningColor,
                        iconBg: kListeningBg,
                        label: 'Listening',
                        percent: 70,
                        onTap: () => showSkillBottomSheet(context, listeningDetail),
                      ),
                      const SizedBox(height: 14),
                      _SkillRow(
                        icon: Icons.mic_outlined,
                        iconColor: kSpeakingColor,
                        iconBg: kSpeakingBg,
                        label: 'Speaking',
                        percent: 45,
                        onTap: () => showSkillBottomSheet(context, speakingDetail),
                      ),
                      const SizedBox(height: 14),
                      _SkillRow(
                        icon: Icons.menu_book_outlined,
                        iconColor: kReadingColor,
                        iconBg: kReadingBg,
                        label: 'Reading',
                        percent: 75,
                        onTap: () => showSkillBottomSheet(context, readingDetail),
                      ),
                      const SizedBox(height: 14),
                      _SkillRow(
                        icon: Icons.edit_outlined,
                        iconColor: kWritingColor,
                        iconBg: kWritingBg,
                        label: 'Writing',
                        percent: 35,
                        onTap: () => showSkillBottomSheet(context, writingDetail),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Insight box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kInsightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: kAppGreen, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insight',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kBlack,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Focus more on Speaking and Writing to improve your overall communication skills.',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(painter: _TargetIconPainter()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skill Row ────────────────────────────────────────────────────────────────
class _SkillRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int percent;
  final VoidCallback? onTap;

  const _SkillRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.percent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kBlack,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: kTextGrey, size: 18),
        ],
      ),
    );
  }
}

// ─── Learning Path Card ───────────────────────────────────────────────────────
class _LearningPathCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(
                child: Text(
                  'Your Learning Path',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Recommended for you',
                style: TextStyle(
                  fontSize: 12,
                  color: kAppGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PathStep(
                icon: Icons.mic_outlined,
                iconColor: kSpeakingColor,
                iconBg: kSpeakingBg,
                title: 'Speaking',
                subtitle: 'Basics',
                number: '7',
              ),
              _PathArrow(),
              _PathStep(
                icon: Icons.edit_outlined,
                iconColor: kWritingColor,
                iconBg: kWritingBg,
                title: 'Writing',
                subtitle: 'Email Writing',
                number: '7',
              ),
              _PathArrow(),
              _PathStep(
                icon: Icons.headphones_outlined,
                iconColor: kListeningColor,
                iconBg: kListeningBg,
                title: 'Listening',
                subtitle: 'Conversations',
                number: '7',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String number;

  const _PathStep({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: kAppGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kBlack,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: kTextGrey),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _PathArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24, left: 4, right: 4),
      child: Icon(Icons.arrow_forward, color: kTextGrey, size: 18),
    );
  }
}

// ─── Continue Button ──────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: kAppGreen,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue Learning',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 10;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final segments = [
      (kListeningColor, 0.28), // Listening
      (kSpeakingColor,  0.18), // Speaking
      (kReadingColor,   0.30), // Reading
      (kWritingColor,   0.14), // Writing
      (const Color(0xFFE0E0E0), 0.10), // remainder
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    const gap = 0.04;
    for (final seg in segments) {
      final sweep = seg.$2 * math.pi * 2 - gap;
      paint.color = seg.$1;
      canvas.drawArc(rect, startAngle + gap / 2, sweep, false, paint);
      startAngle += seg.$2 * math.pi * 2;
    }

    // Center labels
    final overallTP = TextPainter(
      text: const TextSpan(
          text: 'Overall',
          style: TextStyle(color: kTextGrey, fontSize: 11)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    overallTP.paint(canvas, Offset(cx - overallTP.width / 2, cy - 26));

    final pctTP = TextPainter(
      text: const TextSpan(
        text: '60%',
        style: TextStyle(color: kBlack, fontSize: 22, fontWeight: FontWeight.w800),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    pctTP.paint(canvas, Offset(cx - pctTP.width / 2, cy - 10));

    final goodTP = TextPainter(
      text: const TextSpan(
        text: 'Good',
        style: TextStyle(color: kAppGreen, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    goodTP.paint(canvas, Offset(cx - goodTP.width / 2, cy + 14));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAppGreen
      ..style = PaintingStyle.fill;
    final bars = [0.4, 0.65, 1.0, 0.75];
    final barW = size.width / (bars.length * 2 - 1);
    for (int i = 0; i < bars.length; i++) {
      final h = size.height * bars[i];
      final x = i * barW * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barW, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TargetIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final stroke = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 18, stroke);
    canvas.drawCircle(Offset(cx, cy), 12, stroke);
    canvas.drawCircle(Offset(cx, cy), 5,
        Paint()..color = Colors.red..style = PaintingStyle.fill);
    final arrow = Paint()
      ..color = const Color(0xFFFF7043)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 8, cy - 14), Offset(cx + 18, cy - 22), arrow);
    canvas.drawLine(Offset(cx + 18, cy - 22), Offset(cx + 12, cy - 22), arrow);
    canvas.drawLine(Offset(cx + 18, cy - 22), Offset(cx + 18, cy - 16), arrow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
