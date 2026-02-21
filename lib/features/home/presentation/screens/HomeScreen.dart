import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wallet/core/services/hide_balance_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/home/presentation/screens/TransactionsPage.dart';
import 'package:my_wallet/features/wallet/data/presentation/screens/budget_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';
import 'dart:ui' as ui; // needed for ImageFilter

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
body: PageView(
  controller: _pageController,
  onPageChanged: (index) {
    setState(() {
      _currentIndex = index;
    });
  },
  children: [
    HomeTab(pageController: _pageController), // بدون const
    const AnalyticsTab(),
    const TransactionsTab(),
    const BudgetPage(),
  ],
),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home_filled, isDarkMode),
            _buildNavItem(1, Icons.pie_chart_outline, Icons.pie_chart, isDarkMode),
            _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, isDarkMode),
            _buildNavItem(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, bool isDarkMode) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDarkMode ? Colors.grey[900] : Colors.grey[100])
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              size: 24,
              color: isSelected 
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ) 
    );
  }
}

class HomeTab extends StatefulWidget {
  final PageController pageController;
  const HomeTab({super.key, required this.pageController});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final WalletRepository _walletRepository = WalletRepository();
  bool _isLoading = true;
  WalletHomeData? _homeData;
  String? _errorMessage;
  TransactionType _selectedFilter = TransactionType.all;

