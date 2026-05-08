import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hoot_path/lsrw_api_service.dart.dart';

// ─── App Theme Colors ─────────────────────────────────────────────────────────
const kAppGreen = Color(0xFF008738);
const kAppGreenBg = Color(0xFFE8F5ED);
const kBlack = Color(0xFF1A1A1A);
const kTextGrey = Color(0xFF757575);
const kWhite = Colors.white;

// ─── Skill color map ──────────────────────────────────────────────────────────
const _skillColors = {
  'listening': Color(0xFF5B6CF9),
  'speaking': Color(0xFFFF6B6B),
  'reading': Color(0xFF26C6DA),
  'writing': Color(0xFFFFB300),
};

const _skillIcons = {
  'listening': Icons.headphones_rounded,
  'speaking': Icons.mic_rounded,
  'reading': Icons.menu_book_rounded,
  'writing': Icons.edit_rounded,
};

// ─── SkillDetailSheet ─────────────────────────────────────────────────────────

class SkillDetailSheet extends StatelessWidget {
  final String skillName; // e.g. 'listening'
  final SkillDetail skillDetail;

  const SkillDetailSheet({
    super.key,
    required this.skillName,
    required this.skillDetail,
  });

  String get _displayName =>
      skillName[0].toUpperCase() + skillName.substring(1);

  Color get _color => _skillColors[skillName.toLowerCase()] ?? kAppGreen;

  IconData get _icon =>
      _skillIcons[skillName.toLowerCase()] ?? Icons.star_rounded;

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

  String _complexityLabel(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return complexity;
    }
  }

  Color _complexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'hard':
        return const Color(0xFFEF5350);
      default:
        return kTextGrey;
    }
  }

  String _tipFor(double pct) {
    if (pct >= 80) {
      return 'Outstanding performance! Keep up the great work and try harder modules to push further.';
    } else if (pct >= 65) {
      return 'Good progress! Focus on the medium and hard modules to boost your score higher.';
    } else if (pct >= 50) {
      return 'You\'re on the right track. Revisit easy modules and practice consistently to improve.';
    } else {
      return 'This area needs more attention. Start with the easy modules and gradually move up.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = skillDetail.percentage;
    final status = _statusLabel(pct);
    final statusColor = _statusColor(pct);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, color: _color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_displayName Skills',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kBlack,
                          ),
                        ),
                        Text(
                          '${skillDetail.noAttempts} total attempts',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextGrey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: kTextGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // ── Gauge ────────────────────────────────────────────────
                    Center(
                      child: _GaugeWidget(
                        percentage: pct,
                        color: _color,
                        statusLabel: status,
                        statusColor: statusColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tip ──────────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kAppGreenBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kAppGreen.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_outlined,
                            color: kAppGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tipFor(pct),
                              style: const TextStyle(
                                fontSize: 13,
                                color: kBlack,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Module Breakdown ─────────────────────────────────────
                    const Text(
                      'Module Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kBlack,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (skillDetail.records.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No module data available.',
                            style: TextStyle(color: kTextGrey),
                          ),
                        ),
                      )
                    else
                      ...skillDetail.records.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ModuleCard(
                            record: r,
                            skillColor: _color,
                            complexityColor: _complexityColor(r.complexity),
                            complexityLabel: _complexityLabel(r.complexity),
                          ),
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

// ─── Gauge Widget ─────────────────────────────────────────────────────────────

class _GaugeWidget extends StatelessWidget {
  final double percentage;
  final Color color;
  final String statusLabel;
  final Color statusColor;

  const _GaugeWidget({
    required this.percentage,
    required this.color,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 130),
            painter: _GaugePainter(
              percentage: percentage.clamp(0, 100),
              color: color,
            ),
          ),
          Positioned(
            bottom: 10,
            child: Column(
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kBlack,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = (percentage / 100) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.percentage != percentage;
}

// ─── Module Card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final ModuleRecord record;
  final Color skillColor;
  final Color complexityColor;
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Module icon from URL
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: record.moduleIcon.isNotEmpty
                    ? Image.network(
                        record.moduleIcon,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: skillColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.extension_rounded,
                            color: skillColor,
                            size: 18,
                          ),
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: skillColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.extension_rounded,
                          color: skillColor,
                          size: 18,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.moduleName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: complexityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            complexityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: complexityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${record.count} attempts',
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: skillColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: skillColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(skillColor),
            ),
          ),
        ],
      ),
    );
  }
}
