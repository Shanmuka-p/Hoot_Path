import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─── App Theme Colors ─────────────────────────────────────────────────────────
const kAppGreen   = Color(0xFF008738);
const kBlack      = Color(0xFF1A1A1A);
const kTextGrey   = Color(0xFF757575);
const kWhite      = Colors.white;

// ─── LSRW Skill Colors ────────────────────────────────────────────────────────
const kListeningColor = Color(0xFF008738); // green
const kSpeakingColor  = Color(0xFFFFBB00); // yellow
const kReadingColor   = Color(0xFF72BD20); // lime green
const kWritingColor   = Color(0xFF2196F3); // blue

const kListeningBg = Color(0xFFE6F4EC);
const kSpeakingBg  = Color(0xFFFFF8E1);
const kReadingBg   = Color(0xFFF2FAE6);
const kWritingBg   = Color(0xFFE3F2FD);

// ─── Models ───────────────────────────────────────────────────────────────────
class SkillDetail {
  final String title;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final int overall;
  final String status;
  final Color statusColor;
  final List<SubSkill> subSkills;
  final String tip;

  const SkillDetail({
    required this.title,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.overall,
    required this.status,
    required this.statusColor,
    required this.subSkills,
    required this.tip,
  });
}

class SubSkill {
  final String name;
  final IconData icon;
  final int percent;
  final Color barColor;

  const SubSkill({
    required this.name,
    required this.icon,
    required this.percent,
    required this.barColor,
  });
}

// ─── Data ─────────────────────────────────────────────────────────────────────
final listeningDetail = SkillDetail(
  title: 'Listening',
  color: kListeningColor,
  bgColor: kListeningBg,
  icon: Icons.headphones_outlined,
  overall: 70,
  status: 'Good',
  statusColor: kListeningColor,
  tip: 'Great job! Try listening to advanced conversations.',
  subSkills: const [
    SubSkill(name: 'Comprehension', icon: Icons.psychology_outlined,         percent: 75, barColor: kListeningColor),
    SubSkill(name: 'Focus',         icon: Icons.center_focus_strong_outlined, percent: 70, barColor: kListeningColor),
    SubSkill(name: 'Vocabulary',    icon: Icons.abc_outlined,                 percent: 65, barColor: kListeningColor),
    SubSkill(name: 'Detail Recall', icon: Icons.bookmark_outline,             percent: 70, barColor: kListeningColor),
    SubSkill(name: 'Inference',     icon: Icons.lightbulb_outline,            percent: 70, barColor: kListeningColor),
  ],
);

final speakingDetail = SkillDetail(
  title: 'Speaking',
  color: kSpeakingColor,
  bgColor: kSpeakingBg,
  icon: Icons.mic_outlined,
  overall: 45,
  status: 'Needs Improvement',
  statusColor: Colors.orange,
  tip: 'Speak slowly and clearly. Practice conversations every day.',
  subSkills: const [
    SubSkill(name: 'Pronunciation', icon: Icons.record_voice_over_outlined, percent: 40, barColor: kSpeakingColor),
    SubSkill(name: 'Fluency',       icon: Icons.speed_outlined,             percent: 45, barColor: kSpeakingColor),
    SubSkill(name: 'Grammar',       icon: Icons.spellcheck_outlined,        percent: 50, barColor: kSpeakingColor),
    SubSkill(name: 'Confidence',    icon: Icons.emoji_emotions_outlined,    percent: 45, barColor: kSpeakingColor),
    SubSkill(name: 'Vocabulary',    icon: Icons.abc_outlined,               percent: 50, barColor: kSpeakingColor),
  ],
);

final readingDetail = SkillDetail(
  title: 'Reading',
  color: kReadingColor,
  bgColor: kReadingBg,
  icon: Icons.menu_book_outlined,
  overall: 75,
  status: 'Good',
  statusColor: kReadingColor,
  tip: 'Excellent! Keep reading and try complex articles.',
  subSkills: const [
    SubSkill(name: 'Speed',         icon: Icons.timer_outlined,         percent: 70, barColor: kReadingColor),
    SubSkill(name: 'Comprehension', icon: Icons.psychology_outlined,    percent: 80, barColor: kReadingColor),
    SubSkill(name: 'Vocabulary',    icon: Icons.abc_outlined,           percent: 75, barColor: kReadingColor),
    SubSkill(name: 'Accuracy',      icon: Icons.check_circle_outline,   percent: 75, barColor: kReadingColor),
    SubSkill(name: 'Inference',     icon: Icons.lightbulb_outline,      percent: 70, barColor: kReadingColor),
  ],
);

