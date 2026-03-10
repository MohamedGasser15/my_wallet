import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_wallet/core/services/hide_balance_service.dart';
import 'package:my_wallet/core/services/message_service.dart';
import 'package:my_wallet/core/utils/api_error_handler.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/home/presentation/screens/TransactionsPage.dart';
import 'package:my_wallet/features/wallet/data/models/category_model.dart';
import 'package:my_wallet/features/wallet/data/models/voice_expense_model.dart';
import 'package:my_wallet/features/wallet/data/presentation/screens/analytics_screen.dart';
import 'package:my_wallet/features/wallet/data/presentation/screens/budget_page.dart';
import 'package:my_wallet/features/wallet/data/repositories/category_repository.dart';
import 'package:my_wallet/features/wallet/presentation/widgets/voice_expense_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';
import 'dart:ui' as ui;

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
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              HomeTab(pageController: _pageController),
              const AnalyticsScreen(),
              const TransactionsTab(),
              const BudgetPage(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _buildFloatingNav(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNav(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 75,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, FontAwesomeIcons.solidHouse, FontAwesomeIcons.solidHouse, isDarkMode),
              _buildNavItem(1, FontAwesomeIcons.chartSimple, FontAwesomeIcons.chartSimple, isDarkMode),
              _buildNavItem(2, FontAwesomeIcons.receipt, FontAwesomeIcons.receipt, isDarkMode),
              _buildNavItem(3, FontAwesomeIcons.wallet, FontAwesomeIcons.wallet, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData outlineIcon, IconData filledIcon, bool isDarkMode) {
    final isSelected = _currentIndex == index;
    final l10n = context.l10n;

    String label;
    switch (index) {
      case 0:
        label = l10n.home;
        break;
      case 1:
        label = l10n.analytics;
        break;
      case 2:
        label = l10n.transactions;
        break;
      case 3:
        label = l10n.budget;
        break;
      default:
        label = '';
    }

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 70,
        height: 65,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                size: 26,
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white60 : Colors.black45),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white60 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
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
  //#region Private Fields
  final WalletRepository _walletRepository = WalletRepository();
  bool _isLoading = true;
  WalletHomeData? _homeData;
  String? _errorMessage;
  TransactionType _selectedFilter = TransactionType.all;

  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  String? _currencyCode;
  bool _currencyLoaded = false;
  //#endregion

  //#region Currency Helpers
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'EGP': 'E£',
    'SAR': '﷼',
    'AED': 'د.إ',
    'KWD': 'د.ك',
  };
  //#endregion

  //#region Lifecycle
  @override
  void initState() {
    super.initState();
    _loadCurrency().then((_) {
      _loadHomeData();
    });
    _loadCategories();
  }
  //#endregion

  //#region Data Loading
  Future<void> _loadCurrency() async {
    final code = await SharedPrefs.getCurrency();
    setState(() {
      _currencyCode = code ?? 'USD';
      _currencyLoaded = true;
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final repo = CategoryRepository();
      _categories = await repo.getAllCategories();
    } catch (e) {
      final errorMsg = ApiErrorHandler.getErrorMessage(e);
      debugPrint('Error loading categories: $errorMsg');
      MessageService.showError('فشل تحميل الفئات: $errorMsg');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<List<WalletTransaction>> _loadAllTransactions() async {
    try {
      final response = await _walletRepository.getTransactions(pageSize: 100);
      return response.transactions;
    } catch (e) {
      final errorMsg = ApiErrorHandler.getErrorMessage(e);
      MessageService.showError('فشل تحميل المعاملات: $errorMsg');
      return [];
    }
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _walletRepository.getHomeData();
      setState(() {
        _homeData = data;
      });
    } catch (e) {
      final errorMsg = ApiErrorHandler.getErrorMessage(e);
      setState(() {
        _errorMessage = errorMsg;
      });
      if (!ApiErrorHandler.isNetworkError(e)) {
        MessageService.showError(errorMsg);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadHomeData();
  }
  //#endregion

  //#region Filter Helpers
  List<TransactionFilter> get _filters => [
        TransactionFilter(type: TransactionType.all, label: context.l10n.all),
        TransactionFilter(type: TransactionType.income, label: context.l10n.income),
        TransactionFilter(type: TransactionType.expense, label: context.l10n.expense),
      ];

  List<WalletTransaction> get _filteredTransactions {
    if (_selectedFilter == TransactionType.all)
      return _homeData?.recentTransactions ?? [];

    return _homeData?.recentTransactions
            .where((t) => _selectedFilter == TransactionType.income
                ? t.isDeposit
                : t.isWithdrawal)
            .toList() ??
        [];
  }
  //#endregion

  //#region Dialog Helpers (Add / Edit / Delete)
void _showAddTransactionDialog(
  TransactionType type, {
  VoiceExpenseResult? prefillFromVoice,
}) {
  final isIncome = type == TransactionType.income;

  // ✅ فلترة الكاتيجوريز الصح من البداية
  final filteredCategories = _categories.where((c) => isIncome
      ? ['Salary', 'Bonus', 'Income'].contains(c.nameEn)
      : !['Salary', 'Bonus', 'Income'].contains(c.nameEn)).toList();

  // ✅ الـ default بياخد من الـ filtered مش من الكل
  int? selectedCategoryId = prefillFromVoice?.categoryId != null
      ? prefillFromVoice!.categoryId
      : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null);

  final descriptionController = TextEditingController(
    text: prefillFromVoice?.note ?? '',
  );
  final amountController = TextEditingController(
    text: prefillFromVoice?.amount?.toString() ?? '',
  );

  bool _isSubmitting = false;
  double? _previewAmount = prefillFromVoice?.amount;

  final currencyCode = _currencyCode ?? 'USD';
  final currencySymbol = currencySymbols[currencyCode] ?? '\$';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                      height: 4, width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            isIncome ? context.l10n.addDeposit : context.l10n.addWithdrawal,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_previewAmount != null && _previewAmount! > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isIncome ? Colors.green[800]! : Colors.red[800]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.l10n.amount,
                                style: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                            Text(
                              '${isIncome ? '+' : '-'}$currencySymbol${_previewAmount!.toStringAsFixed(2)}',
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        ],
                        onChanged: (value) {
                          setState(() => _previewAmount = double.tryParse(value));
                        },
                        decoration: InputDecoration(
                          labelText: context.l10n.amount,
                          prefixIcon: Icon(Icons.attach_money,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: (isIncome
                                ? [50, 500, 1000, 2000]
                                : [10, 50, 100, 200])
                            .map((value) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('$currencySymbol$value'),
                                    onSelected: (_) => setState(() {
                                      amountController.text = value.toString();
                                      _previewAmount = value.toDouble();
                                    }),
                                    backgroundColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                    selected: false,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Dropdown بيستخدم filteredCategories المحسوبة فوق
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : filteredCategories.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'لا توجد فئات متاحة',
                                    style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  value: selectedCategoryId,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.category,
                                    prefixIcon: Icon(Icons.category,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  // ✅ بيستخدم filteredCategories مباشرة
                                  items: filteredCategories
                                      .map((category) => DropdownMenuItem<int>(
                                            value: category.id,
                                            child: Text(
                                              Localizations.localeOf(context).languageCode == 'ar'
                                                  ? category.nameAr
                                                  : category.nameEn,
                                              style: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => selectedCategoryId = value),
                                ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.l10n.descriptionOptional,
                          prefixIcon: Icon(Icons.description,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

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
                                    color: isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(context.l10n.cancel,
                                  style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      if (amountController.text.isEmpty) {
                                        MessageService.showError(context.l10n.enterAmount);
                                        return;
                                      }
                                      final amount = double.tryParse(amountController.text);
                                      if (amount == null || amount <= 0) {
                                        MessageService.showError(context.l10n.enterValidAmount);
                                        return;
                                      }
                                      if (selectedCategoryId == null) {
                                        MessageService.showError('اختر فئة');
                                        return;
                                      }

                                      setState(() => _isSubmitting = true);
                                      try {
                                        await _walletRepository.addTransaction(
                                          description: descriptionController.text,
                                          amount: amount,
                                          type: isIncome ? 'Deposit' : 'Withdrawal',
                                          categoryId: selectedCategoryId!,
                                        );
                                        Navigator.pop(context);
                                        await _loadHomeData();
                                        MessageService.showSuccess(isIncome
                                            ? context.l10n.depositAddedSuccess
                                            : context.l10n.withdrawalAddedSuccess);
                                      } catch (e) {
                                        MessageService.showError(e.toString());
                                      } finally {
                                        setState(() => _isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isIncome ? Colors.green[800] : Colors.red[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(context.l10n.add,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
void _showEditTransactionDialog(WalletTransaction transaction) {
  final isIncome = transaction.isDeposit;

  final filteredCategories = _categories.where((c) => isIncome
      ? ['Salary', 'Bonus', 'Income'].contains(c.nameEn)
      : !['Salary', 'Bonus', 'Income'].contains(c.nameEn)).toList();

  int? selectedCategoryId = filteredCategories.any((c) => c.id == transaction.categoryId)
      ? transaction.categoryId
      : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null);

  final amountController = TextEditingController(text: transaction.amount.toString());
  final descriptionController = TextEditingController(text: transaction.description ?? '');

  bool _isSubmitting = false;
  double? _previewAmount = transaction.amount;

  final currencyCode = _currencyCode ?? 'USD';
  final currencySymbol = currencySymbols[currencyCode] ?? '\$';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                      height: 4, width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            isIncome ? context.l10n.editDeposit : context.l10n.editWithdrawal,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount preview
                    if (_previewAmount != null && _previewAmount! > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isIncome ? Colors.green[800]! : Colors.red[800]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.l10n.amount,
                                style: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                            Text(
                              '${isIncome ? '+' : '-'}$currencySymbol${_previewAmount!.toStringAsFixed(2)}',
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

                    // Amount field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        ],
                        onChanged: (value) {
                          setState(() => _previewAmount = double.tryParse(value));
                        },
                        decoration: InputDecoration(
                          labelText: context.l10n.amount,
                          prefixIcon: Icon(Icons.attach_money,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick amount chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: (isIncome
                                ? [50, 500, 1000, 2000]
                                : [10, 50, 100, 200])
                            .map((value) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('$currencySymbol$value'),
                                    onSelected: (_) => setState(() {
                                      amountController.text = value.toString();
                                      _previewAmount = value.toDouble();
                                    }),
                                    backgroundColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                    selected: false,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : filteredCategories.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('لا توجد فئات متاحة',
                                      style: TextStyle(
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                                )
                              : DropdownButtonFormField<int>(
                                  value: selectedCategoryId,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.category,
                                    prefixIcon: Icon(Icons.category,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: filteredCategories
                                      .map((category) => DropdownMenuItem<int>(
                                            value: category.id,
                                            child: Text(
                                              Localizations.localeOf(context).languageCode == 'ar'
                                                  ? category.nameAr
                                                  : category.nameEn,
                                              style: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => selectedCategoryId = value),
                                ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: context.l10n.descriptionOptional,
                          prefixIcon: Icon(Icons.description,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(context.l10n.cancel,
                                  style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      if (amountController.text.isEmpty) {
                                        MessageService.showError(context.l10n.enterAmount);
                                        return;
                                      }
                                      final amount = double.tryParse(amountController.text);
                                      if (amount == null || amount <= 0) {
                                        MessageService.showError(context.l10n.enterValidAmount);
                                        return;
                                      }
                                      if (selectedCategoryId == null) {
                                        MessageService.showError('اختر فئة');
                                        return;
                                      }

                                      setState(() => _isSubmitting = true);
                                      try {
                                        await _walletRepository.updateTransaction(
                                          transaction.id,
                                          title: transaction.title, // ✅ بيحتفظ بالـ title القديم
                                          description: descriptionController.text,
                                          amount: amount,
                                          type: isIncome ? 'Deposit' : 'Withdrawal',
                                          categoryId: selectedCategoryId!,
                                          transactionDate: transaction.transactionDate, // ✅ بيحتفظ بالتاريخ
                                          isRecurring: transaction.isRecurring ?? false,
                                          recurringInterval: transaction.recurringInterval,
                                          recurringEndDate: transaction.recurringEndDate,
                                        );
                                        Navigator.pop(context);
                                        await _loadHomeData();
                                        MessageService.showSuccess(context.l10n.transactionUpdatedSuccess);
                                      } catch (e) {
                                        MessageService.showError(e.toString());
                                      } finally {
                                        setState(() => _isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isIncome ? Colors.green[800] : Colors.red[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(context.l10n.update,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
  //#endregion

  //#region Transaction Actions
  Future<void> _deleteTransaction(WalletTransaction transaction) async {
    try {
      final success = await _walletRepository.deleteTransaction(transaction.id);

      if (success) {
        await _loadHomeData();
        MessageService.showSuccess(context.l10n.transactionDeletedSuccess);
      } else {
        MessageService.showError(context.l10n.failedToDeleteTransaction);
      }
    } catch (e) {
      MessageService.showError(context.l10n.errorDeletingTransaction(e.toString()));
    }
  }

  Future<void> _updateTransaction(WalletTransaction transaction,
      {required String title,
      required String description,
      required double amount,
      required String type,
      required int categoryId,
      required DateTime transactionDate,
      bool isRecurring = false,
      String? recurringInterval,
      DateTime? recurringEndDate}) async {
    try {
      await _walletRepository.updateTransaction(
        transaction.id,
        title: title,
        description: description,
        amount: amount,
        type: type,
        categoryId: categoryId,
        transactionDate: transactionDate,
        isRecurring: isRecurring,
        recurringInterval: recurringInterval,
        recurringEndDate: recurringEndDate,
      );
      await _loadHomeData();
      MessageService.showSuccess('تم تحديث المعاملة بنجاح');
    } catch (e) {
      MessageService.showError('فشل تحديث المعاملة: ${e.toString()}');
    }
  }
  //#endregion

  //#region All Transactions Modal
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
  //#endregion

  //#region Skeleton Widgets
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
  //#endregion

  //#region UI Builders
  Widget _buildBlurrableNumber(double amount, TextStyle style, bool blurred) {
    final formatted = _formatAmount(amount);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: blurred ? 0 : 8, end: blurred ? 8 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, sigma, child) {
        if (sigma == 0) {
          return Text(formatted, style: style);
        }
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Text(formatted, style: style),
        );
      },
    );
  }

  Widget _buildErrorWidget(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'عذراً، حدث خطأ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadHomeData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
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
  final hideService = Provider.of<HideBalanceService>(context, listen: true);
  final locale = Localizations.localeOf(context).languageCode;
  final categoryName = locale == 'ar'
      ? (transaction.categoryNameAr ?? transaction.categoryNameEn ?? '')
      : (transaction.categoryNameEn ?? transaction.categoryNameAr ?? '');

  return Slidable(
    key: Key('transaction_${transaction.id}'),
    endActionPane: ActionPane(
      motion: const ScrollMotion(),
      children: [
        // زر التعديل
        CustomSlidableAction(
          onPressed: (context) => _showEditTransactionDialog(transaction),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          child: Container(
            width: 80,
            margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.blue.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.blue.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit,
                        color: isDarkMode ? Colors.white : Colors.blue[800],
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.edit,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.blue[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // زر الحذف
        CustomSlidableAction(
          onPressed: (context) => _showDeleteConfirmationDialog(transaction),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          child: Container(
            width: 80,
            margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.red.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.red.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete,
                        color: isDarkMode ? Colors.white : Colors.red[800],
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.delete,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.red[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
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
                  '$categoryName • ${_formatDate(transaction.transactionDate)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty)
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBlurrableNumber(
                transaction.amount,
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hideService = Provider.of<HideBalanceService>(context);

    return SafeArea(
      bottom: false,
      child: Stack(
         children: [ RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_homeData == null) ...[
                if (_isLoading)
                  _buildSkeletonLoading(isDarkMode)
                else if (_errorMessage != null)
                  _buildErrorWidget(isDarkMode)
                else
                  const SizedBox.shrink(),
              ] else ...[
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(30),
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
                                      Icons.account_balance_wallet_outlined,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n.appTitle,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      hideService.isHidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
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
                                      backgroundColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      child: Icon(
                                        Icons.person,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
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
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBlurrableNumber(
                                _homeData!.balance.totalBalance,
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
                                      _homeData!.balance.totalDeposits,
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
                                      _homeData!.balance.totalWithdrawals,
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
                  child: // في مكان Row الـ Quick Actions في build()
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildQuickAction(
      Icons.add, context.l10n.addDeposit,
      () => _showAddTransactionDialog(TransactionType.income),
      isDarkMode,
    ),
    _buildQuickAction(
      Icons.remove, context.l10n.addWithdrawal,
      () => _showAddTransactionDialog(TransactionType.expense),
      isDarkMode,
    ),
  ],
),
                ),
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
                      if (_homeData!.totalTransactionCount > 5)
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
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
                                        : (isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
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
                 const SizedBox(height: 160),
              ],
            ],
          ),
        ),
      ),
       Positioned(
          bottom: 105,
          left: 0,
          right: 0,
          child: Center(
            child: VoiceExpenseButton(
              isDarkMode: isDarkMode,
              onResult: (result) {
                if (result.isSuccess) {
                  final type = result.transactionType == 'Deposit'
                      ? TransactionType.income
                      : TransactionType.expense;
                  _showAddTransactionDialog(type, prefillFromVoice: result);
                } else {
                  MessageService.showError(
                      result.errorMessage ?? 'فشل تحليل الصوت');
                }
              },
            ),
          ),
        ),
      ],
    )
  );}
  //#endregion

  //#region Helper Methods
  String _formatAmount(double amount) {
    final symbol = _currencyCode != null ? (currencySymbols[_currencyCode] ?? '\$') : '\$';
    final formatter = NumberFormat('#,##0', 'en_US');
    return '$symbol ${formatter.format(amount)}';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
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
  //#endregion
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