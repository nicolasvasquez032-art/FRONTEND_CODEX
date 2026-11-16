import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile.dart';

/// Hoja modal interactiva que presenta las habilidades detectadas por la IA a partir del CV extraído.
/// Permite al candidato revisar, confirmar, añadir o eliminar habilidades antes de guardarlas.
class CvSkillsExtractionSheet extends StatefulWidget {
  final Profile profile;
  final String cvText;
  final bool isSpanish;
  final Future<bool> Function(List<String> confirmedSkills) onConfirm;

  const CvSkillsExtractionSheet({
    super.key,
    required this.profile,
    required this.cvText,
    required this.isSpanish,
    required this.onConfirm,
  });

  @override
  State<CvSkillsExtractionSheet> createState() => _CvSkillsExtractionSheetState();
}

class _CvSkillsExtractionSheetState extends State<CvSkillsExtractionSheet> {
  late Set<String> _selectedSkills;
  final TextEditingController _customSkillCtrl = TextEditingController();
  bool _saving = false;

  // Catálogo inteligente de detección técnica
  static const List<String> _knowledgeBase = [
    'Flutter', 'Dart', 'Python', 'FastAPI', 'Django', 'Flask',
    'Java', 'Spring Boot', 'JavaScript', 'TypeScript', 'React', 'Angular',
    'Vue.js', 'Next.js', 'Node.js', 'Express', 'SQL', 'PostgreSQL',
    'MySQL', 'MongoDB', 'Redis', 'Docker', 'Kubernetes', 'AWS', 'GCP',
    'Azure', 'Git', 'GitHub', 'CI/CD', 'Linux', 'REST APIs', 'GraphQL',
    'Machine Learning', 'Inteligencia Artificial', 'Deep Learning', 'PyTorch',
    'TensorFlow', 'UI/UX', 'Figma', 'Scrum', 'Agile', 'Clean Architecture',
    'Testing', 'TDD', 'Inglés Técnico',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set<String>.from(widget.profile.skills);
    _extractSkillsFromCv();
  }

  void _extractSkillsFromCv() {
    final textLower = widget.cvText.toLowerCase();
    for (final tech in _knowledgeBase) {
      final tLower = tech.toLowerCase();
      // Búsqueda por palabra o frase clave
      if (textLower.contains(tLower)) {
        _selectedSkills.add(tech);
      }
    }
  }

  @override
  void dispose() {
    _customSkillCtrl.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final text = _customSkillCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedSkills.add(text);
        _customSkillCtrl.clear();
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final success = await widget.onConfirm(_selectedSkills.toList());
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.isSpanish;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de agarre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cabecera con Icono de IA
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: kBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEs ? 'Habilidades detectadas por IA' : 'AI Extracted Skills',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kNavy,
                        ),
                      ),
                      Text(
                        isEs
                            ? 'Confirma las tecnologías para afinar tus recomendaciones'
                            : 'Confirm technologies to fine-tune your recommendations',
                        style: const TextStyle(fontSize: 11.5, color: kMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kMuted, size: 20),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Explicación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: kBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEs
                          ? 'Toca cualquier habilidad para seleccionarla o deseleccionarla. Estas competencias se indexan en pgvector para tu perfil.'
                          : 'Tap any skill to select or deselect. These competencies are indexed into pgvector for your profile.',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista deslizable de habilidades
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSkills.map((skill) {
                        return FadeIn(
                          duration: const Duration(milliseconds: 200),
                          child: InkWell(
                            onTap: () => _toggleSkill(skill),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: kBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: kBlue,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: kBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: kBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.close, size: 12, color: kBlue),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Campo para agregar habilidad personalizada
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              controller: _customSkillCtrl,
                              decoration: InputDecoration(
                                hintText: isEs ? 'Agregar otra habilidad (ej. Docker)...' : 'Add another skill (e.g. Docker)...',
                                hintStyle: const TextStyle(fontSize: 12, color: kMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: kBlue),
                                ),
                              ),
                              onSubmitted: (_) => _addCustomSkill(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addCustomSkill,
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          tooltip: isEs ? 'Agregar' : 'Add',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Acciones principales
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEs ? 'Omitir' : 'Skip',
                      style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEs ? 'Confirmar Habilidades' : 'Confirm Skills',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
