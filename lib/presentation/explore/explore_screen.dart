import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _query = '';

  static const _jobs = [
    ('Desarrollador Junior', 'TechSolutions', 'Fusagasugá', 'Remoto', 'Hace 1 hora'),
    ('Analista de Datos', 'DataPro', 'Fusagasugá', 'Híbrido', 'Hace 3 horas'),
    ('Practicante de Marketing', 'Impulsa S.A.S.', 'Fusagasugá', 'Presencial', 'Hace 5 horas'),
    ('Soporte Técnico Junior', 'Andes Digital', 'Fusagasugá', 'Híbrido', 'Ayer'),
    ('Desarrollador Web', 'Nexo Tecnología', 'Bogotá', 'Remoto', 'Ayer'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _jobs.where((j) =>
        '${j.$1} ${j.$2} ${j.$3} ${j.$4}'.toLowerCase().contains(_query.toLowerCase())).toList();

    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        const Text(AppStrings.exploreSubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 4),
        const Text(AppStrings.exploreTitle, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 18),

        // Búsqueda
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: AppStrings.searchJobHint,
            prefixIcon: Icon(Icons.search, color: kMuted),
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text(AppStrings.noResults, style: TextStyle(color: kMuted))),
          )
        else
          ...filtered.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExploreCard(title: j.$1, company: j.$2, location: j.$3, mode: j.$4, time: j.$5),
              )),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String title, company, location, mode, time;
  const _ExploreCard({required this.title, required this.company, required this.location, required this.mode, required this.time});

  String get _letters => company.split(' ').map((w) => w[0]).take(2).join();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: kLine), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: kNavy.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 43, height: 43, alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(11)),
              child: Text(_letters, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(company, style: const TextStyle(color: kMuted, fontSize: 11)),
            ])),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [
            _chip('📍 $location'), _chip(mode, blue: true),
          ]),
          const Divider(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(time, style: const TextStyle(fontSize: 10, color: kMuted)),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              onPressed: () {},
              child: const Text(AppStrings.viewOffer),
            ),
          ]),
        ]),
      );

  Widget _chip(String t, {bool blue = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: blue ? const Color(0xFFEAF1FF) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(t, style: TextStyle(fontSize: 10, color: blue ? const Color(0xFF245BC8) : const Color(0xFF596579))),
      );
}
