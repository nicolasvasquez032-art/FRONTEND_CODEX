import 'package:flutter/material.dart';
import 'package:talentmatch/core/constants/app_colors.dart';

/// Logo cuadrado con gradiente cyan→blue y letra inicial.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.29),
          gradient: kLogoGradient,
        ),
        child: Text(
          'T',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.52,
          ),
        ),
      );
}

/// Logotipo completo: ícono + texto "TalentMatch"
class BrandFull extends StatelessWidget {
  final double iconSize;
  const BrandFull({super.key, this.iconSize = 34});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(size: iconSize),
          const SizedBox(width: 9),
          Text(
            'TalentMatch',
            style: TextStyle(
              fontSize: iconSize * 0.56,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
          ),
        ],
      );
}
