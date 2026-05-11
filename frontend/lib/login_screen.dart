import 'package:flutter/material.dart';
import 'package:hoot_path/main.dart';
import 'package:hoot_path/services/auth_service.dart';


// ─── Colors ───────────────────────────────────────────────────────────────────
const kGreen      = Color(0xFF008738);
const kYellow     = Color(0xFFFFBB00);
const kBlack      = Color(0xFF1A1A1A);
const kTextGrey   = Color(0xFF9E9E9E);
const kBorderGrey = Color(0xFFE0E0E0);
const kWhite      = Colors.white;

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword     = true;
  bool _isLoading           = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: kGreen,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email   : email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HootHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kGreen,
      body: Column(
        children: [
          // ── Green top section ───────────────────────────────────────────────
          SizedBox(height: screenH * 0.22),

          // ── White card (bottom sheet style) ────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),

                    // ── Welcome text ──────────────────────────────────────────
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: kTextGrey,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── HOOT Logo ─────────────────────────────────────────────
                    SizedBox(
                      height: 72,
                      child: CustomPaint(
                        painter: _HootLogoPainter(),
                        size: const Size(240, 72),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Email field ───────────────────────────────────────────
                    _InputField(
                      controller: _emailController,
                      hint: 'Email',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    // ── Password field ────────────────────────────────────────
                    _InputField(
                      controller: _passwordController,
                      hint: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kTextGrey,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Forgot Password ───────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: kBlack,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Login Button ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: kWhite,
                          disabledBackgroundColor: kGreen.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: kWhite,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // ── Powered By ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Powered By  ',
                          style: TextStyle(fontSize: 12, color: kTextGrey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF72BD20), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'T',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF72BD20),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'TECHNICAL HUB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF72BD20),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
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

// ─── Input Field Widget ───────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey, width: 1.2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(prefixIcon, color: kBlack, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                color: kBlack,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(color: kTextGrey, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) ...[
            suffixIcon!,
            const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

// ─── HOOT Logo Painter ────────────────────────────────────────────────────────
class _HootLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = kGreen
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = kYellow
      ..style = PaintingStyle.fill;

    // We'll draw "HOOT" text-style using paths
    // H
    _drawText(canvas, 'H', 0, size.height, kGreen, 68);
    // OO (with owl eyes effect)
    _drawText(canvas, 'O', 52, size.height, kGreen, 68);
    // inner circle yellow for first O
    canvas.drawCircle(Offset(82, size.height / 2 - 4), 10, yellowPaint);
    canvas.drawCircle(Offset(82, size.height / 2 - 4), 5,
        Paint()..color = kGreen..style = PaintingStyle.fill);

    _drawText(canvas, 'O', 104, size.height, kGreen, 68);
    // inner circle yellow for second O
    canvas.drawCircle(Offset(134, size.height / 2 - 4), 10, yellowPaint);
    canvas.drawCircle(Offset(134, size.height / 2 - 4), 5,
        Paint()..color = kGreen..style = PaintingStyle.fill);

    // T
    _drawText(canvas, 'T', 156, size.height, kGreen, 68);

    // Small speech bubble / signal arcs between the O's
    final arcPaint = Paint()
      ..color = kGreen.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.88), width: 90, height: 16),
      arcPaint,
    );
  }

  void _drawText(Canvas canvas, String char, double x, double baseY,
      Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, baseY - fontSize * 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
