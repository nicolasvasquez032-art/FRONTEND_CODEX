import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import 'gradient_button.dart';

enum StatusType { success, error, info }

/// Modal de estado reutilizable para confirmaciones, errores y éxitos.
class StatusDialog extends StatelessWidget {
  final String title;
  final String message;
  final StatusType type;
  final String buttonText;
  final VoidCallback? onConfirm;

  const StatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = StatusType.success,
    this.buttonText = 'Entendido',
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    StatusType type = StatusType.success,
    String buttonText = 'Entendido',
    VoidCallback? onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatusDialog(
        title: title,
        message: message,
        type: type,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case StatusType.success:
        iconColor = kGreen;
        iconData = Icons.check_rounded;
        break;
      case StatusType.error:
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.error_outline_rounded;
        break;
      case StatusType.info:
        iconColor = kBlue;
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          ZoomIn(
            duration: const Duration(milliseconds: 350),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          FadeInDown(
            from: 10,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: kMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            text: buttonText,
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
          ),
        ],
      ),
    );
  }
}
