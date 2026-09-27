import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _fullNameCtrl     = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _skillsCtrl       = TextEditingController();
  final _educationCtrl    = TextEditingController();
  final _expCtrl          = TextEditingController(text: '0');
  bool _obscure           = true;
  int _step               = 0; // 0 = datos básicos, 1 = perfil profesional

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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

    if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        leading: BackButton(color: kNavy),
        backgroundColor: kBg,
        elevation: 0,
        title: const BrandFull(iconSize: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Paso indicador ──
              _StepIndicator(current: _step, total: 2),
              const SizedBox(height: 28),

              Text(
                _step == 0 ? 'Crear cuenta' : 'Tu perfil profesional',
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 0
                    ? 'Primero, tus datos de acceso'
                    : 'Cuéntanos sobre ti para mejores recomendaciones',
                style: const TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 28),

              // ── Formulario ──
              Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildStep0()
                      : _buildStep1(),
                ),
              ),
              const SizedBox(height: 24),

              // ── Botón ──
              _GradientButton(
                text: _step == 0 ? 'Continuar' : 'Crear cuenta',
                loading: auth.loading,
                onPressed: _step == 0 ? _nextStep : _submit,
              ),
              const SizedBox(height: 20),

              // ── Ya tienes cuenta ──
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta?', style: TextStyle(color: kMuted, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() => Column(
        key: const ValueKey(0),
        children: [
          _LabeledField(
            controller: _fullNameCtrl,
            label: 'Nombre completo',
            hint: 'Ej. Andrés Gómez',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.trim().length < 2) ? 'Mínimo 2 caracteres' : null,
          ),
          const SizedBox(height: 14),
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
        ],
      );

  Widget _buildStep1() => Column(
        key: const ValueKey(1),
        children: [
          _LabeledField(
            controller: _locationCtrl,
            label: 'Ubicación',
            hint: 'Ej. Fusagasugá',
            icon: Icons.location_on_outlined,
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
    if (_fullNameCtrl.text.trim().length < 2) {
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
    if (_passwordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres.')),
      );
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

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

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
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: kMuted, size: 20),
              suffixIcon: suffix,
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
