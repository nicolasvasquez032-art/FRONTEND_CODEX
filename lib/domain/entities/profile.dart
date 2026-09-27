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

  const Profile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.skills,
    required this.experienceYears,
    this.location,
    this.education,
    this.cvText,
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
      );
}
