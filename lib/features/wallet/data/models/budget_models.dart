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
      monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
      currentSpending: (json['currentSpending'] as num).toDouble(),
      categoryBudgets: (json['categoryBudgets'] as List)
          .map((e) => CategoryBudgetDto.fromJson(e))
          .toList(),
    );
  }
}

class CategoryBudgetDto {
  final String category;
  final double budget;
  final double spent;

  CategoryBudgetDto({
    required this.category,
    required this.budget,
    required this.spent,
  });

  factory CategoryBudgetDto.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetDto(
      category: json['category'],
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
    );
  }
}