class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  // Personal Data
  final String? gender;
  final DateTime? dateOfBirth;

  // Professional Data
  final double professionalSalary;
  final int? salaryCreditDate;
  final double fixedAllowances;
  final String? jobTitle;
  final String? companyName;
  final String? professionType; // 'White Collar' or 'Labor'
  final bool mustChangePassword;
  final DateTime? tempPwdExpiresAt;
  final DateTime? accountLockedUntil;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    this.gender,
    this.dateOfBirth,
    this.professionalSalary = 0,
    this.salaryCreditDate,
    this.fixedAllowances = 0,
    this.jobTitle,
    this.companyName,
    this.professionType,
    this.mustChangePassword = false,
    this.tempPwdExpiresAt,
    this.accountLockedUntil,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      professionalSalary:
          (json['professional_salary'] as num?)?.toDouble() ?? 0,
      salaryCreditDate: json['salary_credit_date'] as int?,
      fixedAllowances: (json['fixed_allowances'] as num?)?.toDouble() ?? 0,
      jobTitle: json['job_title'] as String?,
      companyName: json['company_name'] as String?,
      professionType: json['profession_type'] as String?,
      mustChangePassword: (json['must_change_password'] as bool?) ?? false,
      tempPwdExpiresAt: json['temp_pwd_expires_at'] != null
          ? DateTime.parse(json['temp_pwd_expires_at'] as String)
          : null,
      accountLockedUntil: json['account_locked_until'] != null
          ? DateTime.parse(json['account_locked_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'professional_salary': professionalSalary,
      'salary_credit_date': salaryCreditDate,
      'fixed_allowances': fixedAllowances,
      'job_title': jobTitle,
      'company_name': companyName,
      'profession_type': professionType,
      'must_change_password': mustChangePassword,
    };
  }

  double get completeness {
    int totalFields =
        9; // ID, FullName, CreatedAt are mandatory. Others are optional.
    int filledFields = 0;

    if (avatarUrl != null) filledFields++;
    if (gender != null) filledFields++;
    if (dateOfBirth != null) filledFields++;
    if (professionalSalary > 0) filledFields++;
    if (salaryCreditDate != null) filledFields++;
    if (fixedAllowances > 0) filledFields++;
    if (jobTitle != null && jobTitle!.isNotEmpty) filledFields++;
    if (companyName != null && companyName!.isNotEmpty) filledFields++;
    if (professionType != null) filledFields++;

    return filledFields / totalFields;
  }
}
