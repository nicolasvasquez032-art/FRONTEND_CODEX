import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talentmatch/core/constants/app_colors.dart';
import 'package:talentmatch/presentation/shared/providers/chat_provider.dart';
import 'package:talentmatch/presentation/shared/providers/locale_provider.dart';
import 'package:talentmatch/presentation/shared/widgets/app_toast.dart';

class ScheduleInterviewDialog extends StatefulWidget {
  final String roomId;
  final String candidateName;
  final String vacancyTitle;

  const ScheduleInterviewDialog({
    super.key,
    required this.roomId,
    required this.candidateName,
    this.vacancyTitle = '',
  });

  static Future<bool?> show(
    BuildContext context, {
    required String roomId,
    required String candidateName,
    String vacancyTitle = '',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScheduleInterviewDialog(
        roomId: roomId,
        candidateName: candidateName,
        vacancyTitle: vacancyTitle,
      ),
    );
  }

  @override
  State<ScheduleInterviewDialog> createState() => _ScheduleInterviewDialogState();
}

class _ScheduleInterviewDialogState extends State<ScheduleInterviewDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _titleCtrl;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Por defecto: Mañana a las 10:00 AM
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final defaultTitle = widget.vacancyTitle.isNotEmpty
        ? 'Entrevista: ${widget.vacancyTitle}'
        : 'Entrevista Laboral con ${widget.candidateName}';
    _titleCtrl = TextEditingController(text: defaultTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              onSurface: kNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              onSurface: kNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmarAgendamiento() async {
    final isEs = context.read<LocaleProvider>().isSpanish;
    final titulo = _titleCtrl.text.trim();
    if (titulo.isEmpty) {
      AppToast.warning(context, isEs ? 'Ingresa un título para la reunión' : 'Please enter a meeting title');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final combined = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final dateFormatted = isEs
          ? DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(combined)
          : DateFormat("EEEE, MMMM d, yyyy", 'en').format(combined);
      final hourStr = _selectedTime.format(context);
      final fechaHoraString = '$dateFormatted - $hourStr';

      final chat = context.read<ChatProvider>();
      final res = await chat.programarEntrevista(
        widget.roomId,
        titulo,
        fechaHoraString,
        notas: _notesCtrl.text.trim(),
      );

      if (mounted) {
        if (res != null) {
          AppToast.success(
            context,
            isEs ? '¡Entrevista agendada con éxito!' : 'Interview scheduled successfully!',
          );
          Navigator.of(context).pop(true);
        } else {
          AppToast.error(
            context,
            isEs ? 'No se pudo agendar la entrevista' : 'Failed to schedule interview',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.watch<LocaleProvider>().isSpanish;

    final dateFormatted = isEs
        ? DateFormat("EEE, d 'de' MMM, yyyy", 'es').format(_selectedDate)
        : DateFormat("EEE, MMM d, yyyy", 'en').format(_selectedDate);
    final timeFormatted = _selectedTime.format(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: kBlue, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEs ? 'Programar Entrevista' : 'Schedule Interview',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                            ),
                          ),
                          Text(
                            widget.candidateName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Título de la reunión
                Text(
                  isEs ? 'Título de la reunión' : 'Meeting Title',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kNavy),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  style: GoogleFonts.inter(fontSize: 14, color: kText),
                  decoration: InputDecoration(
                    hintText: isEs ? 'Ej. Entrevista Técnica' : 'e.g. Technical Interview',
                    filled: true,
                    fillColor: kBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kLine),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de Fecha y Hora en 2 columnas
                Row(
                  children: [
                    // Columna Fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEs ? 'Fecha' : 'Date',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kNavy),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kLine),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: kBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dateFormatted,
                                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: kNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Columna Hora
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEs ? 'Hora' : 'Time',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kNavy),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickTime(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kLine),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: kBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      timeFormatted,
                                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: kNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notas adicionales
                Text(
                  isEs ? 'Instrucciones o notas para el candidato (opcional)' : 'Notes or instructions (optional)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kNavy),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13, color: kText),
                  decoration: InputDecoration(
                    hintText: isEs ? 'Ej. Tener a mano su portafolio o código fuente...' : 'e.g. Have your code portfolio ready...',
                    filled: true,
                    fillColor: kBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kLine),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        child: Text(
                          isEs ? 'Cancelar' : 'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: kMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _confirmarAgendamiento,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18, color: Colors.white),
                        label: Text(
                          isEs ? 'Agendar Reunión' : 'Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
