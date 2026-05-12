import 'package:flutter/material.dart';
import 'learning_path_service.dart';

class DayTaskScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> dayData;
  final bool isToday;
  final VoidCallback onComplete;

  const DayTaskScreen({
    Key? key,
    required this.userId,
    required this.dayData,
    required this.isToday,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<DayTaskScreen> createState() => _DayTaskScreenState();
}

class _DayTaskScreenState extends State<DayTaskScreen> {
  final LearningPathService _service = LearningPathService();
  bool _isLoading = false;

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return const Color(0xFF008738);
      case 'speaking': return const Color(0xFFFFBB00);
      case 'reading': return const Color(0xFF72BD20);
      case 'writing': return const Color(0xFF2196F3);
      default: return Colors.grey;
    }
  }

  IconData _getSkillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return Icons.headphones;
      case 'speaking': return Icons.mic;
      case 'reading': return Icons.menu_book;
      case 'writing': return Icons.edit;
      default: return Icons.task;
    }
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'easy': return const Color(0xFF4CAF50);
      case 'medium': return const Color(0xFFFFA726);
      case 'hard': return const Color(0xFFEF5350);
      default: return Colors.grey;
    }
  }

  String _getComplexityLabel(String c) =>
      c.isEmpty ? 'Easy' : c[0].toUpperCase() + c.substring(1).toLowerCase();

  Future<void> _markComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to mark this day as complete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _service.completeDay(widget.userId, widget.dayData['day']);
      widget.onComplete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete day: $e')),
        );
      }
    }
  }

  Widget _buildModuleIcon(Map<String, dynamic> task) {
    final String moduleIcon = task['module_icon'] as String? ?? '';
    final String skill = task['skill'] as String? ?? '';
    final Color skillColor = _getSkillColor(skill);

    if (moduleIcon.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          moduleIcon,
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _iconFallback(skill, skillColor),
        ),
      );
    }
    return _iconFallback(skill, skillColor);
  }

  Widget _iconFallback(String skill, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_getSkillIcon(skill), color: color, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.dayData['tasks'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.dayData['day']} Tasks'),
        backgroundColor: const Color(0xFF008738),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFE8F5ED),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Focus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(widget.dayData['focus'] ?? '', style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index] is Map<String, dynamic>
                          ? tasks[index] as Map<String, dynamic>
                          : (tasks[index] as Map).cast<String, dynamic>();
                      final skill = task['skill'] as String? ?? '';
                      final moduleName = task['module'] as String? ?? 'Module';
                      final complexity = task['complexity'] as String? ?? task['difficulty'] as String? ?? 'easy';
                      final courseName = task['course_name'] as String? ?? '';
                      final skillColor = _getSkillColor(skill);
                      final complexityColor = _getComplexityColor(complexity);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Module icon (from API URL or fallback)
                                _buildModuleIcon(task),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        moduleName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // Skill badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: skillColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              skill,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: skillColor),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Complexity badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: complexityColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getComplexityLabel(complexity),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: complexityColor),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'x${task['count']}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (courseName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                courseName,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.isToday
              ? _isLoading
                  ? const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF008738),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBB00),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _markComplete,
                      child: const Text('Mark Day Complete', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
              : const SizedBox.shrink(),
        ),
    );
  }
}
