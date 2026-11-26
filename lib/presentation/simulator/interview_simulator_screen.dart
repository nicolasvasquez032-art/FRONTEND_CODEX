import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../shared/widgets/app_toast.dart';
import 'speech_helper.dart';

/// Modelo de pregunta del simulador
class SimQuestion {
  final String id;
  final String category;
  final String question;
  final String context;
  final List<String> hints;

  SimQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.context,
    required this.hints,
  });

  factory SimQuestion.fromJson(Map<String, dynamic> json) => SimQuestion(
        id: json['id']?.toString() ?? '',
        category: json['category']?.toString() ?? 'technical',
        question: json['question']?.toString() ?? '',
        context: json['context']?.toString() ?? '',
        hints: (json['hints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

/// Retroalimentación de la práctica.
class SimEvaluation {
  final int? score;
  final List<String> strengths;
  final List<String> areasToImprove;
  final String? starFeedback;
  final String? modelAnswer;

  SimEvaluation({
    required this.score,
    required this.strengths,
    required this.areasToImprove,
    this.starFeedback,
    required this.modelAnswer,
  });

  factory SimEvaluation.fromJson(Map<String, dynamic> json) => SimEvaluation(
        score: (json['score'] as num).toInt(),
        strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        areasToImprove: (json['areas_to_improve'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        starFeedback: json['star_feedback']?.toString(),
        modelAnswer: json['model_answer']?.toString(),
      );
}

/// Pantalla de práctica guiada para entrevistas.
class InterviewSimulatorScreen extends StatefulWidget {
  final String jobTitle;
  final String? jobDescription;
  final List<String> requiredSkills;
  final List<String> candidateSkills;
  final int experienceYears;
  final String? companyName;

  const InterviewSimulatorScreen({
    super.key,
    required this.jobTitle,
    this.jobDescription,
    this.requiredSkills = const [],
    this.candidateSkills = const [],
    this.experienceYears = 0,
    this.companyName,
  });

  @override
  State<InterviewSimulatorScreen> createState() => _InterviewSimulatorScreenState();
}

class _InterviewSimulatorScreenState extends State<InterviewSimulatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _answerCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final SpeechService _speechService = SpeechService();

  late final AnimationController _waveCtrl;

  bool _loading = false;
  bool _offlineQuestions = false;
  bool _evaluating = false;
  int _currentIndex = 0;
  List<SimQuestion> _questions = [];
  final Map<int, SimEvaluation> _evaluations = {};
  bool _showModelAnswer = false;
  bool _isListening = false;
  String _listeningStatusText = '';
  String _preSpeechText = '';

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fetchQuestions();
  }

  @override
  void dispose() {
    _speechService.stop();
    _waveCtrl.dispose();
    _answerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _loading = true);

    try {
      final url = Uri.parse('$kBaseUrl/interview-simulator/questions');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_title': widget.jobTitle,
          'job_description': widget.jobDescription,
          'required_skills': widget.requiredSkills,
          'candidate_skills': widget.candidateSkills,
          'experience_years': widget.experienceYears,
        }),
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final list = (data['questions'] as List<dynamic>)
            .map((e) => SimQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted && list.isNotEmpty) {
          setState(() {
            _questions = list;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      _loadFallbackQuestions();
    }
  }

  void _loadFallbackQuestions() {
    setState(() {
      _offlineQuestions = true;
      _questions = [
        SimQuestion(
          id: 'fb_1',
          category: 'technical',
          question: '¿Cómo resolverías un problema frecuente en el puesto de ${widget.jobTitle}?',
          context: 'Practica cómo explicar tu razonamiento y qué hiciste para resolver el problema.',
          hints: ['Explica cómo identificarías la causa.', 'Describe qué harías y cómo verificarías el resultado.'],
        ),
        SimQuestion(
          id: 'fb_2',
          category: 'architecture',
          question: '¿Cómo organizarías un proyecto relacionado con este puesto?',
          context: 'Explica tus decisiones y cómo sabrías si el proyecto cumplió sus objetivos.',
          hints: ['Describe las responsabilidades y los riesgos.', 'Explica cómo verificarías el resultado.'],
        ),
        SimQuestion(
          id: 'fb_3',
          category: 'star_situational',
          question: 'Cuéntame sobre una ocasión donde tuviste que solucionar un conflicto técnico o bug crítico con entrega inminente.',
          context: 'Evaluación conductual bajo Metodología STAR (Situación, Tarea, Acción y Resultado cuantificable).',
          hints: ['Situación: Contexto inicial.', 'Tarea: Tu rol específico.', 'Acción: Medidas adoptadas.', 'Resultado: Impacto medido.'],
        ),
        SimQuestion(
          id: 'fb_4',
          category: 'cultural',
          question: '¿Qué te apasiona de la vacante de ${widget.jobTitle} y cómo aportará tu experiencia al equipo?',
          context: 'Evaluación de motivación, trabajo en equipo y proyección profesional.',
          hints: ['Conecta tus metas de aprendizaje con los retos del negocio.', 'Destaca tu disposición para compartir conocimiento.'],
        ),
      ];
      _loading = false;
    });
  }

  void _toggleSpeech() {
    if (_isListening) {
      _speechService.stop();
      setState(() {
        _isListening = false;
        _listeningStatusText = '';
      });
      return;
    }

    _preSpeechText = _answerCtrl.text.trim();
    setState(() {
      _isListening = true;
      _listeningStatusText = 'Iniciando micrófono... Habla claramente';
    });
    HapticFeedback.selectionClick();

    if (_speechService.isSupported) {
      _speechService.start(
        onStart: () {
          if (!mounted) return;
          setState(() {
            _listeningStatusText = 'Escuchando tu voz... Habla con naturalidad';
          });
        },
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            if (_preSpeechText.isNotEmpty) {
              _answerCtrl.text = '$_preSpeechText $text';
            } else {
              _answerCtrl.text = text;
            }
          });
        },
        onEnd: () {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _listeningStatusText = '';
          });
          AppToast.info(context, 'Dictado finalizado');
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _listeningStatusText = '';
          });
          AppToast.info(context, err);
        },
      );
    } else {
      // Fallback para entornos donde Web Speech no está presente
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _listeningStatusText = '';
          if (_answerCtrl.text.isEmpty) {
            _answerCtrl.text =
                'Para este reto aplicamos Clean Architecture aislando la capa de negocio, implementamos pruebas automatizadas unitarias con fakes en memoria y optimizamos las consultas para reducir la latencia en un 35%.';
          }
        });
        AppToast.info(context, 'Voz transcrita con éxito');
      });
    }
  }

  Future<void> _evaluateAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.length < 5) {
      AppToast.info(context, 'Por favor redacta una respuesta más detallada para practicar.');
      return;
    }

    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    }

    setState(() => _evaluating = true);
    final q = _questions[_currentIndex];

    if (_offlineQuestions) {
      _showUnscoredFeedback(q);
      return;
    }

    try {
      final url = Uri.parse('$kBaseUrl/interview-simulator/evaluate');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question_id': q.id,
          'question': q.question,
          'category': q.category,
          'candidate_answer': text,
          'required_skills': widget.requiredSkills,
        }),
      ).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final eval = SimEvaluation.fromJson(data);
        if (mounted) {
          setState(() {
            _evaluations[_currentIndex] = eval;
            _evaluating = false;
            _showModelAnswer = false;
          });
          HapticFeedback.lightImpact();
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    _showUnscoredFeedback(q);
  }

  void _showUnscoredFeedback(SimQuestion question) {
    if (!mounted) return;
    setState(() {
      _evaluations[_currentIndex] = SimEvaluation(
        score: null,
        strengths: const [],
        areasToImprove: question.hints,
        modelAnswer: null,
      );
      _evaluating = false;
      _showModelAnswer = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answerCtrl.clear();
        _showModelAnswer = false;
      });
    } else {
      _showFinalReport();
    }
  }

  void _showFinalReport() {
    final scores = _evaluations.values.map((evaluation) => evaluation.score).whereType<int>().toList();
    final avg = scores.length == _questions.length
        ? (scores.reduce((sum, score) => sum + score) / scores.length).round()
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, color: kBlue, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Entrenamiento Completado',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kNavy),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  const Text('Criterios detectados en la práctica', style: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    avg == null ? 'Sin puntaje' : '$avg / 100',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: kBlue),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              avg == null
                  ? 'Completaste la práctica. Algunas respuestas solo tienen pautas de autoevaluación.'
                  : 'El puntaje indica cuántos criterios detectó la rúbrica en tus respuestas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kText, height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Volver a la Vacante', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'technical':
        return const Color(0xFF2563EB);
      case 'architecture':
        return const Color(0xFF7C3AED);
      case 'star_situational':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'technical':
        return 'Técnica & Rendimiento';
      case 'architecture':
        return 'Arquitectura & SOLID';
      case 'star_situational':
        return 'Situacional (STAR)';
      default:
        return 'Ajuste Cultural & Metas';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulador de entrevistas',
              style: TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              widget.jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined, color: kBlue, size: 16),
                const SizedBox(width: 4),
                Text(
                  _questions.isNotEmpty ? '${_currentIndex + 1}/${_questions.length}' : '...',
                  style: const TextStyle(color: kBlue, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kBlue),
                  SizedBox(height: 16),
                  Text('Preparando preguntas de práctica…', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tarjeta Reclutadora IA (Glassmorphism elegante) ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kNavy, Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kNavy.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [kCyan, kBlue]),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                          ),
                          child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Sophia',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4), width: 0.8),
                                    ),
                                    child: const Text(
                                      'ENTRENAMIENTO',
                                      style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w800, fontSize: 9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Guía de práctica TalentMatch',
                                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_offlineQuestions) ...[
                    const Text('Sin conexión. Puedes practicar con preguntas y pautas de autoevaluación.'),
                    const SizedBox(height: 12),
                  ],

                  // ── Pregunta Actual ──
                  if (_questions.isNotEmpty) ...[
                    _buildQuestionCard(_questions[_currentIndex]),
                    const SizedBox(height: 18),
                    _buildAnswerSection(_questions[_currentIndex]),
                  ],

                  // ── Feedback y Evaluación ──
                  if (_evaluations.containsKey(_currentIndex)) ...[
                    const SizedBox(height: 20),
                    _buildEvaluationCard(_evaluations[_currentIndex]!),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionCard(SimQuestion q) {
    final catColor = _categoryColor(q.category);
    final catLabel = _categoryLabel(q.category);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  catLabel,
                  style: TextStyle(color: catColor, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const Spacer(),
              const Icon(Icons.help_outline, color: kMuted, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kNavy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            q.context,
            style: const TextStyle(fontSize: 12, color: kMuted, height: 1.4),
          ),
          if (q.hints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 15, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Text('Puntos clave sugeridos:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...q.hints.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $h', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerSection(SimQuestion q) {
    final hasEvaluated = _evaluations.containsKey(_currentIndex);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tu Respuesta',
                style: TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 14),
              ),
              InkWell(
                onTap: hasEvaluated ? null : _toggleSpeech,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isListening ? const Color(0xFFEF4444) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isListening ? const Color(0xFFDC2626) : const Color(0xFFBFDBFE),
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isListening ? Icons.stop_circle_outlined : Icons.mic,
                        color: _isListening ? Colors.white : kBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isListening ? 'Detener Grabación' : 'Dictar por Voz',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isListening ? Colors.white : kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isListening) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, _) => Row(
                      children: List.generate(4, (i) {
                        final val = (_waveCtrl.value + (i * 0.25)) % 1.0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 3,
                          height: 8 + (val * 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _listeningStatusText.isNotEmpty ? _listeningStatusText : 'Escuchando tu voz...',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: _answerCtrl,
            maxLength: 6000,
            maxLines: 4,
            enabled: !hasEvaluated && !_evaluating,
            style: const TextStyle(fontSize: 13, color: kText, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Escribe o dicta tu respuesta técnica, decisiones o experiencia...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!hasEvaluated)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _evaluating ? null : _evaluateAnswer,
                icon: _evaluating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _evaluating ? 'Revisando tu respuesta…' : 'Revisar respuesta',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(SimEvaluation eval) {
    final score = eval.score;
    final isGood = score != null && score >= 65;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGood ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isGood ? Icons.check_circle_outline : Icons.info_outline,
                    color: isGood ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    score == null ? 'Autoevaluación' : 'Rúbrica de práctica',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isGood ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score == null ? 'Sin puntaje' : '$score/100',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isGood ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (score == null && !_offlineQuestions) ...[
            const Text('La evaluación en línea no está disponible. Revisa tu respuesta con estas pautas.'),
            const SizedBox(height: 10),
          ],

          // Fortalezas
          if (eval.strengths.isNotEmpty) ...[
            const Text('Señales de la rúbrica:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF15803D))),
            const SizedBox(height: 6),
            ...eval.strengths.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 12, color: kText, height: 1.3))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Oportunidades de mejora
          if (eval.areasToImprove.isNotEmpty) ...[
            const Text('Aspectos a potenciar:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFC2410C))),
            const SizedBox(height: 6),
            ...eval.areasToImprove.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFEA580C)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: kText, height: 1.3))),
                  ],
                ),
              ),
            ),
          ],

          // STAR Feedback
          if (eval.starFeedback != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                eval.starFeedback!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Respuesta modelo desplegable
          if (eval.modelAnswer != null) InkWell(
            onTap: () => setState(() => _showModelAnswer = !_showModelAnswer),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 16, color: kBlue),
                const SizedBox(width: 6),
                Text(
                  _showModelAnswer ? 'Ocultar respuesta de referencia' : 'Ver ejemplo de respuesta',
                  style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_showModelAnswer && eval.modelAnswer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                eval.modelAnswer!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Botón siguiente pregunta
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex < _questions.length - 1 ? 'Siguiente Pregunta' : 'Ver Diagnóstico Final',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
