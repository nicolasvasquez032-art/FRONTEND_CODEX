import '../../domain/entities/profile.dart';

/// DTO que mapea la respuesta JSON de POST /auth/registro/candidato
/// y GET /perfiles/{id} al dominio.
class ProfileModel extends Profile {
  ProfileModel({
    required super.id,
    required super.userId,
    required super.fullName,
    required super.skills,
    required super.experienceYears,
    super.location,
    super.education,
    super.cvText,
    super.phone,
    super.portfolioUrl,
    super.aboutMe,
    super.jobTitle,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        skills: (json['skills'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        experienceYears: json['experience_years'] as int,
        location: json['location'] as String?,
        education: json['education'] as String?,
        cvText: json['cv_text'] as String?,
        phone: json['phone'] as String?,
        portfolioUrl: json['portfolio_url'] as String?,
        aboutMe: json['about_me'] as String?,
        jobTitle: json['job_title'] as String?,
      );

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'skills': skills,
        'experience_years': experienceYears,
        if (location != null) 'location': location,
        if (education != null) 'education': education,
        if (phone != null) 'phone': phone,
        if (portfolioUrl != null) 'portfolio_url': portfolioUrl,
        if (aboutMe != null) 'about_me': aboutMe,
        if (jobTitle != null) 'job_title': jobTitle,
      };
}
