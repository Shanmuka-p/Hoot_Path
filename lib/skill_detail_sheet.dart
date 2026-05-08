import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/lsrw_api_service.dart.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
const kAppGreen   = Color(0xFF008738);
const kAppGreenBg = Color(0xFFE6F4EC);
const kBlack      = Color(0xFF1A1A1A);
const kTextGrey   = Color(0xFF757575);
const kWhite      = Colors.white;

// ─── LSRW Skill Colors ────────────────────────────────────────────────────────
const _skillColors = <String, Color>{
  'listening': Color(0xFF008738), // green
  'speaking':  Color(0xFFFFBB00), // yellow
  'reading':   Color(0xFF72BD20), // lime
  'writing':   Color(0xFF2196F3), // blue
};

const _skillBgs = <String, Color>{
  'listening': Color(0xFFE6F4EC),
  'speaking':  Color(0xFFFFF8E1),
  'reading':   Color(0xFFF2FAE6),
  'writing':   Color(0xFFE3F2FD),
};

const _skillIcons = <String, IconData>{
  'listening': Icons.headphones_outlined,
  'speaking':  Icons.mic_outlined,
  'reading':   Icons.menu_book_outlined,
  'writing':   Icons.edit_outlined,
};

// ─── Skill Detail Sheet ───────────────────────────────────────────────────────
class SkillDetailSheet extends StatelessWidget {
  final String skillName;       // e.g. 'listening'
  final SkillDetail skillDetail;

  const SkillDetailSheet({
    super.key,
    required this.skillName,
    required this.skillDetail,
  });

  String get _key => skillName.toLowerCase();
  String get _displayName => skillName[0].toUpperCase() + skillName.substring(1);

  Color get _color => _skillColors[_key] ?? kAppGreen;
  Color get _bgColor => _skillBgs[_key] ?? kAppGreenBg;
  IconData get _icon => _skillIcons[_key] ?? Icons.star_outlined;

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

  String _tipFor(double pct) {
    if (pct >= 80) return 'Outstanding! Keep pushing with harder modules.';
    if (pct >= 65) return 'Good progress! Focus on medium and hard modules.';
    if (pct >= 50) return 'You\'re on track. Practice consistently to improve.';
    return 'This area needs attention. Start with easy modules and work up.';
  }

  Color _complexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'easy':   return const Color(0xFF4CAF50);
      case 'medium': return const Color(0xFFFFA726);
      case 'hard':   return const Color(0xFFEF5350);
      default:       return kTextGrey;
    }
  }

  String _complexityLabel(String c) =>
      c.isEmpty ? 'Easy' : c[0].toUpperCase() + c.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final pct         = skillDetail.percentage;
    final status      = _statusLabel(pct);
    final statusColor = _statusColor(pct);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.88, 1.0],
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, color: _color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_displayName Details',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
                          Text('${skillDetail.noAttempts} total attempts',
                              style: const TextStyle(fontSize: 12, color: kTextGrey)),
                        ],
                      ),
                    ),
                    // Percent + status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${pct.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _color)),
                        Text(status,
                            style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 18, color: kTextGrey),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    // ── Gauge card ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Performance Breakdown',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kBlack)),
                          const SizedBox(height: 16),
                          // Semicircle gauge
                          Center(
                            child: SizedBox(
                              width: 220, height: 120,
                              child: CustomPaint(
                                painter: _GaugePainter(percent: pct / 100, color: _color),
                                child: Align(
                                  alignment: const Alignment(0, 0.6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${pct.toStringAsFixed(0)}%',
                                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _color)),
                                      const Text('Overall',
                                          style: TextStyle(fontSize: 12, color: kTextGrey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 0% / 100% labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tip card ───────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: _color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBlack)),
                                const SizedBox(height: 4),
                                Text(_tipFor(pct),
                                    style: const TextStyle(fontSize: 13, color: kTextGrey, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Module breakdown header ────────────────────────────────
                    const Text('Module Breakdown',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBlack)),
                    const SizedBox(height: 12),

                    // ── Module cards from API ──────────────────────────────────
                    ...skillDetail.records.map((rec) {
                      final cc = _complexityColor(rec.complexity);
                      final cl = _complexityLabel(rec.complexity);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ModuleCard(
                          record: rec,
                          skillColor: _color,
                          complexityColor: cc,
                          complexityLabel: cl,
                        ),
                      );
                    }),

                    if (skillDetail.records.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No module data available.',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Gauge Painter (semicircle) ───────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  const _GaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final radius = size.width / 2 - 14;
    const strokeW = 20.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background
    canvas.drawArc(rect, math.pi, math.pi, false,
        Paint()..color = Colors.grey.shade200..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);

    // Foreground
    canvas.drawArc(rect, math.pi, math.pi * percent.clamp(0.0, 1.0), false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.percent != percent;
}

// ─── Module Card ──────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final ModuleRecord record;
  final Color skillColor, complexityColor;
  final String complexityLabel;

  const _ModuleCard({
    required this.record,
    required this.skillColor,
    required this.complexityColor,
    required this.complexityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = record.percentage.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Module icon (from URL or fallback)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: record.moduleIcon.isNotEmpty
                    ? Image.network(
                        record.moduleIcon, width: 36, height: 36, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _iconFallback(skillColor),
                      )
                    : _iconFallback(skillColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.moduleName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBlack),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: complexityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(complexityLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: complexityColor)),
                        ),
                        const SizedBox(width: 6),
                        Text('${record.count} attempts',
                            style: const TextStyle(fontSize: 11, color: kTextGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: skillColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100, minHeight: 5,
              backgroundColor: skillColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(skillColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconFallback(Color color) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.extension_rounded, color: color, size: 18),
    );
  }
}
