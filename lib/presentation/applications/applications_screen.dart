import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(17),
        children: [
          const Text(AppStrings.applicationsSubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(AppStrings.applicationsTitle, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 20),

          // Estado vacío — se reemplaza con datos reales en Sprint F-4
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kLine),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.fact_check_outlined, size: 48, color: kBlue),
                SizedBox(height: 12),
                Text(AppStrings.noApplications, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kNavy)),
                SizedBox(height: 8),
                Text(AppStrings.noApplicationsDesc, textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      );
}
