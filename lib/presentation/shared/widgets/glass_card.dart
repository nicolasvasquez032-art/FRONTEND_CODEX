import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Contenedor Glassmorphism de alto rendimiento optimizado para dispositivos móviles.
///
/// Utiliza un gradiente translúcido de doble capa, borde especular y sombra suave
/// que emula el efecto de vidrio esmerilado sin forzar recreación de capas fuera
/// de pantalla (offscreen buffers) en listas desplazables (evitando caídas de FPS).
///
/// Para elementos estacionarios (AppBars, BottomNav, Modales), se puede habilitar
/// [useBackdropFilter: true] con un kernel de desenfoque ligero y controlado (sigma 8).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final dynamic borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool useBackdropFilter;
  final double blurSigma;
  final Color? tintColor;
  final double opacity;
  final Border? customBorder;
  final List<BoxShadow>? customShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 22.0,
    this.width,
    this.height,
    this.onTap,
    this.useBackdropFilter = false,
    this.blurSigma = 8.0,
    this.tintColor,
    this.opacity = 0.75,
    this.customBorder,
    this.customShadows,
  });

  BorderRadius get _effectiveRadius {
    if (borderRadius is BorderRadius) return borderRadius as BorderRadius;
    if (borderRadius is num) return BorderRadius.circular((borderRadius as num).toDouble());
    return BorderRadius.circular(22);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = tintColor ?? Colors.white;

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withValues(alpha: opacity),
          baseColor.withValues(alpha: (opacity * 0.7).clamp(0.0, 1.0)),
        ],
      ),
      borderRadius: _effectiveRadius,
      border: customBorder ??
          Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1.2,
          ),
      boxShadow: customShadows ??
          [
            BoxShadow(
              color: kNavy.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 1,
              offset: const Offset(-0.5, -0.5),
            ),
          ],
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (useBackdropFilter) {
      content = ClipRRect(
        borderRadius: _effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: _effectiveRadius,
        child: InkWell(
          borderRadius: _effectiveRadius,
          onTap: onTap,
          splashColor: kBlue.withValues(alpha: 0.08),
          highlightColor: kBlue.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
