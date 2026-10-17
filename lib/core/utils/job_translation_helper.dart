/// Helper utilitario para traducir reactivamente campos dinámicos de vacantes
/// (título, categoría, descripción, requisitos, ubicación) y explicaciones IA
/// cuando el usuario cambia el idioma a Inglés.
class JobTranslationHelper {
  // ── Categorías ───────────────────────────────────────────────────────────
  static const Map<String, String> _categoriesEsToEn = {
    'Ingeniería de Software': 'Software Engineering',
    'Tecnología': 'Technology',
    'Datos': 'Data',
    'Diseño': 'Design',
    'Infraestructura': 'Infrastructure',
    'Desarrollo': 'Development',
    'Ventas': 'Sales',
    'Marketing': 'Marketing',
    'Finanzas': 'Finance',
    'Recursos Humanos': 'Human Resources',
    'Operaciones': 'Operations',
    'Ciberseguridad': 'Cybersecurity',
    'Producto': 'Product',
    'Gestión': 'Management',
    'Soporte': 'Technical Support',
    'Legal': 'Legal',
    'Salud': 'Healthcare',
    'Educación': 'Education',
    'Administración': 'Administration',
    'Atención al Cliente': 'Customer Service',
    'Inteligencia Artificial': 'Artificial Intelligence',
    'Sin categoría': 'Uncategorized',
  };

  static String? translateCategory(String? category, bool isSpanish) {
    if (category == null || category.isEmpty) return category;
    if (isSpanish) return category;

    // Búsqueda exacta
    if (_categoriesEsToEn.containsKey(category)) {
      return _categoriesEsToEn[category]!;
    }

    // Búsqueda insensible a mayúsculas
    for (final entry in _categoriesEsToEn.entries) {
      if (entry.key.toLowerCase() == category.toLowerCase()) {
        return entry.value;
      }
    }

    return category;
  }

  // ── Títulos de Vacantes ───────────────────────────────────────────────────
  static const Map<String, String> _titlesEsToEn = {
    'Ingeniero de Inteligencia Artificial': 'Artificial Intelligence Engineer',
    'Desarrollador Flutter Senior': 'Senior Flutter Developer',
    'Especialista Cloud AWS': 'AWS Cloud Specialist',
    'Diseñador UI/UX': 'UI/UX Designer',
    'Data Scientist Jr': 'Junior Data Scientist',
    'Empresas de tecnología y startups': 'Tech & Startups Software Engineer',
    'Desarrollador Backend': 'Backend Developer',
    'Desarrollador Frontend': 'Frontend Developer',
    'Desarrollador Full Stack': 'Full Stack Developer',
    'Desarrollador Fullstack': 'Full Stack Developer',
    'Desarrollador Móvil': 'Mobile Developer',
    'Ingeniero de Software': 'Software Engineer',
    'Ingeniero de Datos': 'Data Engineer',
    'Ingeniero DevOps': 'DevOps Engineer',
    'Arquitecto Cloud': 'Cloud Architect',
    'Arquitecto de Software': 'Software Architect',
    'Líder Técnico': 'Tech Lead',
    'Gerente de Producto': 'Product Manager',
    'Gerente de Proyecto': 'Project Manager',
    'Analista de Datos': 'Data Analyst',
    'Analista de Ciberseguridad': 'Cybersecurity Analyst',
    'Ingeniero de QA / Testing': 'QA / Testing Engineer',
    'Desarrollador Web': 'Web Developer',
    'Administrador de Sistemas': 'Systems Administrator',
    'Soporte Técnico': 'Technical Support',
  };

  static String translateTitle(String title, bool isSpanish) {
    if (title.isEmpty || isSpanish) return title;

    if (_titlesEsToEn.containsKey(title)) {
      return _titlesEsToEn[title]!;
    }

    for (final entry in _titlesEsToEn.entries) {
      if (entry.key.toLowerCase() == title.toLowerCase()) {
        return entry.value;
      }
    }

    // Sustituciones por patrones comunes
    String translated = title;
    translated = translated.replaceAll(RegExp(r'\bIngeniero(a)? de Inteligencia Artificial\b', caseSensitive: false), 'AI Engineer');
    translated = translated.replaceAll(RegExp(r'\bDesarrollador(a)? de Software\b', caseSensitive: false), 'Software Developer');
    translated = translated.replaceAll(RegExp(r'\bDesarrollador(a)?\b', caseSensitive: false), 'Developer');
    translated = translated.replaceAll(RegExp(r'\bIngeniero(a)? de\b', caseSensitive: false), 'Engineer -');
    translated = translated.replaceAll(RegExp(r'\bIngeniero(a)?\b', caseSensitive: false), 'Engineer');
    translated = translated.replaceAll(RegExp(r'\bDiseñador(a)?\b', caseSensitive: false), 'Designer');
    translated = translated.replaceAll(RegExp(r'\bEspecialista en\b', caseSensitive: false), 'Specialist in');
    translated = translated.replaceAll(RegExp(r'\bEspecialista\b', caseSensitive: false), 'Specialist');
    translated = translated.replaceAll(RegExp(r'\bGerente de\b', caseSensitive: false), 'Manager of');
    translated = translated.replaceAll(RegExp(r'\bLíder de\b', caseSensitive: false), 'Lead of');
    translated = translated.replaceAll(RegExp(r'\bAnalista de\b', caseSensitive: false), 'Analyst of');

    return translated;
  }

