// ─── lib/views/analytics_view.dart ────────────────────────────────────────────
//  View layer — pure UI for the Analytics/Dashboard screen.
//  All business logic delegated to AnalyticsController.
//  Updated imports point to the MVC-organized lib/services/ and lib/models/.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/models/lsrw_models.dart';
import 'package:hoot_path/controllers/analytics_controller.dart';
import 'package:hoot_path/views/skill_detail_sheet.dart';
import 'package:hoot_path/views/learning_path_view.dart';
import 'package:hoot_path/config/app_config.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
const kAppGreen = Color(0xFF008738);
const kAppGreenBg = Color(0xFFE6F4EC);
const kInsightBg = Color(0xFFF0F7F2);
const kScaffoldBg = Color(0xFFF5F5F5);
const kBlack = Color(0xFF1A1A1A);
const kTextGrey = Color(0xFF757575);
const kWhite = Colors.white;

// ─── LSRW Skill Colors ────────────────────────────────────────────────────────
const kListeningColor = Color(0xFF008738); // green
const kSpeakingColor  = Color(0xFFFFBB00); // yellow
const kReadingColor   = Color(0xFF72BD20); // lime
const kWritingColor   = Color(0xFF2196F3); // blue

const kListeningBg = Color(0xFFE6F4EC);
const kSpeakingBg  = Color(0xFFFFF8E1);
const kReadingBg   = Color(0xFFF2FAE6);
const kWritingBg   = Color(0xFFE3F2FD);

