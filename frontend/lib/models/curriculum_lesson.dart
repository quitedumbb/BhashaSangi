class CurriculumLesson {
  final int id;
  final String lessonTitle;
  final String gradeLevel;
  final String subject;

  const CurriculumLesson({
    required this.id,
    required this.lessonTitle,
    required this.gradeLevel,
    required this.subject,
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> json) {
    return CurriculumLesson(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      lessonTitle: (json['lesson_title'] ?? '').toString(),
      gradeLevel: (json['grade_level'] ?? 'Class 3').toString(),
      subject: (json['subject'] ?? 'Science / EVS').toString(),
    );
  }
}
