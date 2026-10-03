import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/colombia_location_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _fullNameCtrl     = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _skillsCtrl       = TextEditingController();
  final _educationCtrl    = TextEditingController();
  final _expCtrl          = TextEditingController(text: '0');
  bool _obscure           = true;
  int _step               = 0; // 0 = datos básicos, 1 = perfil profesional (solo candidato)
  bool _isCompany         = false; // true = Registro Empresa, false = Registro Candidato

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _locationCtrl.dispose();
    _skillsCtrl.dispose();
    _educationCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    if (_isCompany) {
      await auth.registerCompany(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } else {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await auth.registerCandidate(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
        skills: skills,
        experienceYears: int.tryParse(_expCtrl.text) ?? 0,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        education: _educationCtrl.text.trim().isEmpty ? null : _educationCtrl.text.trim(),
      );
    }

    if (mounted) {
      if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente. Por favor inicia sesión.'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(color: kNavy),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const BrandFull(iconSize: 24),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurple.withOpacity(0.15),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // ── Paso indicador ──
                  if (!_isCompany) ...[
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: _StepIndicator(current: _step, total: 2),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Toggle Empresa / Candidato ──
                  if (_step == 0)
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoleToggleBtn(
                                title: 'Candidato',
                                active: !_isCompany,
                                onTap: () => setState(() => _isCompany = false),
                              ),
                              _RoleToggleBtn(
                                title: 'Empresa',
                                active: _isCompany,
                                onTap: () => setState(() => _isCompany = true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Form Glassmorphism Container ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: kNavy.withOpacity(0.03),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0 ? 'Crear cuenta' : 'Tu perfil profesional',
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: kNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _step == 0
                                ? (_isCompany ? 'Registra tu empresa para publicar vacantes' : 'Primero, tus datos de acceso')
                                : 'Cuéntanos sobre ti para mejores recomendaciones',
                            style: const TextStyle(fontSize: 13, color: kMuted),
                          ),
                          const SizedBox(height: 28),

                          Form(
                            key: _formKey,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _step == 0 ? _buildStep0() : _buildStep1(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _GradientButton(
                            text: _step == 0 ? (_isCompany ? 'Registrar Empresa' : 'Continuar') : 'Crear cuenta',
                            loading: auth.loading,
                            onPressed: (_step == 0 && !_isCompany) ? _nextStep : _submit,
                          ),
                          
                          if (_step == 0) ...[
                            const SizedBox(height: 24),
                            // ── Divisor O ──
                            Row(
                              children: [
                                Expanded(child: Divider(color: kNavy.withOpacity(0.1))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('O registrarse con', style: TextStyle(color: kMuted, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: kNavy.withOpacity(0.1))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Botones Sociales ──
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integración con Google próximamente')));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      backgroundColor: Colors.white.withOpacity(0.8),
                                      side: BorderSide(color: kNavy.withOpacity(0.1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: FaIcon(FontAwesomeIcons.google, color: const Color(0xFFDB4437), size: 18),
                                    label: const Text('Google', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integración con LinkedIn próximamente')));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      backgroundColor: Colors.white.withOpacity(0.8),
                                      side: BorderSide(color: kNavy.withOpacity(0.1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: FaIcon(FontAwesomeIcons.linkedin, color: const Color(0xFF0077B5), size: 18),
                                    label: const Text('LinkedIn', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Ya tienes cuenta ──
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta?', style: TextStyle(color: kMuted, fontSize: 14)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(color: kBlue, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() => Column(
        key: const ValueKey(0),
        children: [
          if (!_isCompany) ...[
            _LabeledField(
              controller: _fullNameCtrl,
              label: 'Nombre completo',
              hint: 'Ej. Andrés Gómez',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Mínimo 2 caracteres' : null,
            ),
            const SizedBox(height: 14),
          ],
          _LabeledField(
            controller: _emailCtrl,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _emailCtrl,
            builder: (context, value, child) {
              final text = value.text;
              if (text.contains('@')) {
                final parts = text.split('@');
                final localPart = parts[0];
                final typedDomain = parts.length > 1 ? parts[1].toLowerCase() : '';
                
                final allDomains = ['gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com'];
                final suggestions = allDomains.where((d) => d.startsWith(typedDomain) && d != typedDomain).toList();

                if (suggestions.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestions.map((domain) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(domain, style: const TextStyle(fontSize: 12, color: kNavy)),
                            backgroundColor: kLine,
                            side: BorderSide.none,
                            onPressed: () {
                              _emailCtrl.text = '$localPart@$domain';
                              _emailCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _emailCtrl.text.length));
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _passwordCtrl,
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: kMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passwordCtrl,
              builder: (context, value, child) {
                final pwd = value.text;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('La contraseña debe tener:', style: TextStyle(fontSize: 11, color: kNavy, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _Requirement(text: 'Mínimo 8 caracteres', met: pwd.length >= 8),
                    _Requirement(text: 'Una mayúscula y una minúscula', met: RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)),
                    _Requirement(text: 'Al menos un número', met: RegExp(r'[0-9]').hasMatch(pwd)),
                    _Requirement(text: 'Un carácter especial', met: RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_\+=;\[\]~`\\]').hasMatch(pwd)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _confirmPasswordCtrl,
            label: 'Confirmar contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
        ],
      );

  Widget _buildStep1() => Column(
        key: const ValueKey(1),
        children: [
          _LabeledField(
            controller: _locationCtrl,
            label: 'Ubicación',
            hint: 'Selecciona tu ciudad',
            icon: Icons.location_on_outlined,
            readOnly: true,
            onTap: () async {
              final result = await showColombiaLocationPicker(context);
              if (result != null) {
                _locationCtrl.text = result;
              }
            },
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _educationCtrl,
            label: 'Nivel educativo',
            hint: 'Ej. Tecnólogo en Sistemas',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _expCtrl,
            label: 'Años de experiencia',
            hint: '0',
            icon: Icons.work_outline,
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0) return 'Ingresa un número válido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _LabeledField(
            controller: _skillsCtrl,
            label: 'Habilidades (separadas por coma)',
            hint: 'Ej. Python, SQL, Comunicación',
            icon: Icons.star_outline,
            maxLines: 2,
          ),
        ],
      );

  void _nextStep() {
    // Validar solo los campos del paso 0
    if (!_isCompany && _fullNameCtrl.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu nombre completo.')),
      );
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')),
      );
      return;
    }
    
    final pwd = _passwordCtrl.text;
    if (pwd.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres.')),
      );
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(pwd) || !RegExp(r'[a-z]').hasMatch(pwd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe incluir al menos una mayúscula y una minúscula.')),
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(pwd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe incluir al menos un número.')),
      );
      return;
    }
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_\+=;\[\]~`\\]').hasMatch(pwd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe incluir al menos un carácter especial.')),
      );
      return;
    }
    if (pwd != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    if (_isCompany) {
      // Si es empresa, en teoría no deberíamos estar llamando a _nextStep, pero por si acaso.
      return;
    }
    setState(() => _step = 1);
  }
}

// ──────────────────────────────────────────────
// Widgets internos
// ──────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? kBlue : kLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      );
}

class _RoleToggleBtn extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _RoleToggleBtn({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? kNavy : kMuted,
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kNavy)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: obscure ? 1 : maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: kMuted, size: 20),
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kNavy.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      );
}

class _GradientButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;
  const _GradientButton({required this.text, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: loading ? null : kButtonGradient,
            color: loading ? kLine : null,
            borderRadius: BorderRadius.circular(13),
            boxShadow: loading ? [] : [BoxShadow(color: kBlue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            onPressed: loading ? null : onPressed,
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue))
                : Text(text, style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _Requirement extends StatelessWidget {
  final String text;
  final bool met;
  const _Requirement({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : kMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? Colors.green : kMuted,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