  // ── Descripciones de Vacantes ─────────────────────────────────────────────
  static const Map<String, String> _descriptionsEsToEn = {
    'Diseña motores de búsqueda y Match usando Sentence-Transformers para emparejar empresas con candidatos en tiempo récord.':
        'Design search and Match engines using Sentence-Transformers to pair companies with candidates in record time.',

    'Únete para liderar el equipo móvil de TalentMatch. Buscamos experto en animaciones, Haptic Feedback y Riverpod.':
        'Join us to lead TalentMatch\'s mobile team. We are looking for an expert in animations, Haptic Feedback, and Riverpod.',

    'Mantenimiento de instancias EC2, arquitecturas escalables y soporte en crisis cuando los servidores se quedan sin memoria.':
        'Maintenance of EC2 instances, scalable architectures, and incident support when servers run out of memory.',

    'Asegúrate de que nuestra aplicación genere un WOW en los usuarios con diseños fluidos y estéticos.':
        'Ensure our application generates a WOW effect for users with fluid and aesthetic designs.',

    'Analiza las interacciones de los usuarios y mejora los embeddings de nuestra plataforma de reclutamiento.':
        'Analyze user interactions and improve the embeddings of our recruitment platform.',

    'Descripción del trabajo: Buscamos un desarrollador de software para formar parte de un equipo dinámico enfocado en la creación y mejora de soluciones tecnológicas innovadoras. La persona seleccionada participará en el diseño, desarrollo, pruebas y mantenimiento de aplicaciones web y móviles, trabajando en conjunto con otros desarrolladores y áreas de la empresa.':
        'Job Description: We are looking for a software developer to join a dynamic team focused on creating and improving innovative technology solutions. The selected person will participate in the design, development, testing, and maintenance of web and mobile applications, collaborating with fellow developers and company departments.',

    'Buscamos un desarrollador experto en Python y bases de datos para unirse a nuestro equipo. El candidato ideal tiene experiencia con Fastapi.':
        'We are looking for an expert Python and database developer to join our team. The ideal candidate has experience with FastAPI.',

    'Buscamos desarrollador Frontend con experiencia en diseño de interfaces y componentes.':
        'We are looking for a Frontend developer with experience in interface and component design.',
  };

  static String translateDescription(String description, bool isSpanish) {
    if (description.isEmpty || isSpanish) return description;

    // Coincidencia exacta
    final trimmed = description.trim();
    if (_descriptionsEsToEn.containsKey(trimmed)) {
      return _descriptionsEsToEn[trimmed]!;
    }

    // Coincidencia normalizada
    for (final entry in _descriptionsEsToEn.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }

    // Reemplazos de frases comunes para descripciones dinámicas
    String result = description;
    result = result.replaceAll('Descripción del trabajo:', 'Job Description:');
    result = result.replaceAll('Buscamos un desarrollador de software para formar parte de un equipo dinámico', 'We are looking for a software developer to join a dynamic team');
    result = result.replaceAll('Buscamos un desarrollador experto en', 'We are looking for an expert developer in');
    result = result.replaceAll('Buscamos un desarrollador', 'We are looking for a developer');
    result = result.replaceAll('Buscamos desarrollador', 'We are looking for a developer');
    result = result.replaceAll('Buscamos ', 'We are looking for ');
    result = result.replaceAll('Únete para liderar', 'Join us to lead');
    result = result.replaceAll('Únete a nuestro equipo', 'Join our team');
    result = result.replaceAll('en tiempo récord', 'in record time');
    result = result.replaceAll('bases de datos', 'databases');
    result = result.replaceAll('aplicaciones web y móviles', 'web and mobile applications');
    result = result.replaceAll('trabajando en conjunto con', 'working alongside');
    result = result.replaceAll('para unirse a nuestro equipo', 'to join our team');

    return result;
  }

