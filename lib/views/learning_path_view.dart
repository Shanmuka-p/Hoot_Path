// ─── lib/views/learning_path_view.dart ────────────────────────────────────────
//  View layer — pure UI for the 30-day Learning Path screen.
//  All business logic delegated to LearningPathController.
//  Imports updated to use MVC-organized lib/services/ and lib/controllers/.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoot_path/controllers/learning_path_controller.dart';
import 'package:hoot_path/views/day_task_view.dart';

class LearningPathScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentAccuracy;

  const LearningPathScreen({
    Key? key,
    required this.userId,
    required this.currentAccuracy,
  }) : super(key: key);

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late final LearningPathController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _loadingStepIndex = 0;
  late Timer _loadingTimer;
  List<String> _loadingSteps = [];

  @override
  void initState() {
    super.initState();

    _controller = LearningPathController(
      userId: widget.userId,
      currentAccuracy: widget.currentAccuracy,
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadingSteps = _controller.buildLoadingSteps();

    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && (_controller.isLoading || _controller.isGenerating)) {
        setState(() {
          _loadingStepIndex = (_loadingStepIndex + 1) % _loadingSteps.length;
        });
      }
    });

    _controller.loadPath();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _loadingTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        title: const Text('AI Mentor Path'),
        backgroundColor: const Color(0xFF008738),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading)    return _buildCheckingState();
    if (_controller.isGenerating) return _buildGeneratingState();
    if (_controller.errorMessage.isNotEmpty) return _buildErrorState();
    if (_controller.pathData == null || _controller.pathData!['path'] == null) {
      return const Center(child: Text('No path available.'));
    }
    return _buildPathUI();
  }

  Widget _buildCheckingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF008738)),
          const SizedBox(height: 20),
          Text(
            'Checking your learning history...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    final acc    = widget.currentAccuracy;
    final skills = [
      {'label': 'Listening', 'key': 'listening', 'icon': Icons.headphones},
      {'label': 'Speaking',  'key': 'speaking',  'icon': Icons.mic},
      {'label': 'Reading',   'key': 'reading',   'icon': Icons.menu_book},
      {'label': 'Writing',   'key': 'writing',   'icon': Icons.edit},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF008738),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF008738).withOpacity(0.3), blurRadius: 24, spreadRadius: 8)],
              ),
              child: const Icon(Icons.route, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Designing Your Path',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your real accuracy — here\'s what we found:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR SKILL CONDITIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF008738), letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                ...skills.map((s) {
                  final pct    = (acc[s['key']] ?? 0).toDouble();
                  final tier   = _controller.tierLabel(pct);
                  final tColor = _controller.tierColor(pct);
                  final sColor = _controller.skillColor(s['label'] as String);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(s['icon'] as IconData, size: 16, color: sColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(s['label'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A1A))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sColor)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: tColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(tier, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100.0,
                            backgroundColor: sColor.withOpacity(0.12),
                            color: sColor,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              _loadingSteps.isNotEmpty
                  ? _loadingSteps[_loadingStepIndex % _loadingSteps.length]
                  : 'Generating your path...',
              key: ValueKey<int>(_loadingStepIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF555555), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                color: Color(0xFF008738),
                backgroundColor: Color(0xFFE8F5ED),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_connected_no_internet_4_rounded, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _controller.errorMessage,
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _controller.loadPath,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008738),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathUI() {
    final days           = _controller.pathData!['path'] as List;
    final completedCount = _controller.getCompletedCount();
    final todayIndex     = _controller.getTodayIndex(days);
    final totalDays      = days.length;
    final progress       = totalDays == 0 ? 0.0 : completedCount / totalDays;
    final todayFocus     = todayIndex < totalDays
        ? (days[todayIndex]['focus'] as String? ?? '')
        : 'Complete';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ADAPTIVE PATH:\nMILESTONES',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFE8F5ED), borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF008738), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16)),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Color(0xFF333333)),
                          children: [
                            TextSpan(text: 'A guided roadmap from your '),
                            TextSpan(text: 'Hoot AI Mentor', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE8F5ED),
                        color: const Color(0xFF72BD20),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$completedCount/$totalDays days',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF008738)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day         = days[index];
              final isCompleted = day['completed'] == true;
              final isToday     = index == todayIndex;
              final isLocked    = !isCompleted && !isToday;
              final focus       = day['focus'] as String? ?? '';
              final dayNum      = day['day'] ?? (index + 1);
              final skillWord   = focus.split(' ').first;

              return _buildDayTile(
                context,
                day: day, index: index, totalDays: totalDays,
                isCompleted: isCompleted, isToday: isToday, isLocked: isLocked,
                focus: focus, dayNum: dayNum, skillWord: skillWord,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayTile(
    BuildContext context, {
    required Map<String, dynamic> day,
    required int index,
    required int totalDays,
    required bool isCompleted,
    required bool isToday,
    required bool isLocked,
    required String focus,
    required dynamic dayNum,
    required String skillWord,
  }) {
    final Color nodeColor = isCompleted
        ? const Color(0xFF008738)
        : isToday
            ? const Color(0xFFFFBB00)
            : Colors.grey.shade300;

    final Color cardBg = isCompleted
        ? const Color(0xFFE8F5ED)
        : isToday
            ? const Color(0xFFFFF9E6)
            : Colors.white;

    final Color borderColor = isCompleted
        ? const Color(0xFF008738)
        : isToday
            ? const Color(0xFFFFBB00)
            : Colors.grey.shade200;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: 2, height: 16,
                  color: index == 0 ? Colors.transparent : const Color(0xFF008738).withOpacity(isCompleted || index <= _controller.getTodayIndex(_controller.pathData!['path'] as List) ? 1 : 0.25),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isToday ? 32 : 28,
                  height: isToday ? 32 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    boxShadow: isToday
                        ? [BoxShadow(color: const Color(0xFFFFBB00).withOpacity(0.4), blurRadius: 12, spreadRadius: 3)]
                        : [],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : isToday ? Icons.play_arrow : Icons.lock,
                    size: isToday ? 18 : 14,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: index == totalDays - 1
                        ? Colors.transparent
                        : const Color(0xFF008738).withOpacity(isCompleted ? 1 : 0.2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isLocked) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayTaskScreen(
                        userId: widget.userId,
                        dayData: day,
                        isToday: isToday,
                        onComplete: () {},
                      ),
                    ),
                  ).then((_) => _controller.loadPath());
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 6, bottom: 6, right: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: borderColor, width: isToday ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isToday
                      ? [BoxShadow(color: const Color(0xFFFFBB00).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                      : isCompleted
                          ? []
                          : [const BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey.shade200 : _controller.skillColor(skillWord).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : _controller.skillIcon(skillWord),
                        size: 20,
                        color: isLocked ? Colors.grey.shade400 : _controller.skillColor(skillWord),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFFBB00), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('ACTIVE FOCUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              Text(
                                'Day $dayNum',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLocked ? Colors.grey.shade400 : const Color(0xFF666666)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            focus,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey.shade400 : const Color(0xFF1A1A1A)),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF008738), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else if (isToday)
                      const Icon(Icons.chevron_right, color: Color(0xFFFFBB00), size: 24)
                    else if (isLocked)
                      Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
