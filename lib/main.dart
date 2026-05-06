import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hoot_path/onboarding_screen.dart';

void main() {
  if(kIsWeb){
    runApp(DevicePreview(builder: (context) => HootApp(),));
  }else{
    runApp(const HootApp());
  }
}

class HootApp extends StatelessWidget {
  const HootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hoot App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HootHomePage(),
    );
  }
}

class HootHomePage extends StatelessWidget {
  const HootHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hoot Logo Mockup
              Row(
                children: [
                  Text(
                    'H',
                    style: TextStyle(
                      color: Color(0xFF007B3E),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.hearing,
                    color: Color(0xFFF4B41A),
                  ), // Mock icon for OO
                  Text(
                    'T',
                    style: TextStyle(
                      color: Color(0xFF007B3E),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007B3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Text(
                      '490',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: const [
                  SkillCard(title: 'Listening', icon: Icons.volume_up_outlined),
                  SkillCard(title: 'Speaking', icon: Icons.mic_none),
                  SkillCard(title: 'Reading', icon: Icons.menu_book_outlined),
                  SkillCard(
                    title: 'Writing',
                    icon: Icons.keyboard_outlined,
                  ), // Typewriter alternative
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: const [
                  Expanded(child: ActionButton(title: 'HOOT EDGE')),
                  SizedBox(width: 16),
                  Expanded(child: ActionButton(title: 'HOOT TEST')),
                ],
              ),
              const SizedBox(height: 16),

              // [NEW] Hoot AI Mentor Card
              const HootAIMentorCard(),
              const SizedBox(height: 24),

              // Leader Board
              const Text(
                'Leader Board',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const LeaderBoardTable(),
              const SizedBox(height: 24),

              // Hoot Tips
              const Text(
                'Hoot Tips',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const HootTipsCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF007B3E),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.hearing), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom Widgets
// ----------------------------------------------------

class SkillCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const SkillCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7E5C8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: WavePainter(color: const Color(0xFFEAF5E5)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF007B3E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ActionButton extends StatelessWidget {
  final String title;
  const ActionButton({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7E5C8), width: 1.5),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1B3B59),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HootAIMentorCard extends StatelessWidget {
  const HootAIMentorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>{
        Navigator.push(context, MaterialPageRoute(builder:(context) => OnboardingScreen(),))
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black,blurRadius: 3,offset: Offset(0, 4))],
          color: const Color(0xFFEAF5E5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.smart_toy, color: Color(0xFF007B3E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HOOT AI MENTOR',
                        style: TextStyle(
                          color: Color(0xFF007B3E),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
      
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value:
                            0.75, // You can adjust this to match streak progression
                        strokeWidth: 8,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF67B521),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department,
                          color: Color(0xFF67B521),
                          size: 24,
                        ),
                        Text(
                          '7',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3B59),
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5A7184),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderBoardTable extends StatelessWidget {
  const LeaderBoardTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF007B3E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Accuracy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Attempts',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          _buildTableRow('AMURI CHARISHMA', '59%', '1594'),
          const Divider(height: 1, thickness: 1),
          _buildTableRow('PUDI SUBHASH', '48%', '1537'),
          const Divider(height: 1, thickness: 1),
          _buildTableRow('MUDI GURU', '63%', '1239'),
          const Divider(height: 1, thickness: 1),
          _buildTableRow('ADA SUDEEP', '56%', '1238'),
          const Divider(height: 1, thickness: 1),
          _buildTableRow('URI DHARANI', '54%', '1209'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String name, String accuracy, String attempts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text(accuracy, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              attempts,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class HootTipsCard extends StatelessWidget {
  const HootTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF7FBF6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF007B3E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Text(
              'Speaking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _TipBullet(text: 'Speak slowly and clearly'),
                      SizedBox(height: 8),
                      _TipBullet(
                        text: 'Use short sentences to build confidence',
                      ),
                    ],
                  ),
                ),
                // Decorative icon in bottom right (mocked)
                const Icon(Icons.mic, size: 40, color: Color(0xFFC7E5C8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBullet extends StatelessWidget {
  final String text;
  const _TipBullet({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0, right: 8.0),
          child: Icon(Icons.circle, size: 6, color: Colors.black87),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
