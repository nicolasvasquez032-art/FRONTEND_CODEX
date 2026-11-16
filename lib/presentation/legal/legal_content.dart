// Contenido y marco legal de TalentMatch conforme a la legislación de la República de Colombia
// (Ley Estatutaria 1581 de 2012, Decreto 1377 de 2013, Ley 527 de 1999, Ley 1480 de 2011,
// Código Sustantivo del Trabajo y convenios de la OIT).

class LegalSectionItem {
  final String title;
  final String content;
  final List<String> bullets;
  final String? alertNotice;

  const LegalSectionItem({
    required this.title,
    required this.content,
    this.bullets = const [],
    this.alertNotice,
  });
}

class LegalContentData {
  LegalContentData._();

  // ═══════════════════════════════════════════════════════════════════════════
  // TÉRMINOS Y CONDICIONES (ESPAÑOL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<LegalSectionItem> termsSectionsEs = [
    LegalSectionItem(
      title: '1. Objeto y Aceptación de los Términos',
      content:
          'Los presentes Términos y Condiciones regulan el acceso, navegación y uso de la plataforma digital TalentMatch (aplicación móvil y web), operada conforme al ordenamiento jurídico de la República de Colombia (Ley 527 de 1999 de Comercio Electrónico y Ley 1480 de 2011 Estatuto del Consumidor).\n\nAl registrar una cuenta, pulsar "Acepto" o utilizar cualquiera de las herramientas del sistema, usted declara ser legalmente capaz y acepta someterse de manera íntegra, expresa y sin reservas a las presentes condiciones.',
      alertNotice:
          'Contrato de adhesión vinculante. Si no está de acuerdo con alguno de los términos, absténgase de utilizar la plataforma.',
    ),
    LegalSectionItem(
      title: '2. Naturaleza del Servicio de Intermediación Digital',
      content:
          'TalentMatch es un ecosistema tecnológico diseñado para optimizar el encuentro entre personas naturales que buscan oportunidades laborales ("Candidatos") y personas jurídicas o empleadores que ofrecen puestos de trabajo ("Empresas").',
      bullets: [
        'TalentMatch opera exclusivamente como canal tecnológico de intermediación e inteligencia algorítmica.',
        'TalentMatch NO es empleador, subcontratista, ni agencia de colocación laboral con cobro al trabajador.',
        'La relación contractual, laboral o de prestación de servicios se formaliza de manera exclusiva y autónoma entre la Empresa contratante y el Candidato seleccionado.',
      ],
    ),
    LegalSectionItem(
      title: '3. Principio de Gratuidad Estricta para Candidatos',
      content:
          'En observancia estricta del Convenio 181 de la Organización Internacional del Trabajo (OIT) y los preceptos laborales de Colombia, TalentMatch ratifica la total gratuidad para los Candidatos.',
      bullets: [
        'El registro de la cuenta, la creación del perfil profesional, la carga del currículum (CV) y la postulación ilimitada a vacantes son y serán siempre 100% gratuitos.',
        'Queda TERMINANTEMENTE PROHIBIDO que cualquier Empresa o reclutador solicite dinero, comisiones o pagos a los postulantes por exámenes de ingreso, pruebas técnicas o trámites de selección (en virtud del Art. 348 del Código Sustantivo del Trabajo y la Resolución 2346 de 2007).',
        'Cualquier requerimiento de cobro a un candidato acarreará la expulsión inmediata de la Empresa y la denuncia ante el Ministerio del Trabajo.',
      ],
      alertNotice:
          'Regla Cero Cobro: Ninguna vacante en TalentMatch puede exigir pagos al candidato. Reporte cualquier irregularidad de inmediato.',
    ),
    LegalSectionItem(
      title: '4. Deberes y Obligaciones de las Empresas',
      content:
          'Las cuentas registradas bajo la modalidad Empresa asumen el compromiso de actuar bajo los más altos estándares de transparencia y legalidad:',
      bullets: [
        'Publicar únicamente vacantes verídicas, claras, con condiciones salariales dignas y acordes a la ley colombiana.',
        'Principio de No Discriminación: Cumplir con el Artículo 13 de la Constitución Política. Se prohíben ofertas con sesgos injustificados de género, edad, raza, religión, estado civil, orientación sexual o ideología política.',
        'Uso confidencial de la información: Los datos, currículums y contactos recibidos de los candidatos solo podrán emplearse para la evaluación de la vacante específica y bajo autorización de Habeas Data.',
        'Respeto en comunicaciones: Brindar retroalimentación oportuna y trato respetuoso a los postulados.',
      ],
    ),
    LegalSectionItem(
      title: '5. Deberes y Obligaciones de los Candidatos',
      content:
          'Los usuarios postulantes se comprometen a un uso honesto y profesional de la plataforma:',
      bullets: [
        'Garantizar la autenticidad y veracidad de la información consignada en su perfil, títulos académicos, experiencia y hoja de vida.',
        'No suplantar la identidad de terceros ni suministrar documentos falsos o adulterados.',
        'Asistir puntualmente a las entrevistas acordadas o notificar con debida anticipación cualquier imposibilidad.',
      ],
    ),
    LegalSectionItem(
      title: '6. Inteligencia Artificial y Sistema "Match Score"',
      content:
          'TalentMatch incorpora algoritmos de Inteligencia Artificial para analizar requisitos técnicos, habilidades y experiencia, calculando un porcentaje estimativo de compatibilidad denominado "Match Score".',
      bullets: [
        'El Match Score constituye una herramienta meramente orientativa y de apoyo computacional.',
        'No constituye una decisión automatizada vinculante ni discriminatoria.',
        'La evaluación final, convocatoria y decisión de contratación depende única y exclusivamente del criterio humano de la Empresa empleadora.',
      ],
    ),
    LegalSectionItem(
      title: '7. Uso de Canales de Comunicación (Chat y Videollamadas)',
      content:
          'Los módulos integrados de mensajería instantánea y salas de entrevista virtual están sujetos a reglas estrictas de convivencia:',
      bullets: [
        'Uso estrictamente laboral: Queda prohibido el uso para fines comerciales no autorizados, spam o actividades de índole personal ajenas a la selección.',
        'Cero tolerancia al acoso: Prohibición absoluta de acoso laboral (Ley 1010 de 2006), hostigamiento verbal o sexual, violencia de género o amenazas.',
        'Cifrado y seguridad: Las comunicaciones se transmiten mediante protocolos seguros (WebRTC / TLS). Las videollamadas no se graban sin previo aviso y autorización.',
      ],
      alertNotice:
          'Cualquier conducta indebida en el chat o videollamada causará el bloqueo preventivo y definitivo de la cuenta.',
    ),
    LegalSectionItem(
      title: '8. Modelos de Suscripción y Planes para Empresas',
      content:
          'TalentMatch ofrece a las empresas un "Plan Gratuito" base para iniciar la publicación de vacantes, así como planes avanzados ("Plan Pro / Premium") con herramientas de analítica predictiva y mayor capacidad operativa. Las tarifas vigentes se informarán de manera transparente previo a cualquier cobro, sin cargos ocultos.',
    ),
    LegalSectionItem(
      title: '9. Propiedad Intelectual y Licencia de Uso',
      content:
          'Todos los derechos sobre el software TalentMatch, marcas registradas, logotipos, código fuente, algoritmos, arquitectura e interfaz gráfica pertenecen exclusivamente a los titulares de TalentMatch. Se otorga al usuario una licencia personal, revocable, no exclusiva e intransferible para el uso de la aplicación conforme a estos términos.',
    ),
    LegalSectionItem(
      title: '10. Limitación de Responsabilidad y Ley Aplicable',
      content:
          'TalentMatch no garantiza el éxito de contratación ni asume responsabilidad por acuerdos individuales o disputas entre candidatos y empleadores. Este contrato se rige íntegramente por las leyes de la República de Colombia. Cualquier controversia se someterá a la jurisdicción de los juzgados y tribunales competentes de la ciudad de Bogotá D.C.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // POLÍTICA DE PRIVACIDAD Y HABEAS DATA - LEY 1581 DE 2012 (ESPAÑOL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<LegalSectionItem> privacySectionsEs = [
    LegalSectionItem(
      title: '1. Marco Legal y Compromiso de Protección de Datos',
      content:
          'La presente Política de Tratamiento de Datos Personales se formula en estricto cumplimiento del Artículo 15 de la Constitución Política de Colombia, la Ley Estatutaria 1581 de 2012 (Régimen General de Protección de Datos Personales), el Decreto Reglamentario 1377 de 2013, el Decreto Único 1074 de 2015 y las directrices expedidas por la Superintendencia de Industria y Comercio (SIC).\n\nTalentMatch garantiza la seguridad, transparencia, confidencialidad y libre ejercicio de los derechos de Habeas Data de todos los titulares registrados.',
      alertNotice:
          'Cumplimiento oficial: Ley Estatutaria 1581 de 2012 de la República de Colombia (Habeas Data).',
    ),
    LegalSectionItem(
      title: '2. Responsable del Tratamiento y Canales de Atención',
      content:
          'El Responsable del tratamiento de sus datos personales es TalentMatch Colombia.\n\nPara el ejercicio de sus derechos de consulta, actualización, rectificación o supresión de datos, ponemos a su disposición el canal oficial de Habeas Data:\n• Correo electrónico: privacidad@talentmatch.com\n• Área encargada: Oficial de Cumplimiento y Privacidad de Datos',
    ),
    LegalSectionItem(
      title: '3. Datos Personales Objeto de Tratamiento',
      content:
          'Para el funcionamiento idóneo de los servicios, TalentMatch recolecta y almacena los siguientes datos:',
      bullets: [
        'Candidatos: Nombre completo, correo electrónico, número telefónico, ubicación territorial (departamento y municipio), formación académica, certificaciones, experiencia laboral, habilidades técnicas, archivo digital de la hoja de vida (PDF/imagen) y preferencias laborales.',
        'Empresas: Razón social, identificación tributaria (NIT), correo corporativo, ubicación, sector económico, tamaño empresarial, sitio web y logotipo.',
        'Datos Técnicos: Dirección IP, registros de conexión (logs), información de dispositivo y tokens criptográficos de sesión.',
      ],
    ),
    LegalSectionItem(
      title: '4. Finalidades Legítimas del Tratamiento',
      content:
          'Los datos personales suministrados serán tratados exclusivamente para las siguientes finalidades debidamente autorizadas:',
      bullets: [
        'Crear, validar y gestionar su cuenta de usuario y credenciales de acceso seguro.',
        'Gestionar la intermediación laboral: habilitar la visualización del perfil profesional y CV por parte de las empresas a cuyas vacantes el candidato se postule voluntariamente.',
        'Ejecutar modelos de Inteligencia Artificial para el cálculo de compatibilidad técnica (Match Score) y sugerencia de oportunidades laborales afines.',
        'Habilitar canales de interacción directa: mensajería en tiempo real y enlaces de videollamadas para entrevistas.',
        'Enviar notificaciones operativas (cambios de estado en su postulación, invitaciones a entrevistas, alertas de seguridad).',
        'Cumplir con requerimientos legales o de autoridades judiciales y administrativas competentes.',
      ],
    ),
    LegalSectionItem(
      title: '5. Datos Sensibles y Protección de Menores',
      content:
          'TalentMatch respeta rigurosamente las disposiciones sobre categorías especiales de datos:',
      bullets: [
        'Datos Sensibles: No se condiciona el servicio a la entrega de datos sobre convicciones religiosas, orientación sexual, filiación política, salud o datos biométricos. En las videollamadas, la transmisión de voz y video es cifrada y no se graba sin autorización expresa previa.',
        'Menores de edad: La plataforma está destinada primordialmente a personas mayores de 18 años. Los adolescentes mayores de 15 años podrán postularse en los términos contemplados por el Código de la Infancia y la Adolescencia (Ley 1098 de 2006) y con las autorizaciones legales vigentes.',
      ],
    ),
    LegalSectionItem(
      title: '6. Derechos de los Titulares (Derechos ARCO)',
      content:
          'De conformidad con el Artículo 8 de la Ley 1581 de 2012, usted como titular de datos personales tiene derecho a:',
      bullets: [
        'a) Conocer, actualizar y rectificar sus datos personales frente a TalentMatch.',
        'b) Solicitar prueba de la autorización otorgada.',
        'c) Ser informado del uso específico que se le ha dado a sus datos.',
        'd) Presentar quejas ante la Superintendencia de Industria y Comercio (SIC) por infracciones a la ley.',
        'e) Revocar la autorización y/o solicitar la supresión del dato (Derecho al Olvido) cuando no exista un deber legal o contractual de permanencia.',
        'f) Acceder de forma gratuita a sus datos personales objeto de tratamiento.',
      ],
    ),
    LegalSectionItem(
      title: '7. Procedimiento para el Ejercicio de sus Derechos (PQR)',
      content:
          'Para tramitar cualquier consulta, solicitud o reclamo de Habeas Data:',
      bullets: [
        'Envíe su petición al correo privacidad@talentmatch.com indicando su nombre, número de documento, correo registrado y el motivo claro de su solicitud.',
        'Plazo de Consultas: Las solicitudes de información sobre sus datos se resolverán en un término máximo de diez (10) días hábiles.',
        'Plazo de Reclamos y Supresión: Las peticiones de corrección o eliminación de cuenta y datos se resolverán en un plazo máximo de quince (15) días hábiles, de acuerdo con el Art. 15 de la Ley 1581 de 2012.',
      ],
    ),
    LegalSectionItem(
      title: '8. Medidas de Seguridad de la Información',
      content:
          'TalentMatch adopta estrictas medidas de seguridad técnicas, humanas y administrativas para salvaguardar sus datos:',
      bullets: [
        'Cifrado en tránsito mediante protocolos TLS 1.3 / HTTPS de última generación.',
        'Contraseñas procesadas con algoritmos de hashing criptográfico unidireccional (bcrypt), inaccesibles para el personal de la empresa.',
        'Tokens de sesión JWT cifrados en almacenamiento seguro del dispositivo (SecureStorage).',
        'Infraestructura en la nube con altos estándares de seguridad (AWS Cloud) y monitoreo de intrusiones.',
      ],
    ),
    LegalSectionItem(
      title: '9. Transferencia y Transmisión Internacional de Datos',
      content:
          'El usuario autoriza expresamente que los datos puedan ser almacenados y procesados en centros de datos seguros ubicados en servidores de nube internacional (como Amazon Web Services), los cuales cumplen con estándares internacionales de seguridad de la información (ISO/IEC 27001, SOC 2) y niveles adecuados de protección conforme a la regulación de la SIC.',
    ),
    LegalSectionItem(
      title: '10. Vigencia de las Bases de Datos',
      content:
          'Las bases de datos tendrán una vigencia equivalente al tiempo durante el cual se mantenga activa la cuenta del usuario y por el término que resulte necesario para el cumplimiento de las obligaciones legales o la prescripción de acciones contractuales y laborales.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // POLÍTICA DE COOKIES Y ALMACENAMIENTO SEGURO (ESPAÑOL)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<LegalSectionItem> cookiesSectionsEs = [
    LegalSectionItem(
      title: '1. Qué son las Tecnologías de Almacenamiento Local',
      content:
          'TalentMatch utiliza almacenamiento local seguro en el dispositivo móvil y en el navegador web (como SharedPreferences, SecureStorage y tokens criptográficos) con fines estrictamente técnicos, operativos y de seguridad.',
    ),
    LegalSectionItem(
      title: '2. Finalidades de Uso en TalentMatch',
      content:
          'Estas tecnologías se emplean con propósitos funcionales y no para seguimiento invasivo publicitario:',
      bullets: [
        'Autenticación: Mantener abierta la sesión del usuario de forma cifrada mediante tokens JWT temporales.',
        'Preferencias de Experiencia: Guardar el idioma seleccionado (Español / Inglés) y ajustes visuales de la aplicación.',
        'Rendimiento y Red: Almacenar en caché local temporal listas de vacantes para optimizar el consumo de datos móviles y la velocidad de carga.',
      ],
    ),
    LegalSectionItem(
      title: '3. Control por el Usuario',
      content:
          'Al cerrar sesión formalmente desde el menú de perfil, los tokens de autenticación son eliminados de inmediato del almacenamiento seguro de su dispositivo. El usuario puede además limpiar la memoria caché de la aplicación en cualquier momento desde los ajustes de su sistema operativo.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGLISH VERSIONS (FOR ADAPTIVE LOCALIZATION)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<LegalSectionItem> termsSectionsEn = [
    LegalSectionItem(
      title: '1. Purpose & Acceptance of Terms',
      content:
          'These Terms and Conditions govern the access, browsing, and use of the TalentMatch digital platform (mobile app and web), operated in compliance with the legal framework of the Republic of Colombia (Electronic Commerce Law 527/1999 and Consumer Statute Law 1480/2011).\n\nBy registering an account, clicking "I Agree", or using any service feature, you declare that you are of legal age and expressly accept all terms without reservation.',
      alertNotice:
          'Binding agreement. If you do not agree with any part of these terms, please refrain from using the platform.',
    ),
    LegalSectionItem(
      title: '2. Nature of Digital Matching Service',
      content:
          'TalentMatch connects job seekers ("Candidates") with employers offering employment opportunities ("Companies").',
      bullets: [
        'TalentMatch acts exclusively as a technology bridge and algorithmic recommendation system.',
        'TalentMatch is NOT an employer, subcontractor, or employment agency charging candidates.',
        'The contractual, labor, or service relationship is formed exclusively and autonomously between the hiring Company and the candidate.',
      ],
    ),
    LegalSectionItem(
      title: '3. Zero Fee Guarantee for Candidates',
      content:
          'In strict compliance with ILO Convention 181 and Colombian labor law, TalentMatch guarantees 100% free access for Candidates.',
      bullets: [
        'Account registration, profile creation, CV upload, and unlimited job applications are completely free.',
        'Companies and recruiters are STRICTLY PROHIBITED from requesting money or fees from applicants for medical checkups, exams, or selection procedures (Colombian Labor Code Art. 348 and Resolution 2346/2007).',
        'Any violation results in immediate company account termination and referral to labor authorities.',
      ],
      alertNotice:
          'Zero-Fee Policy: No job vacancy in TalentMatch can ever demand payments from candidates.',
    ),
    LegalSectionItem(
      title: '4. Obligations of Companies',
      content:
          'Companies agree to publish genuine vacancies with fair wages, adhere to non-discrimination principles under Article 13 of the Colombian Constitution, and handle applicant CVs strictly for hiring purposes.',
    ),
    LegalSectionItem(
      title: '5. AI Matching & Score Transparency',
      content:
          'The AI Match Score is an assistive computational affinity percentage based on technical requirements and skills. It does not constitute a legally binding or discriminatory automated decision; all hiring choices remain human.',
    ),
    LegalSectionItem(
      title: '6. Communication & Video Call Rules',
      content:
          'Chat and video calls are strictly professional. Any form of harassment, discrimination, or abusive conduct results in immediate ban. Communications are encrypted (WebRTC/TLS) and not recorded without prior consent.',
    ),
    LegalSectionItem(
      title: '7. Governing Law & Jurisdiction',
      content:
          'These Terms are governed by the laws of the Republic of Colombia. Any dispute shall be submitted to the competent courts of Bogotá D.C.',
    ),
  ];

  static const List<LegalSectionItem> privacySectionsEn = [
    LegalSectionItem(
      title: '1. Legal Framework (Colombian Statutory Law 1581 of 2012)',
      content:
          'This Privacy Policy complies with Article 15 of the Colombian Constitution, Statutory Law 1581 of 2012 (General Personal Data Protection Regime), and Regulatory Decrees 1377 of 2013 and 1074 of 2015.\n\nTalentMatch guarantees confidentiality, security, and full respect for your Habeas Data rights.',
      alertNotice:
          'Official compliance: Republic of Colombia Statutory Law 1581 of 2012 (Habeas Data).',
    ),
    LegalSectionItem(
      title: '2. Data Controller & Privacy Officer',
      content:
          'The data controller is TalentMatch Colombia. You can exercise your rights by contacting our official privacy channel:\n• Email: privacidad@talentmatch.com',
    ),
    LegalSectionItem(
      title: '3. Data Collected & Legitimate Purposes',
      content:
          'We collect candidate contact info, CV, skills, education, and company corporate details solely for account authentication, job matching, AI compatibility scoring, direct interview communication, and legal compliance.',
    ),
    LegalSectionItem(
      title: '4. User Rights (ARCO & Habeas Data)',
      content:
          'Under Article 8 of Law 1581 of 2012, you have the right to know, update, rectify, and request deletion (Right to be Forgotten) of your personal data, or file complaints before the Superintendency of Industry and Commerce (SIC).',
    ),
    LegalSectionItem(
      title: '5. Security & International Cloud Hosting',
      content:
          'We apply TLS 1.3 / HTTPS encryption, one-way bcrypt password hashing, encrypted JWT tokens, and secure AWS Cloud infrastructure adhering to ISO 27001 standards.',
    ),
  ];

  static const List<LegalSectionItem> cookiesSectionsEn = [
    LegalSectionItem(
      title: '1. Local Storage Technologies',
      content:
          'TalentMatch uses secure local storage (SharedPreferences and SecureStorage) strictly for authentication tokens, language preferences, and performance caching, never for third-party ad tracking.',
    ),
  ];
}
