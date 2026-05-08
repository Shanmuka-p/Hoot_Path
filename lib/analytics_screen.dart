import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/lsrw_api_service.dart.dart';
import 'package:hoot_path/skill_detail_sheet.dart';

// ─── App Theme Colors (matching HOOT app) ─────────────────────────────────────
const kAppGreen = Color(0xFF008738);
const kAppGreenBg = Color(0xFFE8F5ED);
const kBlack = Color(0xFF1A1A1A);
const kTextGrey = Color(0xFF757575);
const kWhite = Colors.white;

// ─── Hardcoded user (replace / pass via constructor as needed) ────────────────
const kUserId = '66628e2f213ad0a228fedd06'; // TODO: pass from login/session

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  OverallLsrwData? _overallData;
  IndividualLsrwData? _individualData;

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
        _overallData = results[0] as OverallLsrwData;
        _individualData = results[1] as IndividualLsrwData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _statusLabel(double pct) {
    if (pct >= 80) return 'Excellent';
    if (pct >= 65) return 'Good';
    if (pct >= 50) return 'Average';
    return 'Needs Improvement';
  }

  Color _statusColor(double pct) {
    if (pct >= 80) return const Color(0xFF008738);
    if (pct >= 65) return const Color(0xFF4CAF50);
    if (pct >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String _insightText(OverallLsrwData data) {
    // Find weakest skill
    final skills = <String, double>{
      'Listening': data.listening?.percentage ?? 0,
      'Speaking': data.speaking?.percentage ?? 0,
      'Reading': data.reading?.percentage ?? 0,
      'Writing': data.writing?.percentage ?? 0,
    };
    final weakest =
        skills.entries.reduce((a, b) => a.value < b.value ? a : b);
    final strongest =
        skills.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Your ${strongest.key} is your strongest skill (${strongest.value.toStringAsFixed(0)}%). '
        'Focus more on ${weakest.key} (${weakest.value.toStringAsFixed(0)}%) to improve overall.';
  }

  void _openSkillSheet(String skill) {
    if (_individualData == null) return;
    final detail = _individualData!.detailFor(skill);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillDetailSheet(
        skillName: skill,
        skillDetail: detail,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? _buildLoader()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kAppGreen),
          SizedBox(height: 16),
          Text('Loading your analytics…',
              style: TextStyle(color: kTextGrey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: kTextGrey),
            const SizedBox(height: 16),
            const Text('Failed to load data',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kBlack)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextGrey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAppGreen,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final overall = _overallData!;
    final individual = _individualData!;
    final overallPct = individual.userPercentage;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          backgroundColor: kWhite,
          elevation: 0,
          title: const Text(
            'Analytics',
            style: TextStyle(
                color: kBlack, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kAppGreen),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Donut Card ───────────────────────────────────────────────
                _DonutCard(
                  overallPct: overallPct,
                  statusLabel: _statusLabel(overallPct),
                  statusColor: _statusColor(overallPct),
                  listeningPct: overall.listening?.percentage ?? 0,
                  speakingPct: overall.speaking?.percentage ?? 0,
                  readingPct: overall.reading?.percentage ?? 0,
                  writingPct: overall.writing?.percentage ?? 0,
                ),

                const SizedBox(height: 20),

                // ── Insight Card ─────────────────────────────────────────────
                _InsightCard(text: _insightText(overall)),

                const SizedBox(height: 20),

                // ── LSRW Skill Rows ──────────────────────────────────────────
                const Text(
                  'Skills Breakdown',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kBlack),
                ),
                const SizedBox(height: 12),

                _SkillRow(
                  icon: Icons.headphones_rounded,
                  color: const Color(0xFF5B6CF9),
                  label: 'Listening',
                  pct: overall.listening?.percentage ?? 0,
                  attempts: individual.listening.noAttempts,
                  onTap: () => _openSkillSheet('listening'),
                ),
                const SizedBox(height: 10),
                _SkillRow(
                  icon: Icons.mic_rounded,
                  color: const Color(0xFFFF6B6B),
                  label: 'Speaking',
                  pct: overall.speaking?.percentage ?? 0,
                  attempts: individual.speaking.noAttempts,
                  onTap: () => _openSkillSheet('speaking'),
                ),
                const SizedBox(height: 10),
                _SkillRow(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF26C6DA),
                  label: 'Reading',
                  pct: overall.reading?.percentage ?? 0,
                  attempts: individual.reading.noAttempts,
                  onTap: () => _openSkillSheet('reading'),
                ),
                const SizedBox(height: 10),
                _SkillRow(
                  icon: Icons.edit_rounded,
                  color: const Color(0xFFFFB300),
                  label: 'Writing',
                  pct: overall.writing?.percentage ?? 0,
                  attempts: individual.writing.noAttempts,
                  onTap: () => _openSkillSheet('writing'),
                ),

                const SizedBox(height: 20),

                // ── Total Attempts ───────────────────────────────────────────
                _TotalAttemptsCard(total: individual.totalAttempts),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Donut Card Widget ────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final double overallPct;
  final String statusLabel;
  final Color statusColor;
  final double listeningPct;
  final double speakingPct;
  final double readingPct;
  final double writingPct;

  const _DonutCard({
    required this.overallPct,
    required this.statusLabel,
    required this.statusColor,
    required this.listeningPct,
    required this.speakingPct,
    required this.readingPct,
    required this.writingPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutPainter(
                    listening: listeningPct,
                    speaking: speakingPct,
                    reading: readingPct,
                    writing: writingPct,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${overallPct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: kBlack),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DonutLegend(
                  color: const Color(0xFF5B6CF9),
                  label: 'L',
                  pct: listeningPct),
              _DonutLegend(
                  color: const Color(0xFFFF6B6B),
                  label: 'S',
                  pct: speakingPct),
              _DonutLegend(
                  color: const Color(0xFF26C6DA),
                  label: 'R',
                  pct: readingPct),
              _DonutLegend(
                  color: const Color(0xFFFFB300),
                  label: 'W',
                  pct: writingPct),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;

  const _DonutLegend(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          '$label  ${pct.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, color: kTextGrey),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double listening;
  final double speaking;
  final double reading;
  final double writing;

  _DonutPainter({
    required this.listening,
    required this.speaking,
    required this.reading,
    required this.writing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = listening + speaking + reading + writing;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final colors = [
      const Color(0xFF5B6CF9),
      const Color(0xFFFF6B6B),
      const Color(0xFF26C6DA),
      const Color(0xFFFFB300),
    ];
    final values = [listening, speaking, reading, writing];

    double startAngle = -math.pi / 2;
    const gap = 0.04; // radians gap between segments

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * (2 * math.pi) - gap;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.listening != listening ||
      old.speaking != speaking ||
      old.reading != reading ||
      old.writing != writing;
}

// ─── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAppGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAppGreen.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: kAppGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: kBlack, height: 1.5),
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
  final Color color;
  final String label;
  final double pct;
  final int attempts;
  final VoidCallback onTap;

  const _SkillRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.pct,
    required this.attempts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kBlack)),
                      Text('$attempts attempts',
                          style: const TextStyle(
                              fontSize: 11, color: kTextGrey)),
                    ],
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: kTextGrey, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (pct.clamp(0, 100)) / 100,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Total Attempts Card ──────────────────────────────────────────────────────

class _TotalAttemptsCard extends StatelessWidget {
  final int total;
  const _TotalAttemptsCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAppGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: kAppGreen, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Total Attempts',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kBlack)),
          ),
          Text(
            '$total',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kAppGreen),
          ),
        ],
      ),
    );
  }
}