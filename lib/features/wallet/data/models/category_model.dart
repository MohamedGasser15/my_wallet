class Category {
  final int id;
  final String nameAr;
  final String nameEn;
  final DateTime? createdAt;  // تغيير إلى nullable
  final DateTime? updatedAt;  // تغيير إلى nullable

  Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.createdAt,           // اختياري
    this.updatedAt,           // اختياري
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameAr: json['nameAr'],
      nameEn: json['nameEn'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,  // إذا لم يوجد، يصبح null
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}