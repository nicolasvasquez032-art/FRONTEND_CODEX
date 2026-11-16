import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Paleta de colores oficial de TalentMatch
// Fuente: wireframe talentmatch_wireframe_movil.html
// ──────────────────────────────────────────────

const Color kBlue   = Color(0xFF1558D6); // botones, íconos activos
const Color kNavy   = Color(0xFF10265F); // títulos, topbar
const Color kCyan   = Color(0xFF08C8DF); // gradiente del logo
const Color kGreen  = Color(0xFF18A477); // éxito, tags positivos
const Color kPurple = Color(0xFF6546C7); // estado "entrevista"

const Color kBg     = Color(0xFFF5F7FB); // fondo general
const Color kText   = Color(0xFF14213D); // texto principal
const Color kMuted  = Color(0xFF758095); // texto secundario/hint
const Color kLine   = Color(0xFFE7EBF2); // bordes y divisores
const Color kWhite  = Colors.white;

// Badge de compatibilidad IA
const Color kMatchBg   = Color(0xFFE8F8EF);
const Color kMatchText = Color(0xFF15804D);

// Estados de postulación
const Color kStatusReview    = Color(0xFF245BC8); // postulado
const Color kStatusInterview = Color(0xFF6546C7); // entrevista
const Color kStatusRejected  = Color(0xFF9099A8); // rechazado
const Color kStatusHired     = Color(0xFF15804D); // contratado

// ──────────────────────────────────────────────
// Paleta Premium / Pro (Gold & Obsidian Edition)
// ──────────────────────────────────────────────
const Color kGold         = Color(0xFFD97706); // Oro ámbar primario
const Color kGoldLight    = Color(0xFFF59E0B); // Oro brillante
const Color kGoldDark     = Color(0xFF92400E); // Oro profundo
const Color kGoldSurface  = Color(0xFFFFFBEB); // Fondo sutil oro
const Color kGoldBorder   = Color(0xFFFDE68A); // Borde dorado
const Color kObsidian     = Color(0xFF0F172A); // Fondo obsidiana / noche profunda

const LinearGradient kGoldGradient = LinearGradient(
  colors: [kGoldLight, kGold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kPremiumBannerGradient = LinearGradient(
  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF78350F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kPremiumGoldButtonGradient = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Gradientes reutilizables
const LinearGradient kLogoGradient = LinearGradient(
  colors: [kCyan, kBlue],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kBannerGradient = LinearGradient(
  colors: [kNavy, kBlue],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kButtonGradient = LinearGradient(
  colors: [Color(0xFF1667DC), kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
