import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Datos de demostración — se reemplazarán con API real en Sprint F-2
const _demoJobs = [
  _DemoJob('Desarrollador Junior', 'TechSolutions', 'Fusagasugá', 'Remoto', 'Hace 1 hora', 94),
  _DemoJob('Analista de Datos', 'DataPro', 'Fusagasugá', 'Híbrido', 'Hace 3 horas', 89),
  _DemoJob('Practicante de Marketing', 'Impulsa S.A.S.', 'Fusagasugá', 'Presencial', 'Hace 5 horas', null),
];

class HomeScreen extends StatelessWidget {
  final VoidCallback onExplore;
  const HomeScreen({super.key, required this.onExplore});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(17, 20, 17, 24),
        children: [
          // ── Saludo ──
          const Text('Buenos días 👋', style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(
            'Oportunidades\npara ti',
            style: TextStyle(fontSize: 27, height: 1.1, fontWeight: FontWeight.w800, color: kNavy),
          ),
          const SizedBox(height: 18),

          // ── Búsqueda (navega a explorar) ──
          GestureDetector(
            onTap: onExplore,
            child: Container(
              height: 47,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  const Icon(Icons.search, color: kMuted, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(AppStrings.searchHint, style: TextStyle(color: kMuted, fontSize: 13)),
                  ),
                  Container(
                    width: 35, height: 35,
                    decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.search, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Sección Recomendadas ──
          _sectionHead(AppStrings.recommended, AppStrings.seeAll, onExplore),
          ..._demoJobs.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JobCard(job: j),
              )),

          // ── Banner IA ──
          const SizedBox(height: 6),
          _AiBanner(),
          const SizedBox(height: 4),

          // ── Funcionalidades ──
          _sectionHead(AppStrings.features, null, null),
          Row(children: const [
            Expanded(child: _FeatureCard(Icons.notifications_none, AppStrings.alertsTitle, AppStrings.alertsDesc)),
            SizedBox(width: 10),
            Expanded(child: _FeatureCard(Icons.location_on_outlined, AppStrings.localTitle, AppStrings.localDesc)),
          ]),
        ],
      );

  Widget _sectionHead(String title, String? action, VoidCallback? onTap) =>
      Padding(
        padding: const EdgeInsets.only(top: 21, bottom: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy),
              ),
            ),
            if (action != null)
              TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}

// ──────────────────────────────────────────────
// Widgets internos (se moverán a shared/ en F-2)
// ──────────────────────────────────────────────

class _DemoJob {
  final String title, company, location, mode, time;
  final int? match;
  const _DemoJob(this.title, this.company, this.location, this.mode, this.time, this.match);
}

class _JobCard extends StatelessWidget {
  final _DemoJob job;
  const _JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.match != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: kMatchBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '✦ ${job.match}% compatible contigo',
                  style: const TextStyle(color: kMatchText, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(children: [
              _CompanyMark(job.company),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(job.company, style: const TextStyle(color: kMuted, fontSize: 11)),
              ])),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, children: [
              _Tag('📍 ${job.location}'),
              _Tag(job.mode, blue: true),
            ]),
            const Divider(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(job.time, style: const TextStyle(fontSize: 10, color: kMuted)),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onPressed: () {},
                child: const Text(AppStrings.viewOffer),
              ),
            ]),
          ],
        ),
      );
}

class _CompanyMark extends StatelessWidget {
  final String company;
  const _CompanyMark(this.company);

  @override
  Widget build(BuildContext context) {
    final letters = company.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: 43, height: 43,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(11)),
      child: Text(letters, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool blue;
  const _Tag(this.text, {this.blue = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: blue ? const Color(0xFFEAF1FF) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: blue ? const Color(0xFF245BC8) : const Color(0xFF596579)),
        ),
      );
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: kBannerGradient),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.aiBadge, style: TextStyle(fontSize: 9, color: Color(0xFFD9E6FF), fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(AppStrings.aiTitle, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text(AppStrings.aiDesc, style: TextStyle(color: Color(0xFFD9E6FF), fontSize: 12, height: 1.4)),
          ],
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const _FeatureCard(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kBlue),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: kMuted, fontSize: 10, height: 1.45)),
          ],
        ),
      );
}