final writingDetail = SkillDetail(
  title: 'Writing',
  color: kWritingColor,
  bgColor: kWritingBg,
  icon: Icons.edit_outlined,
  overall: 35,
  status: 'Needs Improvement',
  statusColor: Colors.orange,
  tip: 'Practice email writing daily to improve your professional communication.',
  subSkills: const [
    SubSkill(name: 'Email Writing',     icon: Icons.email_outlined,       percent: 30, barColor: kWritingColor),
    SubSkill(name: 'Paragraph Writing', icon: Icons.article_outlined,     percent: 40, barColor: kWritingColor),
    SubSkill(name: 'Essay Writing',     icon: Icons.description_outlined, percent: 35, barColor: kWritingColor),
    SubSkill(name: 'Grammar',           icon: Icons.spellcheck_outlined,  percent: 45, barColor: kWritingColor),
    SubSkill(name: 'Vocabulary Usage',  icon: Icons.abc_outlined,         percent: 50, barColor: kWritingColor),
  ],
);

// ─── Show Helper ─────────────────────────────────────────────────────────────
void showSkillBottomSheet(BuildContext context, SkillDetail detail) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => _SkillBottomSheet(detail: detail),
  );
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────
class _SkillBottomSheet extends StatefulWidget {
  final SkillDetail detail;
  const _SkillBottomSheet({required this.detail});

  @override
  State<_SkillBottomSheet> createState() => _SkillBottomSheetState();
}

class _SkillBottomSheetState extends State<_SkillBottomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.75, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SheetHeader(d: d),
                    const SizedBox(height: 20),
                    _GaugeCard(d: d),
                    const SizedBox(height: 16),
                    _SubSkillsCard(d: d),
                    const SizedBox(height: 16),
                    _TipCard(d: d),
                    const SizedBox(height: 24),
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

// ─── Sheet Header ─────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final SkillDetail d;
  const _SheetHeader({required this.d});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: kBlack, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '${d.title} Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kBlack,
          ),
        ),
      ],
    );
  }
}

// ─── Gauge Card ───────────────────────────────────────────────────────────────
class _GaugeCard extends StatelessWidget {
  final SkillDetail d;
  const _GaugeCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Icon + title + status row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: d.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(d.icon, color: d.color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                d.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${d.overall}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: d.color,
                    ),
                  ),
                  Text(
                    d.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: d.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Performance Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kBlack,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Semicircle gauge
          SizedBox(
            width: 220,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(
                percent: d.overall / 100,
                color: d.color,
                bgColor: d.bgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub Skills Card ──────────────────────────────────────────────────────────
class _SubSkillsCard extends StatelessWidget {
  final SkillDetail d;
  const _SubSkillsCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: d.subSkills.map((s) => _SubSkillRow(skill: s)).toList(),
      ),
    );
  }
}

class _SubSkillRow extends StatelessWidget {
  final SubSkill skill;
  const _SubSkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: skill.barColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(skill.icon, color: skill.barColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kBlack,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: skill.percent / 100,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(skill.barColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${skill.percent}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: skill.barColor,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: kTextGrey, size: 18),
        ],
      ),
    );
  }
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final SkillDetail d;
  const _TipCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: d.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: d.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.tip,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextGrey,
                    height: 1.5,
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

// ─── Gauge Painter ────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color bgColor;

  const _GaugePainter({
    required this.percent,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 14;
    const strokeW = 20.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background arc
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Filled arc
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * percent,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // 0% label
    final tp0 = TextPainter(
      text: TextSpan(
          text: '0%',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp0.paint(canvas, Offset(2, cy + 8));

    // 100% label
    final tp100 = TextPainter(
      text: TextSpan(
          text: '100%',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp100.paint(canvas, Offset(size.width - tp100.width - 2, cy + 8));

    // Percent value
    final pctTP = TextPainter(
      text: TextSpan(
        text: '${(percent * 100).round()}%',
        style: TextStyle(
            color: color, fontSize: 28, fontWeight: FontWeight.w800),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    pctTP.paint(canvas, Offset(cx - pctTP.width / 2, cy - 40));

    // "Overall" label
    final ovTP = TextPainter(
      text: TextSpan(
          text: 'Overall',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    ovTP.paint(canvas, Offset(cx - ovTP.width / 2, cy - 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
