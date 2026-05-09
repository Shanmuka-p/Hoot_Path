import 'package:flutter/material.dart';
import 'learning_path_service.dart';
import 'day_task_screen.dart';

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
  final LearningPathService _service = LearningPathService();
  bool isLoading = true;
  bool isGenerating = false;
  String errorMessage = '';
  Map<String, dynamic>? pathData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.15).animate(_pulseController);
    _loadPath();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    setState(() {
      isLoading = true;
      isGenerating = false;
      errorMessage = '';
    });

    // Ping server first for a fast, clear error
    final reachable = await _service.isServerReachable();
    if (!reachable) {
      setState(() {
        errorMessage =
            'Cannot reach the Hoot server.\n\nPlease check your internet connection and try again.';
        isLoading = false;
      });
      return;
    }

    try {
      final checkRes = await _service.checkExistingPath(widget.userId);
      if (checkRes['exists'] == true) {
        setState(() {
          pathData = checkRes['path'] as Map<String, dynamic>?;
          isLoading = false;
        });
      } else {
        setState(() {
          isGenerating = true;
          isLoading = false;
        });
        final genRes =
            await _service.generatePath(widget.userId, widget.currentAccuracy);
        setState(() {
          pathData = genRes;
          isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
        isGenerating = false;
      });
    }
  }

  int _getCompletedCount() {
    if (pathData == null) return 0;
    final List days = pathData!['path'] ?? [];
    return days.where((d) => d['completed'] == true).length;
  }

  // Determine current active (today) day index
  int _getTodayIndex(List days) {
    for (int i = 0; i < days.length; i++) {
      if (days[i]['completed'] != true) return i;
    }
    return days.length; // all done
  }

  Color _skillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
        return const Color(0xFF4CAF50);
      case 'reading':
        return const Color(0xFF2196F3);
      case 'speaking':
        return const Color(0xFFFFBB00);
      case 'writing':
        return Colors.grey.shade400;
      default:
        return const Color(0xFF008738);
    }
  }

  IconData _skillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
        return Icons.headphones;
      case 'speaking':
        return Icons.mic;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit;
      default:
        return Icons.star;
    }
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
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF008738)),
      );
    }

    if (isGenerating) {
      return _buildGeneratingState();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (pathData == null || pathData!['path'] == null) {
      return const Center(child: Text('No path available.'));
    }

    return _buildPathUI();
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF008738),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF008738).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Building Your 30-Day\nAdaptive Path...',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Hoot AI Mentor is crafting a personalized roadmap based on your accuracy data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            const LinearProgressIndicator(
              color: Color(0xFF008738),
              backgroundColor: Color(0xFFE8F5ED),
            ),
          ],
        ),
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
            Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPath,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008738),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathUI() {
    final days = pathData!['path'] as List;
    final completedCount = _getCompletedCount();
    final todayIndex = _getTodayIndex(days);
    final totalDays = days.length;
    final progress = totalDays == 0 ? 0.0 : completedCount / totalDays;

    // Find active skill from today's focus
    final todayFocus = todayIndex < totalDays
        ? (days[todayIndex]['focus'] as String? ?? '')
        : 'Complete';

    return Column(
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ADAPTIVE PATH:\nMILESTONES',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5ED),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Color(0xFF008738), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF333333)),
                          children: [
                            TextSpan(text: 'A guided roadmap from your '),
                            TextSpan(
                              text: 'Hoot AI Mentor',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar
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
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008738)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Timeline list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isCompleted = day['completed'] == true;
              final isToday = index == todayIndex;
              final isLocked = !isCompleted && !isToday;
              final focus = day['focus'] as String? ?? '';
              final dayNum = day['day'] ?? (index + 1);
              final skillWord = focus.split(' ').first;

              return _buildDayTile(
                context,
                day: day,
                index: index,
                totalDays: totalDays,
                isCompleted: isCompleted,
                isToday: isToday,
                isLocked: isLocked,
                focus: focus,
                dayNum: dayNum,
                skillWord: skillWord,
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
          // Timeline column
          SizedBox(
            width: 56,
            child: Column(
              children: [
                // Top connector
                Container(
                  width: 2,
                  height: 16,
                  color: index == 0 ? Colors.transparent : const Color(0xFF008738).withOpacity(isCompleted || index <= _getTodayIndex(pathData!['path'] as List) ? 1 : 0.25),
                ),
                // Node
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isToday ? 32 : 28,
                  height: isToday ? 32 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFBB00).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 3,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : isToday
                            ? Icons.play_arrow
                            : Icons.lock,
                    size: isToday ? 18 : 14,
                    color: Colors.white,
                  ),
                ),
                // Bottom connector
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

          // Card
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
                  ).then((_) => _loadPath());
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
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFBB00).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : isCompleted
                          ? []
                          : [
                              const BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                ),
                child: Row(
                  children: [
                    // Skill icon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.shade200
                            : _skillColor(skillWord).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : _skillIcon(skillWord),
                        size: 20,
                        color: isLocked
                            ? Colors.grey.shade400
                            : _skillColor(skillWord),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFBB00),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('ACTIVE FOCUS',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                ),
                              Text(
                                'Day $dayNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? Colors.grey.shade400
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            focus,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? Colors.grey.shade400
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF008738),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Done',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      )
                    else if (isToday)
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFFFBB00), size: 24)
                    else if (isLocked)
                      Icon(Icons.lock_outline,
                          color: Colors.grey.shade400, size: 18),
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
