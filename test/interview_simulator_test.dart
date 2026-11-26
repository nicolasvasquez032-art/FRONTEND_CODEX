import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/presentation/simulator/interview_simulator_screen.dart';

void main() {
  testWidgets('InterviewSimulatorScreen renders questions and UI elements', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: InterviewSimulatorScreen(
          jobTitle: 'Desarrollador Flutter Senior',
          requiredSkills: ['Flutter', 'Dart', 'Clean Architecture'],
          companyName: 'TechCorp Colombia',
        ),
      ),
    );

    // Esperar a que se procese el initState y fallback questions
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Validar encabezados y avatar de Sophia
    expect(find.text('Simulador de entrevistas'), findsOneWidget);
    expect(find.text('Desarrollador Flutter Senior'), findsOneWidget);
    expect(find.text('Sophia'), findsOneWidget);
    expect(find.text('ENTRENAMIENTO'), findsOneWidget);

    // Validar presencia de campo de respuesta y botón de evaluación
    expect(find.text('Tu Respuesta'), findsOneWidget);
    expect(find.text('Dictar por Voz'), findsOneWidget);

    final evalBtn = find.text('Revisar respuesta');
    expect(evalBtn, findsOneWidget);

    // Ingresar texto de respuesta
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);
    await tester.enterText(
      inputFinder,
      'Aplicamos Clean Architecture, pruebas unitarias automatizadas y optimización de repintados con widgets const.',
    );
    await tester.pump();

    // Asegurar visibilidad del botón y presionar
    await tester.ensureVisible(evalBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(evalBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Sin conexión.'), findsOneWidget);
    expect(find.text('Autoevaluación'), findsOneWidget);
    expect(find.text('Sin puntaje'), findsOneWidget);
    expect(find.text('Aspectos a potenciar:'), findsOneWidget);
    expect(find.text('Siguiente Pregunta'), findsOneWidget);
  });
}
