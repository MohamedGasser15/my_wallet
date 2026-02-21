import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/wallet/data/models/wallet_models.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';
import 'package:shimmer/shimmer.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> with TickerProviderStateMixin {
  final WalletRepository _walletRepository = WalletRepository();
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String? _selectedType; // null = all, "Deposit", "Withdrawal"
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applySearchFilter();
    });
  }

  Future<void> _loadTransactions({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _walletRepository.getTransactions(
        page: page,
        pageSize: 20,
        type: _selectedType,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      setState(() {
        if (page == 1) {
          _transactions = response.transactions;
        } else {
          _transactions.addAll(response.transactions);
        }
        _applySearchFilter();
        _currentPage = response.page;
        _totalPages = response.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load transactions: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTransactions = List.from(_transactions);
    } else {
      _filteredTransactions = _transactions.where((t) =>
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        t.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadTransactions(page: _currentPage + 1);
    }
  }

  Future<void> _refreshData() async {
    _currentPage = 1;
    await _loadTransactions(page: 1);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    DateTime? tempFromDate = _fromDate;
    DateTime? tempToDate = _toDate;

    return StatefulBuilder(
      builder: (context, setState) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today, color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('From', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              trailing: Text(
                tempFromDate == null ? 'Any' : '${tempFromDate!.day}/${tempFromDate!.month}/${tempFromDate!.year}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: tempFromDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => tempFromDate = date);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: isDarkMode ? Colors.white70 : Colors.black54),
              title: Text('To', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              trailing: Text(
                tempToDate == null ? 'Any' : '${tempToDate!.day}/${tempToDate!.month}/${tempToDate!.year}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: tempToDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => tempToDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        tempFromDate = null;
                        tempToDate = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    child: Text('Reset', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = tempFromDate;
                        _toDate = tempToDate;
                      });
                      _loadTransactions(page: 1);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : Colors.black,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(width: 60, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 40, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
        title: Text(
          context.l10n.transactions,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchTransactions,
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, size: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        onPressed: _clearSearch,
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // Type Filter Chips with animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(context.l10n.all, null, _selectedType == null),
                    const SizedBox(width: 8),
                    _buildFilterChip(context.l10n.income, 'Deposit', _selectedType == 'Deposit'),
                    const SizedBox(width: 8),
                    _buildFilterChip(context.l10n.expense, 'Withdrawal', _selectedType == 'Withdrawal'),
                  ],
                ),
              ),
            ),

            // Results count
            if (!_isLoading && _filteredTransactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredTransactions.length} transactions',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Main content
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _filteredTransactions.isEmpty
                          ? _buildEmptyState(isDarkMode)
                          : RefreshIndicator(
                              onRefresh: _refreshData,
                              color: isDarkMode ? Colors.white : Colors.black,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < _filteredTransactions.length) {
                                    final transaction = _filteredTransactions[index];
                                    return _buildTransactionCard(transaction, isDarkMode);
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      // تم إزالة FloatingActionButton
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? (isDarkMode ? Colors.black : Colors.white)  // نص أبيض على خلفية سوداء والعكس
              : (isDarkMode ? Colors.white : Colors.black),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedType = value;
          _currentPage = 1;
          _loadTransactions(page: 1);
        });
      },
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      selectedColor: isDarkMode ? Colors.white : Colors.black, // خلفية حسب الوضع
      checkmarkColor: isDarkMode ? Colors.black : Colors.white, // لون علامة الصح
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildErrorState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: isDarkMode ? Colors.white70 : Colors.black54),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 96,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching transactions'
                : context.l10n.noTransactions,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : context.l10n.addYourFirstTransaction,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: _clearSearch,
                icon: Icon(Icons.clear, color: isDarkMode ? Colors.white70 : Colors.black54),
                label: Text('Clear search', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction, bool isDarkMode) {
    final isIncome = transaction.isDeposit;
    final color = isIncome ? Colors.green : Colors.red;

    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(transaction);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[850]!]
                : [Colors.white, Colors.grey[50]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // عرض تفاصيل المعاملة
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // أيقونة الفئة
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      transaction.icon,
                      color: color[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // التفاصيل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                transaction.category,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(transaction.transactionDate, context, short: false),
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (transaction.description != null && transaction.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              transaction.description!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // المبلغ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.formattedAmount,
                        style: TextStyle(
                          color: isIncome ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isIncome ? 'Income' : 'Expense',
                          style: TextStyle(
                            color: isIncome ? Colors.green[800] : Colors.red[800],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(WalletTransaction transaction) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Delete Transaction',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _walletRepository.deleteTransaction(transaction.id);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context, {required bool short}) {
    if (short) {
      return '${date.day}/${date.month}';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}