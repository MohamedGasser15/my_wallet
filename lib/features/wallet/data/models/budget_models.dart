class BudgetDto {
  final double monthlyBudget;
  final double currentSpending;
  final List<CategoryBudgetDto> categoryBudgets;

  BudgetDto({
    required this.monthlyBudget,
    required this.currentSpending,
    required this.categoryBudgets,
  });

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    return BudgetDto(
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      currentSpending: (json['currentSpending'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: (json['categoryBudgets'] as List?)
              ?.map((e) => CategoryBudgetDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryBudgetDto {
  final int id;
  final int categoryId;
  final String categoryNameAr;
  final String categoryNameEn;
  final double budget;
  final double spent;

  CategoryBudgetDto({
    required this.id,
    required this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.budget,
    required this.spent,
  });

  factory CategoryBudgetDto.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetDto(
      id: json['id'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      categoryNameAr: json['categoryNameAr'] ?? '',
      categoryNameEn: json['categoryNameEn'] ?? '',
      budget: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}