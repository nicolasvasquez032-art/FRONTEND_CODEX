import 'package:flutter/material.dart';

const Color _kBlue = Color(0xFF2563EB);

/// Selector de idioma segmentado (ES / EN) estilo cápsula limpia Figma.
class AuthLanguagePill extends StatelessWidget {
  final bool isEs;
  final VoidCallback onSelectEs;
  final VoidCallback onSelectEn;

  const AuthLanguagePill({
    super.key,
    required this.isEs,
    required this.onSelectEs,
    required this.onSelectEn,
  });

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageSegmentItem(
            label: 'ES',
            selected: isEs,
            onTap: onSelectEs,
          ),
          _LanguageSegmentItem(
            label: 'EN',
            selected: !isEs,
            onTap: onSelectEn,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? _kBlue : const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
