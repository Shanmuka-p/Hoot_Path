import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/lsrw_api_service.dart.dart';
import 'package:hoot_path/skill_detail_sheet.dart';
import 'package:hoot_path/learning_path_screen.dart';

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
const kSpeakingColor = Color(0xFFFFBB00); // yellow
const kReadingColor = Color(0xFF72BD20); // lime
const kWritingColor = Color(0xFF2196F3); // blue

const kListeningBg = Color(0xFFE6F4EC);
const kSpeakingBg = Color(0xFFFFF8E1);
const kReadingBg = Color(0xFFF2FAE6);
const kWritingBg = Color(0xFFE3F2FD);

// ─── Hardcoded user ID (replace from login/session) ───────────────────────────
const kUserId = '66628e2f213ad0a228fedd06';

// ─── Analytics Screen ─────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;
  String? _error;
  OverallLsrwData? _overall;
  IndividualLsrwData? _individual;
  late final LsrwApiService _api;

  @override
  void initState() {
    super.initState();
    _api = LsrwApiService(userId: kUserId);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchOverallData(),
        _api.fetchIndividualData(),
      ]);
      setState(() {
        _overall = results[0] as OverallLsrwData;
        _individual = results[1] as IndividualLsrwData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _statusLabel(double pct) {
    if (pct >= 80) return 'Excellent';
    if (pct >= 65) return 'Good';
    if (pct >= 50) return 'Average';
    return 'Needs Improvement';
  }

  Color _statusColor(double pct) {
    if (pct >= 80) return kAppGreen;
    if (pct >= 65) return const Color(0xFF4CAF50);
    if (pct >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String _insightText(OverallLsrwData data) {
    final skills = <String, double>{
      'Listening': data.listening?.percentage ?? 0,
      'Speaking': data.speaking?.percentage ?? 0,
      'Reading': data.reading?.percentage ?? 0,
      'Writing': data.writing?.percentage ?? 0,
    };
    final weakest = skills.entries.reduce((a, b) => a.value < b.value ? a : b);
    final strongest = skills.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return 'Focus more on ${weakest.key} and ${_secondWeakest(skills, weakest.key)} '
        'to improve your overall communication skills.';
  }

  String _secondWeakest(Map<String, double> skills, String weakestKey) {
    final others = skills.entries.where((e) => e.key != weakestKey).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return others.first.key;
  }

  void _openSkillSheet(String skill) {
    if (_individual == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillDetailSheet(
        skillName: skill,
        skillDetail: _individual!.detailFor(skill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: _loading
          ? _buildLoader()
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  // ── Loader ──────────────────────────────────────────────────────────────────
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

  // ── Error ───────────────────────────────────────────────────────────────────
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
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextGrey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
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

  // ── Main Content ────────────────────────────────────────────────────────────
  Widget _buildContent() {
    final overall = _overall!;
    final individual = _individual!;
    final overallPct = individual.userPercentage;

    // Per-skill percentages from overall API
    final lPct = overall.listening?.percentage ?? 0;
    final sPct = overall.speaking?.percentage ?? 0;
    final rPct = overall.reading?.percentage ?? 0;
    final wPct = overall.writing?.percentage ?? 0;

    return SafeArea(
      child: Column(
        children: [
          // ── Top Bar ─────────────────────────────────────────────────────────
          _TopBar(onRefresh: _loadData),

          // ── Scrollable Body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hello card
                  _HelloCard(),
                  const SizedBox(height: 16),

                  // ── Overall LSRW Performance card (donut + skill rows + insight) ──
                  _PerformanceCard(
                    overallPct: overallPct,
                    lPct: lPct,
                    sPct: sPct,
                    rPct: rPct,
                    wPct: wPct,
                    lAttempts: individual.listening.noAttempts,
                    sAttempts: individual.speaking.noAttempts,
                    rAttempts: individual.reading.noAttempts,
                    wAttempts: individual.writing.noAttempts,
                    statusLabel: _statusLabel(overallPct),
                    statusColor: _statusColor(overallPct),
                    insightText: _insightText(overall),
                    onSkillTap: _openSkillSheet,
                  ),
                  const SizedBox(height: 16),

                  // Learning path card
                  _LearningPathCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Continue Button ──────────────────────────────────────────────────
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
              // Bell with red dot
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
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: kBlack,
                      size: 20,
                    ),
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
              // Avatar
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
          // Level badge
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
                    Text(
                      'Level',
                      style: TextStyle(fontSize: 11, color: kTextGrey),
                    ),
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

// ─── Performance Card (donut + skill rows + insight — all in one) ─────────────
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
    required this.lPct,
    required this.sPct,
    required this.rPct,
    required this.wPct,
    required this.lAttempts,
    required this.sAttempts,
    required this.rAttempts,
    required this.wAttempts,
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
          // Title
          const Text(
            'Overall LSRW Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
          const SizedBox(height: 20),

          // Donut + skill rows side-by-side
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _DonutPainter(l: lPct, s: sPct, r: rPct, w: wPct),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Overall',
                          style: TextStyle(fontSize: 11, color: kTextGrey),
                        ),
                        Text(
                          '${overallPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kBlack,
                          ),
                        ),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Skill rows
              Expanded(
                child: Column(
                  children: [
                    _SkillRow(
                      icon: Icons.headphones_outlined,
                      iconColor: kListeningColor,
                      iconBg: kListeningBg,
                      label: 'Listening',
                      pct: lPct,
                      onTap: () => onSkillTap('listening'),
                    ),
                    const SizedBox(height: 14),
                    _SkillRow(
                      icon: Icons.mic_outlined,
                      iconColor: kSpeakingColor,
                      iconBg: kSpeakingBg,
                      label: 'Speaking',
                      pct: sPct,
                      onTap: () => onSkillTap('speaking'),
                    ),
                    const SizedBox(height: 14),
                    _SkillRow(
                      icon: Icons.menu_book_outlined,
                      iconColor: kReadingColor,
                      iconBg: kReadingBg,
                      label: 'Reading',
                      pct: rPct,
                      onTap: () => onSkillTap('reading'),
                    ),
                    const SizedBox(height: 14),
                    _SkillRow(
                      icon: Icons.edit_outlined,
                      iconColor: kWritingColor,
                      iconBg: kWritingBg,
                      label: 'Writing',
                      pct: wPct,
                      onTap: () => onSkillTap('writing'),
                    ),
                  ],
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: kAppGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insight',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insightText,
                        style: const TextStyle(
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
            '${pct.toStringAsFixed(0)}%',
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
          // Header
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
          // Steps
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
      padding: EdgeInsets.only(bottom: 28, left: 4, right: 4),
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
        child: Builder(
          builder: (context) {
            // Accessing state from the parent AnalyticsScreen
            final state = context.findAncestorStateOfType<_AnalyticsScreenState>();
            final overall = state?._overall;
            final individual = state?._individual;

            return ElevatedButton.icon(
              icon: const Icon(Icons.route, color: Colors.black),
              label: const Text(
                "AI Mentor Path",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBB00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: (overall == null || individual == null) ? null : () {
                Map<String, dynamic> accuracyPayload = {
                  "listening": overall.listening?.percentage ?? 0,
                  "speaking": overall.speaking?.percentage ?? 0,
                  "reading": overall.reading?.percentage ?? 0,
                  "writing": overall.writing?.percentage ?? 0,
                  "modules": {
                    "listening": individual.listening.toJson(),
                    "speaking": individual.speaking.toJson(),
                    "reading": individual.reading.toJson(),
                    "writing": individual.writing.toJson(),
                  }, 
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LearningPathScreen(
                      userId: kUserId,
                      currentAccuracy: accuracyPayload,
                    ),
                  ),
                );
              },
            );
          }
        ),
      ),
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

/// Donut chart with 4 LSRW segments
class _DonutPainter extends CustomPainter {
  final double l, s, r, w;
  const _DonutPainter({
    required this.l,
    required this.s,
    required this.r,
    required this.w,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = l + s + r + w;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeW = 22.0;
    const gap = 0.06;

    final colors = [
      kListeningColor,
      kSpeakingColor,
      kReadingColor,
      kWritingColor,
    ];
    final values = [l, s, r, w];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi - gap;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );
      startAngle += (values[i] / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.l != l || old.s != s || old.r != r || old.w != w;
}

/// Small bar chart icon
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * barW * 2, size.height - h, barW, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Target / bullseye icon with arrow
class _TargetIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final stroke = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 18, stroke);
    canvas.drawCircle(Offset(cx, cy), 12, stroke);
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
    );
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}
