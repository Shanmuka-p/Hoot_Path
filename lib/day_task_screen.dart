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

  Color _getIconColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return const Color(0xFF5B6CF9);
      case 'speaking': return const Color(0xFFFF6B6B);
      case 'reading': return const Color(0xFF26C6DA);
      case 'writing': return const Color(0xFFFFB300);
      default: return Colors.grey;
    }
  }

  IconData _getIconData(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return Icons.headphones;
      case 'speaking': return Icons.mic;
      case 'reading': return Icons.menu_book;
      case 'writing': return Icons.edit;
      default: return Icons.task;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final tasks = widget.dayData['tasks'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayData['day']} Tasks'),
        backgroundColor: const Color(0xFF008738),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                      final task = tasks[index];
                      final skill = task['skill'] as String? ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getIconColor(skill).withOpacity(0.2),
                            child: Icon(_getIconData(skill), color: _getIconColor(skill)),
                          ),
                          title: Text('${task['module']}'),
                          subtitle: Text('Skill: $skill | Difficulty: ${task['difficulty']}'),
                          trailing: Text('x${task['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: widget.isToday && !_isLoading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBB00),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _markComplete,
                child: const Text('Mark Day Complete', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          : null,
    );
  }
}
