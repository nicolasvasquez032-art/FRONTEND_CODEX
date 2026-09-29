import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/profile.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';
import '../shared/widgets/colombia_location_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _educationCtrl;
  String? _location;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.profile.fullName);
    _skillsCtrl   = TextEditingController(text: widget.profile.skills.join(', '));
    _expCtrl      = TextEditingController(text: widget.profile.experienceYears.toString());
    _educationCtrl = TextEditingController(text: widget.profile.education ?? '');
    _location     = widget.profile.location;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skillsCtrl.dispose();
    _expCtrl.dispose();
    _educationCtrl.dispose();
    super.dispose();
  }

  List<String> get _parsedSkills => _skillsCtrl.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final profileId = context.read<AuthProvider>().session?.profileId ?? '';
    if (profileId.isEmpty) return;

    final ok = await context.read<PerfilProvider>().guardar(
          profileId: profileId,
          fullName: _nameCtrl.text.trim(),
          skills: _parsedSkills,
          experienceYears: int.tryParse(_expCtrl.text.trim()) ?? 0,
          location: _location,
          education: _educationCtrl.text.trim().isEmpty ? null : _educationCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(AppStrings.successProfileSaved),
          ]),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<PerfilProvider>().saveError ?? 'Error al guardar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<PerfilProvider, bool>((p) => p.saving);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kLine),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Avatar + nombre ──────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80, height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: kLogoGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kBlue.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Text(
                      widget.profile.initial,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Sección: Información personal ────────────────
            _SectionHeader(icon: Icons.person_outline, label: 'Información personal'),
            const SizedBox(height: 12),

            _Field(
              controller: _nameCtrl,
              label: AppStrings.fullName,
              hint: 'Ej. María López',
              icon: Icons.badge_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.errRequired : null,
            ),
            const SizedBox(height: 14),

            _Field(
              controller: _educationCtrl,
              label: AppStrings.education,
              hint: 'Ej. Tecnólogo en Sistemas',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 14),

            // ── Ubicación (picker Colombia) ───────────────────
            _LocationField(
              current: _location,
              onChanged: (loc) => setState(() => _location = loc),
            ),
            const SizedBox(height: 24),

            // ── Sección: Experiencia profesional ─────────────
            _SectionHeader(icon: Icons.work_outline, label: 'Experiencia profesional'),
            const SizedBox(height: 12),

            _Field(
              controller: _expCtrl,
              label: AppStrings.experienceYears,
              hint: 'Ej. 2',
              icon: Icons.timeline_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return AppStrings.errRequired;
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return 'Ingresa un número válido.';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Sección: Habilidades ──────────────────────────
            _SectionHeader(icon: Icons.code_outlined, label: 'Habilidades'),
            const SizedBox(height: 8),
            const Text(
              'Separa cada habilidad con una coma.',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),

            _Field(
              controller: _skillsCtrl,
              label: 'Habilidades',
              hint: 'Python, Flutter, SQL, Figma...',
              icon: Icons.tag_outlined,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Agrega al menos una habilidad.' : null,
            ),

            // Preview chips de skills
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _skillsCtrl,
              builder: (_, __, ___) {
                final chips = _parsedSkills;
                if (chips.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips
                        .map((s) => _SkillChip(s))
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            // ── Botón guardar ─────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: kBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        AppStrings.saveChanges,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Widgets internos
// ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: kBlue, size: 17),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kNavy)),
        ],
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: kText),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: kMuted, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kBlue, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
        ),
      );
}

class _LocationField extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _LocationField({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showColombiaLocationPicker(context);
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: kMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  current ?? 'Selecciona tu ubicación',
                  style: TextStyle(
                    fontSize: 14,
                    color: current != null ? kText : kMuted,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: kMuted, size: 20),
            ],
          ),
        ),
      );
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF3FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF245BC8), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
