import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/constants/app_colors.dart';
import 'package:talentmatch/presentation/shared/providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel(); // Stop on last page
      }
    });
  }

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Encuentra tu talento ideal',
      'description': 'Conectamos a las mejores empresas con los candidatos más capacitados mediante IA.',
      'lottie': 'assets/lottie/anim1.json',
      'color': kBlue,
    },
    {
      'title': 'Match Semántico de IA',
      'description': 'Nuestro algoritmo analiza las habilidades, no solo palabras clave. Olvídate de leer CVs aburridos.',
      'lottie': 'assets/lottie/anim2.json',
      'color': kGreen,
    },
    {
      'title': 'Chatea al Instante',
      'description': '¿Encontraste a alguien que te gusta? Inicia un chat en tiempo real y pacta entrevistas.',
      'lottie': 'assets/lottie/anim3.json',
      'color': kPurple,
    },
  ];

  final List<Color> _bgColors = [
    const Color(0xFFEBF2FA), // Tono súper sutil azul
    const Color(0xFFE9F7F1), // Tono súper sutil verde
    const Color(0xFFF2ECFC), // Tono súper sutil morado
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: _bgColors[_currentIndex],
        child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = index);
              _startAutoPlay();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = _pageController.page! - index;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lottie Animation con Efecto Parallax
                        Transform.translate(
                          offset: Offset(pageOffset * 200, 0),
                          child: Container(
                            height: 300,
                            width: 300, // Explicit width for the circle
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (page['color'] as Color).withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  padding: const EdgeInsets.all(20),
                                  alignment: Alignment.center,
                                  child: Lottie.asset(
                                    page['lottie'] as String,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error_outline, size: 50, color: kNavy),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 50),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        page['title'] as String,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: kNavy,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          page['description'] as String,
                          style: TextStyle(
                            fontSize: 17,
                            color: kNavy.withValues(alpha: 0.6),
                            height: 1.6,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
                },
              );
            },
          ),
          
          // Bottom controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 600),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Smooth Page Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: kBlue,
                    dotColor: kLine,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 8,
                  ),
                ),
                
                // Next/Done button
                GestureDetector(
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentIndex == _pages.length - 1 ? 140 : 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: kButtonGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _currentIndex == _pages.length - 1
                        ? const Text(
                            'Comenzar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
            ),
          ),
          
          // Skip button
          if (_currentIndex < _pages.length - 1)
            Positioned(
              top: 60,
              right: 24,
              child: FadeInDown(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 600),
                child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<AuthProvider>().completeOnboarding();
                },
                child: const Text(
                  'Saltar',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
