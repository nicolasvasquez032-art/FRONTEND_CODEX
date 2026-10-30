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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.29),
          boxShadow: [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(size * 0.10),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
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
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Talent',
                    style: TextStyle(
                      fontSize: iconSize * 0.58,
                      fontWeight: FontWeight.w900,
                      color: kNavy,
                      letterSpacing: -0.3,
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                  ),
                  TextSpan(
                    text: 'Match',
                    style: TextStyle(
                      fontSize: iconSize * 0.58,
                      fontWeight: FontWeight.w900,
                      color: kBlue,
                      letterSpacing: -0.3,
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
