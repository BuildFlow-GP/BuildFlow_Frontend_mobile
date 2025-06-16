class Review {
  final int id;
  final int userId;
  final int? companyId;
  final int? projectId;
  final int? officeId;
  final int rating;
  final String? comment;
  final DateTime reviewedAt;

  // Relations
  final String? userName;
  final String? companyName;
  final String? projectName;
  final String? officeName;

  Review({
    required this.id,
    required this.userId,
    this.companyId,
    this.projectId,
    this.officeId,
    required this.rating,
    this.comment,
    required this.reviewedAt,
    this.userName,
    this.companyName,
    this.projectName,
    this.officeName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      companyId: json['company_id'],
      projectId: json['project_id'],
      officeId: json['office_id'],
      rating: json['rating'],
      comment: json['comment'],
      reviewedAt: DateTime.parse(json['reviewed_at']),
      userName: json['user']?['name'],
      companyName: json['company']?['name'],
      projectName: json['project']?['name'],
      officeName: json['office']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'company_id': companyId,
      'project_id': projectId,
      'office_id': officeId,
      'rating': rating,
      'comment': comment,
    };
  }
}
