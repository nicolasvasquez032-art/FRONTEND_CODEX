import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/widgets/brand_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.requestPasswordReset(email);
    if (mounted) setState(() => _sent = ok || auth.error == null);
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
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _sent ? _buildSuccess() : _buildForm(auth),
        ),
      ),
    );
  }

  Widget _buildForm(AuthProvider auth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset, color: kBlue, size: 28),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recuperar contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(fontSize: 13, color: kMuted, height: 1.5),
          ),
          const SizedBox(height: 32),

          // ── Campo correo ──
          const Text(
            'Correo electrónico',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kNavy),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'tu@correo.com',
              prefixIcon: Icon(Icons.email_outlined, color: kMuted, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          // ── Botón ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: auth.loading ? null : kButtonGradient,
                color: auth.loading ? kLine : null,
                borderRadius: BorderRadius.circular(13),
                boxShadow: auth.loading
                    ? []
                    : [BoxShadow(color: kBlue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue))
                    : const Text('Enviar enlace', style: TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      );

  Widget _buildSuccess() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kMatchBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: kMatchText, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Listo!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kNavy),
            ),
            const SizedBox(height: 10),
            const Text(
              'Si el correo está registrado, recibirás un enlace de recuperación en los próximos minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kMuted, height: 1.6),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver al inicio de sesión'),
            ),
          ],
        ),
      );
}
