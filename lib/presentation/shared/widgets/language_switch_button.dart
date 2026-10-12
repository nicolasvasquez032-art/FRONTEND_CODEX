import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/locale_provider.dart';
import 'bouncy_tap.dart';

/// Selector interactivo premium ultra-optimizado con cápsula deslizante.
/// Utiliza [RepaintBoundary] para aislar repintados y garantizar 60/120 FPS sin lag.
class LanguageSwitchButton extends StatelessWidget {
  final bool compact;

  const LanguageSwitchButton({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isEs = localeProvider.isSpanish;

    const double height = 36;
    const double width = 106;
    const double pillWidth = 49;
    const double pillHeight = 28;

    return RepaintBoundary(
      child: BouncyTap(
        scaleFactor: 0.95,
        duration: const Duration(milliseconds: 100),
        onPressed: () {
          HapticFeedback.selectionClick();
          localeProvider.toggleLocale();
        },
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: kNavy.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cápsula activa animada ultra-rápida (180ms)
              AnimatedAlign(
                alignment: isEs ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOutCubic,
                child: Container(
                  width: pillWidth,
                  height: pillHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kBlue.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kBlue.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Opciones ES y EN con banderas y tipografía refinada
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isEs) {
                          HapticFeedback.selectionClick();
                          localeProvider.setLocale(const Locale('es'));
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isEs ? FontWeight.w800 : FontWeight.w600,
                            color: isEs ? kBlue : const Color(0xFF64748B),
                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇪🇸', style: TextStyle(fontSize: 12.5)),
                              SizedBox(width: 3),
                              Text('ES'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isEs) {
                          HapticFeedback.selectionClick();
                          localeProvider.setLocale(const Locale('en'));
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: !isEs ? FontWeight.w800 : FontWeight.w600,
                            color: !isEs ? kBlue : const Color(0xFF64748B),
                            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇺🇸', style: TextStyle(fontSize: 12.5)),
                              SizedBox(width: 3),
                              Text('EN'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
