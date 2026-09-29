import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/perfil_provider.dart';

/// Widget embebible (no es una pantalla completa) que maneja
/// la selección y subida del CV del candidato.
class CvUploadWidget extends StatelessWidget {
  const CvUploadWidget({super.key});

  Future<void> _pick(BuildContext context) async {
    final profileId = context.read<AuthProvider>().session?.profileId ?? '';
    if (profileId.isEmpty) return;

    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el selector de archivos.')),
        );
      }
      return;
    }

    if (picked == null) return;

    final bytes    = (await picked.readAsBytes()).toList();
    final fileName = picked.name;
    final ext      = picked.extension?.toLowerCase() ?? 'pdf';
    final mimeType = _mimeFromExt(ext);

    if (!context.mounted) return;
    final ok = await context.read<PerfilProvider>().subirCv(
          profileId: profileId,
          fileBytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
        );

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('CV subido correctamente'),
          ]),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final err = context.read<PerfilProvider>().cvError ?? 'Error al subir el CV.';
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

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      default:     return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PerfilProvider>();
    final uploading = pp.cvStatus == CvUploadStatus.uploading;
    final hasCv     = pp.profile?.cvText != null && pp.profile!.cvText!.isNotEmpty;
    final preview   = pp.profile?.cvText ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: hasCv ? const Color(0xFFE8F8EF) : const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasCv ? Icons.description_outlined : Icons.upload_file_outlined,
                  color: hasCv ? kGreen : kBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCv ? 'CV cargado' : AppStrings.uploadCv,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kNavy),
                    ),
                    Text(
                      hasCv
                          ? 'El sistema analizó tu CV para recomendaciones'
                          : 'PDF, JPG, PNG o WEBP',
                      style: const TextStyle(color: kMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (hasCv)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kMatchBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ Activo',
                    style: TextStyle(color: kMatchText, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          // ── Preview del texto extraído ────────────────────
          if (hasCv && preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kLine),
              ),
              child: Text(
                preview.length > 300 ? '${preview.substring(0, 300)}...' : preview,
                style: const TextStyle(fontSize: 11, color: kMuted, height: 1.6),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Botón ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 44,
            child: uploading
                ? Container(
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: kBlue),
                        ),
                        SizedBox(width: 10),
                        Text('Subiendo CV...', style: TextStyle(color: kBlue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _pick(context),
                    icon: Icon(
                      hasCv ? Icons.upload_outlined : Icons.attach_file_outlined,
                      size: 18,
                    ),
                    label: Text(hasCv ? 'Reemplazar CV' : 'Seleccionar archivo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBlue,
                      side: const BorderSide(color: kBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
