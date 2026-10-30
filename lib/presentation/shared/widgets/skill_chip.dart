import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Chip reutilizable para mostrar habilidades requeridas o seleccionadas.
class SkillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onSelected;
  final VoidCallback? onDelete;
  final Color? backgroundColor;
  final Color? textColor;

  const SkillChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.onDelete,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? kBlue
        : (backgroundColor ?? const Color(0xFFEFF3FA));
    final effectiveText = isSelected
        ? Colors.white
        : (textColor ?? kNavy);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: onDelete != null ? 10 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kBlue : kLine,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: effectiveText,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isSelected ? Colors.white70 : kMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
