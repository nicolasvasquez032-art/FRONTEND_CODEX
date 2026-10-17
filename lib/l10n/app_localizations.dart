import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'TalentMatch'**
  String get appTitle;

  /// No description provided for @appSlogan.
  ///
  /// In es, this message translates to:
  /// **'Empleo inteligente para tu futuro'**
  String get appSlogan;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get commonAccept;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonSuccess.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get commonSuccess;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get requiredField;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get navExplore;

  /// No description provided for @navVacancies.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get navVacancies;

  /// No description provided for @navApplications.
  ///
  /// In es, this message translates to:
  /// **'Postulaciones'**
  String get navApplications;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navCompanyMyJobs.
  ///
  /// In es, this message translates to:
  /// **'Mis Vacantes'**
  String get navCompanyMyJobs;

  /// No description provided for @navCompanyPublish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get navCompanyPublish;

  /// No description provided for @navCompanyProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Empresa'**
  String get navCompanyProfile;

  /// No description provided for @homeRecommendationsBadge.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones para ti'**
  String get homeRecommendationsBadge;

  /// No description provided for @homeFindYour.
  ///
  /// In es, this message translates to:
  /// **'Encuentra Tu\n'**
  String get homeFindYour;

  /// No description provided for @homeIdealJob.
  ///
  /// In es, this message translates to:
  /// **'Trabajo Ideal'**
  String get homeIdealJob;

  /// No description provided for @homeSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Cargo, habilidad o empresa...'**
  String get homeSearchHint;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas →'**
  String get homeSeeAll;

  /// No description provided for @homeAiBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones más inteligentes'**
  String get homeAiBannerTitle;

  /// No description provided for @homeAiBannerDesc.
  ///
  /// In es, this message translates to:
  /// **'Analizamos tu perfil y las ofertas para encontrar coincidencias semánticas, no solo palabras clave.'**
  String get homeAiBannerDesc;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginButton;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In es, this message translates to:
  /// **'O continuar con'**
  String get loginOrContinueWith;

  /// No description provided for @loginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get loginGoogle;

  /// No description provided for @loginLinkedIn.
  ///
  /// In es, this message translates to:
  /// **'LinkedIn'**
  String get loginLinkedIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginCreateAccount;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo inválido'**
  String get loginInvalidEmail;

  /// No description provided for @loginPasswordMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get loginPasswordMinLength;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a TalentMatch y conecta con las mejores oportunidades'**
  String get registerSubtitle;

  /// No description provided for @registerCandidateTab.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get registerCandidateTab;

  /// No description provided for @registerCompanyTab.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get registerCompanyTab;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get registerFullNameLabel;

  /// No description provided for @registerFullNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Pérez'**
  String get registerFullNameHint;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Crear mi cuenta'**
  String get registerButton;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerPasswordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get registerPasswordsDoNotMatch;

  /// No description provided for @registerStepTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil profesional'**
  String get registerStepTitle;

  /// No description provided for @registerCandidateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Primero, tus datos de acceso'**
  String get registerCandidateSubtitle;

  /// No description provided for @registerCompanySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tu empresa para publicar vacantes'**
  String get registerCompanySubtitle;

  /// No description provided for @registerProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos sobre ti para mejores recomendaciones'**
  String get registerProfileSubtitle;

  /// No description provided for @registerContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get registerContinue;

  /// No description provided for @registerCompanyButton.
  ///
  /// In es, this message translates to:
  /// **'Registrar Empresa'**
  String get registerCompanyButton;

  /// No description provided for @registerOrWith.
  ///
  /// In es, this message translates to:
  /// **'O registrarse con'**
  String get registerOrWith;

  /// No description provided for @registerLocationLabel.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get registerLocationLabel;

  /// No description provided for @registerSkillsLabel.
  ///
  /// In es, this message translates to:
  /// **'Habilidades (separadas por coma)'**
  String get registerSkillsLabel;

  /// No description provided for @registerExperienceYearsLabel.
  ///
  /// In es, this message translates to:
  /// **'Años de experiencia'**
  String get registerExperienceYearsLabel;

  /// No description provided for @registerEducationLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel educativo'**
  String get registerEducationLabel;

  /// No description provided for @registerSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada exitosamente. Por favor inicia sesión.'**
  String get registerSuccessMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo para recibir un enlace de recuperación.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get forgotPasswordButton;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In es, this message translates to:
  /// **'Si el correo está registrado, recibirás un enlace en breve.'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Listo!'**
  String get forgotPasswordSuccessTitle;

  /// No description provided for @forgotPasswordSuccessDesc.
  ///
  /// In es, this message translates to:
  /// **'Si el correo está registrado, recibirás un enlace de recuperación en los próximos minutos.'**
  String get forgotPasswordSuccessDesc;

  /// No description provided for @forgotPasswordEnterValidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido.'**
  String get forgotPasswordEnterValidEmail;

  /// No description provided for @vacanciesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar vacantes, cargos o habilidades...'**
  String get vacanciesSearchHint;

  /// No description provided for @vacanciesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay vacantes disponibles en este momento'**
  String get vacanciesEmpty;

  /// No description provided for @vacanciesSalary.
  ///
  /// In es, this message translates to:
  /// **'Salario'**
  String get vacanciesSalary;

  /// No description provided for @vacanciesLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get vacanciesLocation;

  /// No description provided for @vacanciesApplyButton.
  ///
  /// In es, this message translates to:
  /// **'Postularme ahora'**
  String get vacanciesApplyButton;

  /// No description provided for @vacanciesAlreadyApplied.
  ///
  /// In es, this message translates to:
  /// **'Ya te has postulado'**
  String get vacanciesAlreadyApplied;

  /// No description provided for @vacanciesMatchScore.
  ///
  /// In es, this message translates to:
  /// **'Compatibilidad IA'**
  String get vacanciesMatchScore;

  /// No description provided for @vacanciesRequirements.
  ///
  /// In es, this message translates to:
  /// **'Requisitos del puesto'**
  String get vacanciesRequirements;

  /// No description provided for @vacanciesDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción de la vacante'**
  String get vacanciesDescription;

  /// No description provided for @applicationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Postulaciones'**
  String get applicationsTitle;

  /// No description provided for @applicationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no te has postulado a ninguna vacante'**
  String get applicationsEmpty;

  /// No description provided for @applicationsStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get applicationsStatus;

  /// No description provided for @statusReview.
  ///
  /// In es, this message translates to:
  /// **'Postulado'**
  String get statusReview;

  /// No description provided for @statusInterview.
  ///
  /// In es, this message translates to:
  /// **'Entrevista'**
  String get statusInterview;

  /// No description provided for @statusRejected.
  ///
  /// In es, this message translates to:
  /// **'No seleccionado'**
  String get statusRejected;

  /// No description provided for @statusHired.
  ///
  /// In es, this message translates to:
  /// **'Contratado'**
  String get statusHired;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEdit;

  /// No description provided for @profileSkills.
  ///
  /// In es, this message translates to:
  /// **'Habilidades técnicas'**
  String get profileSkills;

  /// No description provided for @profileExperience.
  ///
  /// In es, this message translates to:
  /// **'Años de experiencia'**
  String get profileExperience;

  /// No description provided for @profileEducation.
  ///
  /// In es, this message translates to:
  /// **'Educación'**
  String get profileEducation;

  /// No description provided for @profileUploadCV.
  ///
  /// In es, this message translates to:
  /// **'Subir Hoja de Vida (PDF)'**
  String get profileUploadCV;

  /// No description provided for @profileCVUploaded.
  ///
  /// In es, this message translates to:
  /// **'Hoja de vida cargada correctamente'**
  String get profileCVUploaded;

  /// No description provided for @profileLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la aplicación'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get profileLanguageSpanish;

  /// No description provided for @profileLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get profileLanguageEnglish;

  /// No description provided for @profileStatsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get profileStatsCompleted;

  /// No description provided for @profileStatsApplications.
  ///
  /// In es, this message translates to:
  /// **'Postulaciones'**
  String get profileStatsApplications;

  /// No description provided for @profileStatsViews.
  ///
  /// In es, this message translates to:
  /// **'Vistas'**
  String get profileStatsViews;

  /// No description provided for @profilePersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get profilePersonalData;

  /// No description provided for @profilePersonalDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Información básica de contacto'**
  String get profilePersonalDataSubtitle;

  /// No description provided for @profileExperienceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tu historial laboral'**
  String get profileExperienceSubtitle;

  /// No description provided for @profileEducationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estudios y certificaciones'**
  String get profileEducationSubtitle;

  /// No description provided for @profileSkillsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Destaca tus conocimientos'**
  String get profileSkillsSubtitle;

  /// No description provided for @profileSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profileSettings;

  /// No description provided for @profileHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y Soporte'**
  String get profileHelp;

  /// No description provided for @profileCandidateRole.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get profileCandidateRole;

  /// No description provided for @profileSelectLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Idioma'**
  String get profileSelectLanguageTitle;

  /// No description provided for @chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes conversaciones activas'**
  String get chatEmpty;

  /// No description provided for @chatTypeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatTypeMessage;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones pendientes'**
  String get notificationsEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