  List<String> get _categories => [
    context.l10n.categorySalary,
    context.l10n.categoryFood,
    context.l10n.categoryShopping,
    context.l10n.categoryTransportation,
    context.l10n.categoryEntertainment,
    context.l10n.categoryBills,
    context.l10n.categoryHealth,
    context.l10n.categoryEducation,
    context.l10n.categoryOther
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

Future<List<WalletTransaction>> _loadAllTransactions() async {
  try {
    final response = await _walletRepository.getTransactions(pageSize: 100);
    return response.transactions;
  } catch (e) {
    _showErrorSnackbar('Failed to load transactions: $e');
    return [];
  }
}

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      final data = await _walletRepository.getHomeData();
      setState(() {
        _homeData = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.errorLoadingData(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadHomeData();
  }

  List<TransactionFilter> get _filters => [
    TransactionFilter(type: TransactionType.all, label: context.l10n.all),
    TransactionFilter(type: TransactionType.income, label: context.l10n.income),
    TransactionFilter(type: TransactionType.expense, label: context.l10n.expense),
  ];

  List<WalletTransaction> get _filteredTransactions {
    if (_selectedFilter == TransactionType.all) return _homeData?.recentTransactions ?? [];
    
    return _homeData?.recentTransactions
        .where((t) => _selectedFilter == TransactionType.income 
            ? t.isDeposit 
            : t.isWithdrawal)
        .toList() ?? [];
  }

void _showAddTransactionDialog(TransactionType type) {
  final isIncome = type == TransactionType.income;
  
  // Controllers
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  
  // Selected values
  String? selectedCategory = _categories.first;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  
  // Recurring options
  bool isRecurring = false;
  String? recurringInterval;
  DateTime? recurringEndDate;
  
  // UI state
  bool _isSubmitting = false;
  double? _previewAmount;
  Future<void> _pickDate() async {
  final date = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (date != null) {
    setState(() {
      selectedDate = DateTime(
        date.year, date.month, date.day,
        selectedTime.hour, selectedTime.minute,
      );
    });
  }
}Future<void> _pickTime() async {
  final time = await showTimePicker(
    context: context,
    initialTime: selectedTime,
  );
  if (time != null) {
    setState(() {
      selectedTime = time;
      selectedDate = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day,
        time.hour, time.minute,
      );
    });
  }
}
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          
          // دالة مساعدة لفتح منتقي التاريخ والوقت
          Future<void> _pickDateTime() async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (time != null) {
                setState(() {
                  selectedDate = DateTime(
                    date.year, date.month, date.day,
                    time.hour, time.minute,
                  );
                  selectedTime = time;
                });
              }
            }
          }

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
                    // Handle
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header with icon and title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green[800] : Colors.red[800],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              isIncome ? context.l10n.addDeposit : context.l10n.addWithdrawal,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount preview (live)
                    if (_previewAmount != null && _previewAmount! > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isIncome ? Colors.green[800]! : Colors.red[800]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.amount,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}\$${_previewAmount!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isIncome ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Title Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: context.l10n.title,
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.title,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount Field
                  // Amount Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // يسمح فقط بالأرقام ونقطة عشرية واحدة
                      ],
                      onChanged: (value) {
                        setState(() {
                          _previewAmount = double.tryParse(value);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: context.l10n.amount,
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 16),
                    
                    // Quick amount suggestions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: (isIncome 
                            ? [50, 100, 500, 1000]
                            : [10, 20, 50, 100, 200])
                            .map((value) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('\$$value'),
                                onSelected: (_) {
                                  setState(() {
                                    amountController.text = value.toString();
                                    _previewAmount = value.toDouble();
                                  });
                                },
                                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                selected: false,
                              ),
                            ))
                            .toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: context.l10n.category,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            prefixIcon: Icon(
                              Icons.category,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date & Time Picker
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24),
  child: Row(
    children: [
      // حقل التاريخ
      Expanded(
        flex: 3,
        child: InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      // حقل الوقت
      Expanded(
        flex: 2,
        child: InkWell(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
                    const SizedBox(height: 16),
                    
                    // Recurring Switch and options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: isRecurring,
                            onChanged: (value) {
                              setState(() {
                                isRecurring = value;
                                if (!value) {
                                  recurringInterval = null;
                                  recurringEndDate = null;
                                }
                              });
                            },
                            title: Text(
                              context.l10n.recurringTransaction,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              context.l10n.recurringTransactionDescription,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            secondary: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.repeat,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          if (isRecurring) ...[
                            const SizedBox(height: 12),
                            // Interval selector
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: recurringInterval ?? 'monthly',
                                    items: const [
                                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        recurringInterval = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: context.l10n.recurringInterval,
                                      filled: true,
                                      fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: recurringEndDate ?? selectedDate.add(const Duration(days: 365)),
                                        firstDate: selectedDate,
                                        lastDate: DateTime(2100),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          recurringEndDate = date;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              recurringEndDate == null
                                                  ? context.l10n.endDate
                                                  : '${recurringEndDate!.day}/${recurringEndDate!.month}/${recurringEndDate!.year}',
                                              style: TextStyle(
                                                color: recurringEndDate == null
                                                    ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
                                                    : (isDarkMode ? Colors.white : Colors.black),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.l10n.descriptionOptional,
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.l10n.cancel,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      // Validation
                                      if (titleController.text.isEmpty) {
                                        _showErrorSnackbar(context.l10n.enterTitle);
                                        return;
                                      }
                                      if (amountController.text.isEmpty) {
                                        _showErrorSnackbar(context.l10n.enterAmount);
                                        return;
                                      }
                                      final amount = double.tryParse(amountController.text);
                                      if (amount == null || amount <= 0) {
                                        _showErrorSnackbar(context.l10n.enterValidAmount);
                                        return;
                                      }
                                      
                                      setState(() {
                                        _isSubmitting = true;
                                      });
                                      
                                      try {
                                        await _walletRepository.addTransaction(
                                          title: titleController.text,
                                          description: descriptionController.text,
                                          amount: amount,
                                          type: isIncome ? 'Deposit' : 'Withdrawal',
                                          category: selectedCategory!,
                                          transactionDate: selectedDate, // التاريخ المختار
                                          isRecurring: isRecurring,
                                          recurringInterval: recurringInterval,
                                          recurringEndDate: recurringEndDate,
                                        );
                                        
                                        Navigator.pop(context);
                                        await _loadHomeData();
                                        
                                        _showSuccessMessage(
                                          isIncome
                                              ? context.l10n.depositAddedSuccess
                                              : context.l10n.withdrawalAddedSuccess
                                        );
                                      } catch (e) {
                                        _showErrorSnackbar(context.l10n.failedToAddTransaction(e.toString()));
                                      } finally {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isIncome ? Colors.green[800] : Colors.red[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      context.l10n.add,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
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
  void _showDeleteConfirmationDialog(WalletTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            context.l10n.deleteTransaction,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            context.l10n.confirmDeleteTransaction(transaction.title),
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteTransaction(transaction);
              },
              child: Text(
                context.l10n.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(WalletTransaction transaction) async {
    try {
      final success = await _walletRepository.deleteTransaction(transaction.id);
      
      if (success) {
        await _loadHomeData();
        _showSuccessMessage(context.l10n.transactionDeletedSuccess);
      } else {
        _showErrorSnackbar(context.l10n.failedToDeleteTransaction);
      }
    } catch (e) {
      _showErrorSnackbar(context.l10n.errorDeletingTransaction(e.toString()));
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
void _showAllTransactionsModal(List<WalletTransaction> transactions) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Transactions list
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return _buildTransactionCard(transaction, isDarkMode);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
  // Skeleton Widgets (تم تعديلها لتتناسب مع التصميم الجديد)
  Widget _buildSkeletonAppBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBalanceCard(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonQuickActions(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(2, (index) {
          return Container(
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonTransactionHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonFilters(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonTransactionCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
      child: Column(
        children: [
          _buildSkeletonAppBar(isDarkMode),
          const SizedBox(height: 10),
          _buildSkeletonBalanceCard(isDarkMode),
          _buildSkeletonQuickActions(isDarkMode),
          _buildSkeletonTransactionHeader(isDarkMode),
          _buildSkeletonFilters(isDarkMode),
          ...List.generate(3, (index) => _buildSkeletonTransactionCard(isDarkMode)),
        ],
      ),
    );
  }

Widget _buildBlurrableNumber(String text, TextStyle style, bool blurred) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: blurred ? 0 : 8, end: blurred ? 8 : 0),
    duration: const Duration(milliseconds: 300),
    builder: (context, sigma, child) {
      if (sigma == 0) {
        return Text(text, style: style);
      }
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Text(text, style: style),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hideService = Provider.of<HideBalanceService>(context);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_isLoading)
                _buildSkeletonLoading(isDarkMode),

              if (_errorMessage != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHomeData,
                        child: Text(context.l10n.tryAgain),
                      ),
                    ],
                  ),
                ),

              if (_homeData != null && !_isLoading) ...[
                // بطاقة الرصيد الجديدة التي تمتد للأعلى وتحتوي على أيقونة البروفايل
// Balance Card (New Design - منفصلة عن الحافة)
Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
  child: Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDarkMode
            ? [Colors.grey[900]!, Colors.grey[850]!]
            : [Colors.white, Colors.grey[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف العلوي: (أيقونة المحفظة + اسم التطبيق) + أيقونة العين + صورة البروفايل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ===== الجزء المعدل: أيقونة + اسم التطبيق معاً داخل حاوية واحدة =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(30), // شكل كبسولة ناعم
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined, // أيقونة المحفظة
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.appTitle, // "محفظتي" أو "Mahfazati"
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // ===== نهاية التعديل =====
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      hideService.isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: hideService.toggle,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          onLocaleChanged: (locale) {},
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.totalBalance,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBlurrableNumber(
                '\$${_homeData!.balance.totalDeposits.toStringAsFixed(2)}',
                TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
                hideService.isHidden,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.income,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBlurrableNumber(
                      '\$${_homeData!.balance.totalDeposits.toStringAsFixed(2)}',
                      TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      hideService.isHidden,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.expense,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBlurrableNumber(
                      '\$${_homeData!.balance.totalDeposits.toStringAsFixed(2)}',
                      TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      hideService.isHidden,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        Icons.add,
                        context.l10n.addDeposit,
                        () => _showAddTransactionDialog(TransactionType.income),
                        isDarkMode,
                      ),
                      _buildQuickAction(
                        Icons.remove,
                        context.l10n.addWithdrawal,
                        () => _showAddTransactionDialog(TransactionType.expense),
                        isDarkMode,
                      ),
                    ],
                  ),
                ),

                // Recent Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.recentTransactions,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
if (_homeData != null && _homeData!.totalTransactionCount > 5)
  TextButton(
    onPressed: () async {
      final allTransactions = await _loadAllTransactions();
      if (!mounted) return;
      _showAllTransactionsModal(allTransactions);
    },
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
    ),
    child: Text(
      context.l10n.seeAll,
      style: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  )
else
  const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Transaction Filters
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: _filters
                        .map(
                          (filter) => Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = filter.type;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedFilter == filter.type
                                      ? (isDarkMode ? Colors.black : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _selectedFilter == filter.type
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  filter.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedFilter == filter.type
                                        ? (isDarkMode ? Colors.white : Colors.black)
                                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // Transactions List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _filteredTransactions.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : Column(
                          children: _filteredTransactions
                              .take(5)
                              .map((transaction) => _buildTransactionCard(transaction, isDarkMode))
                              .toList(),
                        ),
                ),

                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: isDarkMode
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildTransactionCard(WalletTransaction transaction, bool isDarkMode) {
  final isIncome = transaction.isDeposit;
  final hideService = Provider.of<HideBalanceService>(context, listen: true); // للاستماع للتغييرات

  return GestureDetector(
    onLongPress: () {
      _showDeleteConfirmationDialog(transaction);
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.icon,
              color: isIncome ? Colors.green[800] : Colors.red[800],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${_formatDate(transaction.transactionDate)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (transaction.description != null && transaction.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.description!,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // عمود المبلغ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // استبدال Text بـ _buildBlurrableNumber
              _buildBlurrableNumber(
                transaction.formattedAmount,
                TextStyle(
                  color: isIncome ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                hideService.isHidden,
              ),
              Text(
                _formatDate(transaction.transactionDate),
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noTransactions,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.addYourFirstTransaction,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${context.l10n.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${context.l10n.hoursAgo}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${context.l10n.daysAgo}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.analytics,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.trackSpendingHabits,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context.l10n.totalIncome,
                      '\$15,000',
                      Icons.trending_up,
                      Colors.green[800]!,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context.l10n.totalExpenses,
                      '\$2,499',
                      Icons.trending_down,
                      Colors.red[800]!,
                      isDarkMode,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Chart Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.spendingOverview,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.chartVisualization,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Categories
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.topCategories,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryItem(context.l10n.categoryFoodDining, '\$850', Icons.restaurant, isDarkMode),
                  _buildCategoryItem(context.l10n.categoryShopping, '\$650', Icons.shopping_bag, isDarkMode),
                  _buildCategoryItem(context.l10n.categoryTransportation, '\$320', Icons.directions_car, isDarkMode),
                  _buildCategoryItem(context.l10n.categoryEntertainment, '\$280', Icons.movie, isDarkMode),
                  _buildCategoryItem(context.l10n.categoryUtilities, '\$210', Icons.bolt, isDarkMode),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      )
      );
  }

  Widget _buildCategoryItem(String name, String amount, IconData icon, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionType { all, income, expense }

class TransactionFilter {
  final TransactionType type;
  final String label;

  TransactionFilter({
    required this.type,
    required this.label,
  });
}