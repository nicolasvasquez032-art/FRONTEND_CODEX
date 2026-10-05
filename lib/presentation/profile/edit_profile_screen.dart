import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/perfil_provider.dart';

enum EditProfileSection { personal, experience, education, skills }

class EditProfileScreen extends StatefulWidget {
  final EditProfileSection section;

  const EditProfileScreen({super.key, required this.section});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _portfolioCtrl;
  late TextEditingController _aboutMeCtrl;
  
  late TextEditingController _educationCtrl;
  
  late TextEditingController _experienceCtrl;
  late TextEditingController _jobTitleCtrl;
  
  late TextEditingController _skillsCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<PerfilProvider>().profile;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _locationCtrl = TextEditingController(text: profile?.location ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _portfolioCtrl = TextEditingController(text: profile?.portfolioUrl ?? '');
    _aboutMeCtrl = TextEditingController(text: profile?.aboutMe ?? '');
    
    _educationCtrl = TextEditingController(text: profile?.education ?? '');
    
    _experienceCtrl = TextEditingController(text: (profile?.experienceYears ?? 0).toString());
    _jobTitleCtrl = TextEditingController(text: profile?.jobTitle ?? '');
    
    _skillsCtrl = TextEditingController(text: profile?.skills.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _portfolioCtrl.dispose();
    _aboutMeCtrl.dispose();
    _educationCtrl.dispose();
    _experienceCtrl.dispose();
    _jobTitleCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final pp = context.read<PerfilProvider>();
    final profile = pp.profile;
    if (profile == null) return;

    final skillsList = _skillsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final exp = int.tryParse(_experienceCtrl.text) ?? 0;

    // Aunque solo editemos una sección, guardamos todo el modelo para no perder el resto de datos
    final success = await pp.guardar(
      profileId: profile.id,
      fullName: _nameCtrl.text.trim(),
      skills: skillsList,
      experienceYears: exp,
      location: _locationCtrl.text.trim(),
      education: _educationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      portfolioUrl: _portfolioCtrl.text.trim(),
      aboutMe: _aboutMeCtrl.text.trim(),
      jobTitle: _jobTitleCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pp.saveError ?? 'Error al guardar'), backgroundColor: Colors.red),
      );
    }
  }

  String _getTitle() {
    switch (widget.section) {
      case EditProfileSection.personal: return 'Datos Personales';
      case EditProfileSection.experience: return 'Experiencia';
      case EditProfileSection.education: return 'Educación';
      case EditProfileSection.skills: return 'Habilidades';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PerfilProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150, left: -150,
            child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: kBlue.withValues(alpha: 0.15))),
          ),
          Positioned(
            bottom: -150, right: -150,
            child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: kNavy.withValues(alpha: 0.08))),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: kNavy.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(_getTitle()),
                          
                          if (widget.section == EditProfileSection.personal) ...[
                            _buildTextField(_nameCtrl, 'Nombre Completo', Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildTextField(_locationCtrl, 'Ubicación (Ej. Bogotá, Colombia)', Icons.location_on_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(_phoneCtrl, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildTextField(_portfolioCtrl, 'LinkedIn / Portafolio URL', Icons.link_outlined, keyboardType: TextInputType.url),
                            const SizedBox(height: 16),
                            _buildTextField(_aboutMeCtrl, 'Acerca de mí (breve biografía)', Icons.info_outline, maxLines: 4),
                          ],
                          
                          if (widget.section == EditProfileSection.experience) ...[
                            _buildTextField(
                              _jobTitleCtrl, 
                              'Cargo (Ej. Desarrollador Frontend)', 
                              Icons.work_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _experienceCtrl, 
                              'Años de experiencia total (Ej. 3)', 
                              Icons.timeline_outlined, 
                              keyboardType: TextInputType.number,
                            ),
                          ],

                          if (widget.section == EditProfileSection.education) ...[
                            _buildTextField(_educationCtrl, 'Educación (Institución y Título)', Icons.school_outlined),
                          ],

                          if (widget.section == EditProfileSection.skills) ...[
                            _buildTextField(
                              _skillsCtrl, 
                              'Habilidades (Ej. Python, React, Liderazgo)', 
                              Icons.star_border_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 8),
                            const Text('Separa las habilidades usando comas (,)', style: TextStyle(color: kMuted, fontSize: 12)),
                          ],
                          
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: pp.saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: pp.saving
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kNavy),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted, fontWeight: FontWeight.w400),
        prefixIcon: maxLines == 1 ? Icon(icon, color: kBlue, size: 20) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kNavy.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Campo requerido';
        return null;
      },
    );
  }
}
