/// Perfil del candidato tal como lo devuelve el backend.
class Profile {
  final String id;
  final String userId;
  final String fullName;
  final List<String> skills;
  final int experienceYears;
  final String? location;
  final String? education;
  final String? cvText;
  final String? phone;
  final String? portfolioUrl;
  final String? aboutMe;
  final String? jobTitle;

  const Profile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.skills,
    required this.experienceYears,
    this.location,
    this.education,
    this.cvText,
    this.phone,
    this.portfolioUrl,
    this.aboutMe,
    this.jobTitle,
  });

  /// Inicial del nombre para el avatar.
  String get initial => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  Profile copyWith({
    String? fullName,
    List<String>? skills,
    int? experienceYears,
    String? location,
    String? education,
    String? cvText,
    String? phone,
    String? portfolioUrl,
    String? aboutMe,
    String? jobTitle,
  }) =>
      Profile(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        skills: skills ?? this.skills,
        experienceYears: experienceYears ?? this.experienceYears,
        location: location ?? this.location,
        education: education ?? this.education,
        cvText: cvText ?? this.cvText,
        phone: phone ?? this.phone,
        portfolioUrl: portfolioUrl ?? this.portfolioUrl,
        aboutMe: aboutMe ?? this.aboutMe,
        jobTitle: jobTitle ?? this.jobTitle,
      );
}
