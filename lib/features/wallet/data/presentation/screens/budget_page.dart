// features/wallet/presentation/screens/budget_page.dart

import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/wallet/data/models/budget_models.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';
import 'package:shimmer/shimmer.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final WalletRepository _walletRepository = WalletRepository();
  bool _isLoading = true;
  String? _errorMessage;
  BudgetDto? _budget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final budget = await _walletRepository.getBudget();
      setState(() {
        _budget = budget;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load budget: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMonthlyBudget(double newBudget) async {
    try {
      await _walletRepository.updateMonthlyBudget(newBudget);
      // بعد التحديث نعيد تحميل البيانات
      await _loadBudget();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditBudgetDialog() {
    final TextEditingController budgetController = TextEditingController(
      text: _budget?.monthlyBudget.toStringAsFixed(0) ?? '3000',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.monthlyBudget,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: context.l10n.monthlyBudget,
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                prefixIcon: Icon(
                                  Icons.attach_money,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(
                                      context.l10n.cancel,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            if (budgetController.text.isEmpty) return;
                                            final budget = double.tryParse(budgetController.text);
                                            if (budget == null || budget <= 0) return;

                                            setState(() => isSubmitting = true);
                                            await _updateMonthlyBudget(budget);
                                            if (mounted) Navigator.pop(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? Colors.white : Colors.black,
                                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(context.l10n.save),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.budget,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _budget != null ? _showEditBudgetDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading(isDarkMode)
          : _errorMessage != null
              ? _buildErrorState(isDarkMode)
              : _buildContent(isDarkMode),
    );
  }

  Widget _buildShimmerLoading(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(height: 100, color: Colors.white),
          const SizedBox(height: 20),
          Container(height: 200, color: Colors.white),
          const SizedBox(height: 20),
          Container(height: 300, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: isDarkMode ? Colors.white70 : Colors.black54),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    final budget = _budget!;
    final remainingBudget = budget.monthlyBudget - budget.currentSpending;
    final progress = budget.currentSpending / budget.monthlyBudget;
    final isOverBudget = budget.currentSpending > budget.monthlyBudget;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Monthly Budget Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.monthlyBudget,
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    Text(
                      '\$${budget.monthlyBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.7 * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: isOverBudget ? Colors.red[800] : Colors.green[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.spent, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                        Text(
                          '\$${budget.currentSpending.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isOverBudget ? Colors.red[800] : Colors.green[800],
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(context.l10n.left, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                        Text(
                          '\$${remainingBudget.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: remainingBudget >= 0 ? Colors.green[800] : Colors.red[800],
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  remainingBudget >= 0 ? context.l10n.underBudget : context.l10n.overBudget,
                  style: TextStyle(
                    color: remainingBudget >= 0 ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category Budgets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.categories,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.l10n.monthlyBudget,
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category Budgets List
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Column(
              children: budget.categoryBudgets.map((cat) {
                final categoryProgress = cat.spent / cat.budget;
                final isCategoryOverBudget = cat.spent > cat.budget;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(cat.category).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(cat.category),
                        color: _getCategoryColor(cat.category),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cat.category,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 4,
                              width: 60 * categoryProgress.clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: isCategoryOverBudget ? Colors.red[800] : Colors.green[800],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${cat.spent.toStringAsFixed(0)} / \$${cat.budget.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isCategoryOverBudget
                              ? context.l10n.overBudget
                              : '${(cat.budget - cat.spent).toStringAsFixed(0)} ${context.l10n.left}',
                          style: TextStyle(
                            color: isCategoryOverBudget ? Colors.red[800] : Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lightbulb_outline, color: Colors.blue[800]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.budget,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOverBudget
                            ? '${context.l10n.overBudget}. ${context.l10n.tryReducingExpenses}.'
                            : '${context.l10n.underBudget}. ${context.l10n.considerSaving}.',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return Colors.orange[800]!;
      case 'Shopping': return Colors.purple[800]!;
      case 'Transportation': return Colors.blue[800]!;
      case 'Entertainment': return Colors.pink[800]!;
      case 'Bills': return Colors.cyan[800]!;
      default: return Colors.grey[800]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Shopping': return Icons.shopping_bag;
      case 'Transportation': return Icons.directions_car;
      case 'Entertainment': return Icons.movie;
      case 'Bills': return Icons.receipt;
      default: return Icons.category;
    }
  }
}