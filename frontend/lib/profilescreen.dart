import 'package:flutter/material.dart';

import 'package:hoot_path/services/auth_service.dart';
import 'package:hoot_path/login_screen.dart';

const kProfileGreen = Color(0xFF28A745);
const kMenuBgColor = Color(0xFFEAF5D4);
const kAvatarBgColor = Color(0xFFFDE4B5);
const kAvatarIconColor = Color(0xFFFF8C00);

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({
    super.key,
    this.userData,
  });

  Map<String, dynamic> get _data {
    if (userData != null && userData!.isNotEmpty) return userData!;
    if (AuthSession.instance.userData.isNotEmpty) return AuthSession.instance.userData;
    
    // Fallback default
    return const {
      "first_name": "Guest User",
      "gender": "male",
      "mobile": "N/A",
      "email": "N/A",
      "roll_no": "N/A"
    };
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        // Adding a thick border to match the reference image exactly
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color.fromARGB(255, 255, 255, 255),),
        ),
        child: Column(
          children: [
            // Header
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                children: [
                  // Green wavy background
                  ClipPath(
                    clipper: _WavyClipper(),
                    child: Container(
                      height: 240,
                      color: const Color.fromARGB(255, 40, 167, 69),
                    ),
                  ),
                  // Wavy black stroke
                  CustomPaint(
                    size: const Size(double.infinity, 240),
                    painter: _WavyBorderPainter(),
                  ),
                  // "TH" Text
                  
                  // Profile Info
                  Positioned(
                    top: 70,
                    left: 30,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Icon
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                            image: (_data['profile_pic'] != null && _data['profile_pic'].toString().isNotEmpty && !_data['profile_pic'].toString().endsWith('dummy.png'))
                                ? DecorationImage(
                                    image: NetworkImage(_data['profile_pic']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_data['profile_pic'] == null || _data['profile_pic'].toString().isEmpty || _data['profile_pic'].toString().endsWith('dummy.png'))
                              ? Icon(
                                  (_data['gender']?.toString().toLowerCase() == 'female') ? Icons.face_3 : Icons.person,
                                  color: const Color.fromARGB(255, 248, 164, 85),
                                  size: 60,
                                )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        // Text Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _data['first_name'] ?? 'N/A',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _data['roll_no'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _data['email'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+91 ${_data['mobile'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Back button (optional but good for UX)
                  Positioned(
                    top: 30,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Color.fromARGB(255, 0, 0, 0),size: 30,),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem('Privacy Policy',Icons.privacy_tip_outlined),
                  const SizedBox(height: 16),
                  _buildMenuItem('Help Centre',Icons.help_outline),
                  const SizedBox(height: 16),
                  _buildMenuItem('About App',Icons.info_outline),
                  const SizedBox(height: 16),
                  _buildMenuItem('Change Password',Icons.key),
                  const SizedBox(height: 16),
                  _buildMenuItem('Logout',Icons.logout, onTap: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title,IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(162, 183, 232, 181),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
        children: [
          Icon(icon,color: title=='Logout'?const Color.fromARGB(255, 255, 0, 0):Colors.black,),
          SizedBox(width: 10),
          Text(
            title, 
            style:  TextStyle(
              color: title=='Logout'?const Color.fromARGB(255, 255, 0, 0):Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ));
  }
}

class _WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    
    // First curve
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 25);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    // Second curve
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 50);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WavyBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0; // Thick black stroke
      
    var path = Path();
    path.moveTo(0, size.height - 30);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 25);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 50);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