  // ── Requisitos ────────────────────────────────────────────────────────────
  static const Map<String, String> _requirementsEsToEn = {
    'Conocimientos en Java, Python, JavaScript o Dart. Manejo de bases de datos SQL y NoSQL. Conocimiento':
        'Knowledge of Java, Python, JavaScript, or Dart. SQL and NoSQL database management.',
    'Diseño Centrado en el Usuario': 'User-Centered Design',
    'Trabajo en equipo': 'Teamwork',
    'Resolución de problemas': 'Problem solving',
    'Comunicación asertiva': 'Effective communication',
    'Liderazgo': 'Leadership',
    'Pensamiento crítico': 'Critical thinking',
    'Proactivo': 'Proactive',
    'Proactiva': 'Proactive',
    'Disponibilidad inmediata': 'Immediate availability',
    'Nivel de inglés avanzado': 'Advanced English level',
    'Nivel de inglés intermedio': 'Intermediate English level',
    'Nivel de inglés conversacional': 'Conversational English',
    'Experiencia de 4+ años': '4+ years of experience',
    'Experiencia de 2 años': '2 years of experience',
    'Experiencia de 3 años': '3 years of experience',
    'Experiencia de 5 años': '5 years of experience',
  };

  static List<String> translateRequirements(List<String> requirements, bool isSpanish) {
    if (requirements.isEmpty || isSpanish) return requirements;

    return requirements.map((req) {
      final trimmed = req.trim();
      if (_requirementsEsToEn.containsKey(trimmed)) {
        return _requirementsEsToEn[trimmed]!;
      }

      // Regex para "Experiencia de X años"
      final expMatch = RegExp(r'^Experiencia de (\d+)\+? años?$', caseSensitive: false).firstMatch(trimmed);
      if (expMatch != null) {
        return '${expMatch.group(1)}+ years of experience';
      }

      // Regex para "Conocimientos en X"
      if (trimmed.toLowerCase().startsWith('conocimientos en ')) {
        return 'Knowledge of ${trimmed.substring(17)}';
      }

      // Regex para "Manejo de X"
      if (trimmed.toLowerCase().startsWith('manejo de ')) {
        return 'Proficiency in ${trimmed.substring(10)}';
      }

      return req;
    }).toList();
  }

  // ── Ubicación ─────────────────────────────────────────────────────────────
  static String translateLocation(String location, bool isSpanish) {
    if (location.isEmpty || isSpanish) return location;

    final trimmed = location.trim();
    if (trimmed.toLowerCase() == 'remoto') return 'Remote';
    if (trimmed.toLowerCase() == 'híbrido' || trimmed.toLowerCase() == 'hibrido') return 'Hybrid';
    if (trimmed.toLowerCase() == 'presencial' || trimmed.toLowerCase() == 'en sitio') return 'On-site';

    // Para ciudades colombianas, adaptamos de forma bilingüe limpia
    String res = location;
    res = res.replaceAll('Medellín, Antioquia', 'Medellin, Colombia');
    res = res.replaceAll('Bogotá, Colombia', 'Bogota, Colombia');
    res = res.replaceAll('Cali, Valle del Cauca', 'Cali, Colombia');
    res = res.replaceAll('Barranquilla, Atlántico', 'Barranquilla, Colombia');
    res = res.replaceAll('Bucaramanga, Santander', 'Bucaramanga, Colombia');
    res = res.replaceAll('Fusagasugá, Cundinamarca', 'Fusagasuga, Colombia');

    return res;
  }

  // ── Explicaciones IA (Recomendaciones) ────────────────────────────────────
  static String translateExplanation(String explanation, bool isSpanish) {
    if (explanation.isEmpty || isSpanish) return explanation;

    final trimmed = explanation.trim();

    if (trimmed.startsWith('Habilidades coincidentes:')) {
      return trimmed.replaceFirst('Habilidades coincidentes:', 'Matching skills:');
    }
    if (trimmed.contains('Alta compatibilidad con tu perfil')) {
      return trimmed.replaceAll('Alta compatibilidad con tu perfil', 'High match with your profile');
    }
    if (trimmed.contains('Coincidencia semántica con')) {
      return trimmed.replaceAll('Coincidencia semántica con', 'Semantic match with');
    }
    if (trimmed.contains('Fuerte afinidad semántica con tus habilidades')) {
      return trimmed.replaceAll('Fuerte afinidad semántica con tus habilidades', 'Strong semantic match with your skills');
    }
    if (trimmed.contains('Perfil recomendado por afinidad técnica en IA y ML')) {
      return 'Recommended profile based on technical affinity in AI & ML';
    }

    return explanation;
  }
}
