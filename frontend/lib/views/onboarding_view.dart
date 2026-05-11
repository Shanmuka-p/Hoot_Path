// ─── lib/views/onboarding_view.dart ───────────────────────────────────────────
//  View layer — Onboarding swiper screen.
//  Import updated to reference analytics_view.dart under the views/ folder.
//  No logic changed — purely a re-path.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:hoot_path/views/analytics_view.dart';

// ─── Color Constants ──────────────────────────────────────────────────────────
const kGreen = Color(0xFF2E7D32);
const kGrey  = Color(0xFFAAAAAA);

// ─── Onboarding Screen ────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> _images = const [
    'assets/onboarding/1_screen.png',
    'assets/onboarding/2_screen.png',
    'assets/onboarding/3_screen.png',
  ];

  void _next() {
    if (_currentPage < _images.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // ── Navigate to AnalyticsScreen, removing onboarding from back stack ──
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen swiping images ────────────────────────────────────
          PageView.builder(
            controller: _controller,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return Image.asset(
                _images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
              );
            },
          ),

          // ── Back button ───────────────────────────────────────────────────
          Positioned(
            top: 40, left: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              color: Colors.black,
            ),
          ),

          // ── Bottom navigation overlay ─────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip
                    GestureDetector(
                      onTap: _skip,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Skip', style: TextStyle(color: kGreen, fontSize: 17, fontWeight: FontWeight.w500)),
                      ),
                    ),

                    // Dot indicators
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_images.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 30 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: isActive ? kGreen : kGrey,
                          ),
                        );
                      }),
                    ),

                    // Next / Done
                    GestureDetector(
                      onTap: _next,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _currentPage == _images.length - 1 ? 'Done' : 'Next',
                          style: const TextStyle(color: kGreen, fontSize: 17, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
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
