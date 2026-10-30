import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/locale_provider.dart';

/// Selector de idioma compacto y limpio (ES / EN) idéntico al de la pantalla de inicio.
/// Sin banderas para maximizar el espacio en la barra superior.
class LanguageSwitchButton extends StatelessWidget {
  final bool compact;

  const LanguageSwitchButton({super.key, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isEs = localeProvider.isSpanish;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageSegmentItem(
            label: 'ES',
            selected: isEs,
            onTap: () {
              if (!isEs) {
                HapticFeedback.selectionClick();
                localeProvider.setLocale(const Locale('es'));
              }
            },
          ),
          _LanguageSegmentItem(
            label: 'EN',
            selected: !isEs,
            onTap: () {
              if (isEs) {
                HapticFeedback.selectionClick();
                localeProvider.setLocale(const Locale('en'));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageSegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageSegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? kBlue : const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

