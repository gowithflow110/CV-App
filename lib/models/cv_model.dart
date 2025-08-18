// lib/models/cv_model.dart

class CVModel {
  String? name;
  String? title;
  String? summary;
  String? email;
  String? phone;
  String? location;
  String? linkedin;
  List<String>? skills;
  List<CVExperience>? experiences;

  CVModel({
    this.name,
    this.title,
    this.summary,
    this.email,
    this.phone,
    this.location,
    this.linkedin,
    this.skills,
    this.experiences,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'summary': summary,
      'email': email,
      'phone': phone,
      'location': location,
      'linkedin': linkedin,
      'skills': skills,
      'experiences': experiences?.map((e) => e.toMap()).toList(),
    };
  }

  factory CVModel.fromMap(Map<String, dynamic> map) {
    return CVModel(
      name: map['name'],
      title: map['title'],
      summary: map['summary'],
      email: map['email'],
      phone: map['phone'],
      location: map['location'],
      linkedin: map['linkedin'],
      skills: List<String>.from(map['skills'] ?? []),
      experiences: (map['experiences'] as List<dynamic>?)
          ?.map((e) => CVExperience.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CVExperience {
  String? position;
  String? company;
  String? location;
  String? startDate;
  String? endDate;
  List<String>? responsibilities;

  CVExperience({
    this.position,
    this.company,
    this.location,
    this.startDate,
    this.endDate,
    this.responsibilities,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'company': company,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'responsibilities': responsibilities,
    };
  }

  factory CVExperience.fromMap(Map<String, dynamic> map) {
    return CVExperience(
      position: map['position'],
      company: map['company'],
      location: map['location'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      responsibilities: List<String>.from(map['responsibilities'] ?? []),
    );
  }
}
