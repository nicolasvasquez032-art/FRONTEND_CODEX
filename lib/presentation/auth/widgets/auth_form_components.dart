import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';

/// Pintor orbital decorativo para el fondo del registro.
class OrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1558D6).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(size.width * 0.42, size.height * 0.45);
    canvas.scale(1.0, 0.38);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.92,
        height: size.height * 0.92,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tarjeta de selección de rol (Candidato vs Empresa).
class RoleSelectorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const RoleSelectorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kBlue : kLine,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? kBlue.withValues(alpha: 0.12) : kLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: selected ? kBlue : kMuted, size: 18),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: selected ? kBlue : kLine, width: 2),
                    color: selected ? kBlue : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 10, color: kWhite)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? kNavy : kText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta superior para campos de formulario.
class FormFieldLabel extends StatelessWidget {
  final String text;
  const FormFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kNavy,
        ),
      );
}

/// Campo de entrada de texto estandarizado para formularios de autenticación.
class FormTextInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const FormTextInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted, fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: kMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7EBF2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
      ),
    );
  }
}

/// Caja indicadora de requisitos y fortaleza de contraseña en tiempo real.
class PasswordRequirementsBox extends StatelessWidget {
  final TextEditingController controller;
  const PasswordRequirementsBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final pwd = value.text;
        final eval = Validators.evaluatePassword(pwd);

        final Color barColor = pwd.isEmpty
            ? Colors.grey.shade300
            : switch (eval.strength) {
                PasswordStrength.weak => Colors.redAccent,
                PasswordStrength.medium => Colors.orangeAccent,
                PasswordStrength.strong => const Color(0xFF10B981),
              };

        final String strengthLabel = pwd.isEmpty
            ? ''
            : switch (eval.strength) {
                PasswordStrength.weak => 'Seguridad: Débil',
                PasswordStrength.medium => 'Seguridad: Media',
                PasswordStrength.strong => 'Seguridad: Fuerte',
              };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pwd.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strengthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                    Text(
                      '${eval.metCount}/4 requisitos',
                      style: const TextStyle(fontSize: 10, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: eval.fraction,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'La contraseña debe tener:',
                style: TextStyle(
                    fontSize: 11, color: kNavy, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _RequirementRow(
                  text: 'Mínimo 8 caracteres', met: eval.hasMinLength),
              _RequirementRow(
                  text: 'Una mayúscula y una minúscula',
                  met: eval.hasUpperAndLower),
              _RequirementRow(
                  text: 'Al menos un número', met: eval.hasNumber),
              _RequirementRow(
                  text: 'Un carácter especial', met: eval.hasSpecialChar),
            ],
          ),
        );
      },
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String text;
  final bool met;
  const _RequirementRow({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: met ? kGreen : kMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: met ? kGreen : kMuted,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