// ─── Analytics Screen (View) ──────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSkillSheet(String skill, double overallPct) {
    if (_controller.individual == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillDetailSheet(
        skillName: skill,
        skillDetail: _controller.individual!.detailFor(skill),
        overallPercentage: overallPct,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: _controller.isLoading
          ? _buildLoader()
          : _controller.error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  // ── Loader ───────────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kAppGreen),
          SizedBox(height: 16),
          Text(
            'Loading your analytics…',
            style: TextStyle(color: kTextGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: kTextGrey),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextGrey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _controller.loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAppGreen,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ─────────────────────────────────────────────────────────────
  Widget _buildContent() {
    final overall    = _controller.overall!;
    final individual = _controller.individual!;
    final overallPct = individual.userPercentage;

    final lPct = overall.listening?.percentage ?? 0;
    final sPct = overall.speaking?.percentage  ?? 0;
    final rPct = overall.reading?.percentage   ?? 0;
    final wPct = overall.writing?.percentage   ?? 0;

    return SafeArea(
      child: Column(
        children: [
          _TopBar(onRefresh: _controller.loadData),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HelloCard(),
                  const SizedBox(height: 16),
                  _PerformanceCard(
                    overallPct:  overallPct,
                    lPct: lPct, sPct: sPct, rPct: rPct, wPct: wPct,
                    lAttempts: individual.listening.noAttempts,
                    sAttempts: individual.speaking.noAttempts,
                    rAttempts: individual.reading.noAttempts,
                    wAttempts: individual.writing.noAttempts,
                    statusLabel: _controller.statusLabel(overallPct),
                    statusColor: _controller.statusColor(overallPct),
                    insightText: _controller.insightText(overall),
                    onSkillTap: (skill) {
                      final pct = <String, double>{
                        'listening': lPct,
                        'speaking':  sPct,
                        'reading':   rPct,
                        'writing':   wPct,
                      }[skill] ?? 0;
                      _openSkillSheet(skill, pct);
                    },
                  ),
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
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TopBar({required this.onRefresh});

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
                    width: 40, height: 40,
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
                    child: const Icon(Icons.notifications_outlined, color: kBlack, size: 20),
                  ),
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 12, height: 12,
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
                width: 40, height: 40,
                decoration: const BoxDecoration(color: kAppGreen, shape: BoxShape.circle),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 16),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kBlack),
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
            decoration: BoxDecoration(color: kAppGreenBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28, height: 28,
                  child: CustomPaint(painter: _BarChartIconPainter()),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Level', style: TextStyle(fontSize: 11, color: kTextGrey)),
                    Text('Intermediate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBlack)),
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
  final double overallPct;
  final double lPct, sPct, rPct, wPct;
  final int lAttempts, sAttempts, rAttempts, wAttempts;
  final String statusLabel;
  final Color statusColor;
  final String insightText;
  final void Function(String) onSkillTap;

  const _PerformanceCard({
    required this.overallPct,
    required this.lPct, required this.sPct,
    required this.rPct, required this.wPct,
    required this.lAttempts, required this.sAttempts,
    required this.rAttempts, required this.wAttempts,
    required this.statusLabel,
    required this.statusColor,
    required this.insightText,
    required this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall LSRW Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kBlack),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CustomPaint(
                  painter: _DonutPainter(l: lPct, s: sPct, r: rPct, w: wPct),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Overall', style: TextStyle(fontSize: 11, color: kTextGrey)),
                        Text(
                          '${overallPct.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kBlack),
                        ),
                        Text(
                          statusLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _SkillRow(icon: Icons.headphones_outlined, iconColor: kListeningColor, iconBg: kListeningBg, label: 'Listening', pct: lPct, onTap: () => onSkillTap('listening')),
                    const SizedBox(height: 14),
                    _SkillRow(icon: Icons.mic_outlined, iconColor: kSpeakingColor, iconBg: kSpeakingBg, label: 'Speaking', pct: sPct, onTap: () => onSkillTap('speaking')),
                    const SizedBox(height: 14),
                    _SkillRow(icon: Icons.menu_book_outlined, iconColor: kReadingColor, iconBg: kReadingBg, label: 'Reading', pct: rPct, onTap: () => onSkillTap('reading')),
                    const SizedBox(height: 14),
                    _SkillRow(icon: Icons.edit_outlined, iconColor: kWritingColor, iconBg: kWritingBg, label: 'Writing', pct: wPct, onTap: () => onSkillTap('writing')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: kInsightBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: kAppGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Insight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBlack)),
                      const SizedBox(height: 2),
                      Text(insightText, style: const TextStyle(fontSize: 12, color: kTextGrey, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 44, height: 44, child: CustomPaint(painter: _TargetIconPainter())),
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
  final Color iconColor, iconBg;
  final String label;
  final double pct;
  final VoidCallback onTap;

  const _SkillRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.pct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kBlack),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: iconColor),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(
                child: Text(
                  'Your Learning Path',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kBlack),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text('Recommended for you', style: TextStyle(fontSize: 12, color: kAppGreen, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PathStep(icon: Icons.mic_outlined, iconColor: kSpeakingColor, iconBg: kSpeakingBg, title: 'Speaking', subtitle: 'Basics', number: '7'),
              _PathArrow(),
              _PathStep(icon: Icons.edit_outlined, iconColor: kWritingColor, iconBg: kWritingBg, title: 'Writing', subtitle: 'Email Writing', number: '7'),
              _PathArrow(),
              _PathStep(icon: Icons.headphones_outlined, iconColor: kListeningColor, iconBg: kListeningBg, title: 'Listening', subtitle: 'Conversations', number: '7'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle, number;

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
      width: 75,
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBlack), textAlign: TextAlign.center),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: kTextGrey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: kAppGreenBg, borderRadius: BorderRadius.circular(20)),
            child: Text(number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kAppGreen)),
          ),
        ],
      ),
    );
  }
}

class _PathArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward_ios, color: kTextGrey, size: 14);
  }
}

// ─── Continue Button ──────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearningPathScreen(
                  userId: kUserId,
                  currentAccuracy: const {},
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kAppGreen,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Continue Learning',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painters (kept in view layer — pure UI) ───────────────────────────

class _DonutPainter extends CustomPainter {
  final double l, s, r, w;
  _DonutPainter({required this.l, required this.s, required this.r, required this.w});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 16.0;

    final total = l + s + r + w;
    final safe  = total == 0 ? 1.0 : total;

    final segments = [
      (l / safe, kListeningColor),
      (s / safe, kSpeakingColor),
      (r / safe, kReadingColor),
      (w / safe, kWritingColor),
    ];

    double startAngle = -math.pi / 2;
    for (final (sweep, color) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      final sweepAngle = sweep * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kAppGreen..style = PaintingStyle.fill;
    final barWidth = size.width / 5;
    final heights  = [size.height * 0.5, size.height * 0.8, size.height * 0.3, size.height * 0.65];
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * barWidth * 1.2, size.height - heights[i], barWidth, heights[i]),
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
    final center = Offset(size.width / 2, size.height / 2);
    final paint  = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 3; i >= 1; i--) {
      paint.color = i == 1 ? kAppGreen : kAppGreen.withOpacity(0.3);
      canvas.drawCircle(center, (size.width / 2) * (i / 3), paint);
    }
    canvas.drawCircle(center, 3, Paint()..color = kAppGreen..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
