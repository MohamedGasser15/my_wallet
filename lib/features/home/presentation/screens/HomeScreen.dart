import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/settings/presentation/widgets/authentication_settings_bottom_sheet.dart';

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
        children: const [
          HomeTab(),
          AnalyticsTab(),
          TransactionsTab(),
          ProfileTab(),
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
            _buildNavItem(3, Icons.person_outline, Icons.person, isDarkMode),
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
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;
  List<WalletTransaction> _transactions = [];
  double _walletBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  TransactionType _selectedFilter = TransactionType.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _walletBalance = 12500.75;
      _totalIncome = 15000.0;
      _totalExpenses = 2499.25;
      _transactions = [
        WalletTransaction(
          id: '1',
          title: 'Salary Deposit',
          category: 'Salary',
          amount: 5000.0,
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: TransactionType.income,
          icon: Icons.account_balance_wallet,
        ),
        WalletTransaction(
          id: '2',
          title: 'Grocery Shopping',
          category: 'Food',
          amount: -1500.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: TransactionType.expense,
          icon: Icons.restaurant,
        ),
        WalletTransaction(
          id: '3',
          title: 'Freelance Payment',
          category: 'Freelance',
          amount: 3000.0,
          date: DateTime.now().subtract(const Duration(days: 3)),
          type: TransactionType.income,
          icon: Icons.work_outline,
        ),
        WalletTransaction(
          id: '4',
          title: 'Electricity Bill',
          category: 'Utilities',
          amount: -750.0,
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: TransactionType.expense,
          icon: Icons.bolt,
        ),
        WalletTransaction(
          id: '5',
          title: 'Online Purchase',
          category: 'Shopping',
          amount: -1200.0,
          date: DateTime.now().subtract(const Duration(days: 7)),
          type: TransactionType.expense,
          icon: Icons.shopping_bag,
        ),
        WalletTransaction(
          id: '6',
          title: 'Investment Return',
          category: 'Investment',
          amount: 2500.0,
          date: DateTime.now().subtract(const Duration(days: 10)),
          type: TransactionType.income,
          icon: Icons.trending_up,
        ),
      ];
      _isLoading = false;
    });
  }

  List<TransactionFilter> _filters = [
    TransactionFilter(type: TransactionType.all, label: 'All'),
    TransactionFilter(type: TransactionType.income, label: 'Income'),
    TransactionFilter(type: TransactionType.expense, label: 'Expense'),
  ];

  List<WalletTransaction> get _filteredTransactions {
    if (_selectedFilter == TransactionType.all) return _transactions;
    return _transactions
        .where((t) => t.type == _selectedFilter)
        .toList();
  }

  void _showAddTransactionDialog(TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                        type == TransactionType.income ? 'Add Income' : 'Add Expense',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField('Title', Icons.title, isDarkMode),
                      const SizedBox(height: 16),
                      _buildInputField('Amount', Icons.attach_money, isDarkMode),
                      const SizedBox(height: 16),
                      _buildInputField('Category', Icons.category, isDarkMode),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
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
                                'Cancel',
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
                              onPressed: () {
                                Navigator.pop(context);
                                _showSuccessMessage(type);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildInputField(String label, IconData icon, bool isDarkMode) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
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
    );
  }

  void _showSuccessMessage(TransactionType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${type == TransactionType.income ? 'Income' : 'Expense'} added successfully!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'John Doe',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: _showAuthenticationSettings,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.visibility_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _walletBalance.toStringAsFixed(2),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceStat('Income', _totalIncome, isDarkMode, isPositive: true),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        ),
                        Expanded(
                          child: _buildBalanceStat('Expenses', _totalExpenses, isDarkMode, isPositive: false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    Icons.add,
                    'Add',
                    () => _showAddTransactionDialog(TransactionType.income),
                    isDarkMode,
                  ),
                  _buildQuickAction(
                    Icons.remove,
                    'Remove',
                    () => _showAddTransactionDialog(TransactionType.expense),
                    isDarkMode,
                  ),
                  _buildQuickAction(
                    Icons.swap_horiz,
                    'Transfer',
                    () {},
                    isDarkMode,
                  ),
                  _buildQuickAction(
                    Icons.download,
                    'Withdraw',
                    () {},
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
                    'Recent Transactions',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
              child: _isLoading
                  ? _buildLoadingSkeleton(isDarkMode)
                  : _filteredTransactions.isEmpty
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
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, double amount, bool isDarkMode, {required bool isPositive}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPositive ? '+' : '-',
              style: TextStyle(
                color: isPositive ? Colors.green[800] : Colors.red[800],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isPositive ? Colors.green[800] : Colors.red[800],
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction, bool isDarkMode) {
    final isIncome = transaction.type == TransactionType.income;
    
    return Container(
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
                  transaction.category,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isIncome ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                _formatDate(transaction.date),
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDarkMode) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
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
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
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
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthenticationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const AuthenticationSettingsBottomSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
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
                        'Analytics',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your spending habits',
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
                      'Total Income',
                      '\$15,000',
                      Icons.trending_up,
                      Colors.green[800]!,
                      isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Expenses',
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
                    'Spending Overview',
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
                        'Chart Visualization',
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
                    'Top Categories',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryItem('Food & Dining', '\$850', Icons.restaurant, isDarkMode),
                  _buildCategoryItem('Shopping', '\$650', Icons.shopping_bag, isDarkMode),
                  _buildCategoryItem('Transportation', '\$320', Icons.directions_car, isDarkMode),
                  _buildCategoryItem('Entertainment', '\$280', Icons.movie, isDarkMode),
                  _buildCategoryItem('Utilities', '\$210', Icons.bolt, isDarkMode),
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
      ),
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

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> transactions = [
      {
        'title': 'Salary Deposit',
        'category': 'Salary',
        'amount': 5000.0,
        'type': 'income',
        'icon': Icons.account_balance_wallet,
        'date': 'Today',
      },
      {
        'title': 'Grocery Shopping',
        'category': 'Food',
        'amount': -150.0,
        'type': 'expense',
        'icon': Icons.restaurant,
        'date': 'Today',
      },
      {
        'title': 'Netflix Subscription',
        'category': 'Entertainment',
        'amount': -15.99,
        'type': 'expense',
        'icon': Icons.movie,
        'date': 'Yesterday',
      },
      {
        'title': 'Freelance Payment',
        'category': 'Freelance',
        'amount': 1200.0,
        'type': 'income',
        'icon': Icons.work_outline,
        'date': '2 days ago',
      },
      {
        'title': 'Electricity Bill',
        'category': 'Utilities',
        'amount': -85.50,
        'type': 'expense',
        'icon': Icons.bolt,
        'date': '3 days ago',
      },
      {
        'title': 'Online Purchase',
        'category': 'Shopping',
        'amount': -249.99,
        'type': 'expense',
        'icon': Icons.shopping_bag,
        'date': '5 days ago',
      },
    ];

    return SafeArea(
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
                      'Transactions',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All your transactions in one place',
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
                    Icons.filter_list,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Transactions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isIncome = transaction['type'] == 'income';
                
                return Container(
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
                          transaction['icon'] as IconData,
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
                              transaction['title'] as String,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction['category']} • ${transaction['date']}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}\$${(transaction['amount'] as double).abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isIncome ? 'Income' : 'Expense',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'John Doe',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'john.doe@email.com',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Stats
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProfileStat('Transactions', '156', isDarkMode),
                  _buildProfileStat('Categories', '12', isDarkMode),
                  _buildProfileStat('Balance', '\$12,500', isDarkMode),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    'Account Settings',
                    Icons.person_outline,
                    isDarkMode,
                    showTrailing: true,
                  ),
                  _buildSettingItem(
                    'Notifications',
                    Icons.notifications_outlined,
                    isDarkMode,
                    showTrailing: true,
                  ),
                  _buildSettingItem(
                    'Security',
                    Icons.lock_outline,
                    isDarkMode,
                    showTrailing: true,
                  ),
                  _buildSettingItem(
                    'Help & Support',
                    Icons.help_outline,
                    isDarkMode,
                    showTrailing: true,
                  ),
                  _buildSettingItem(
                    'About',
                    Icons.info_outline,
                    isDarkMode,
                    showTrailing: true,
                  ),
                  _buildSettingItem(
                    'Log Out',
                    Icons.logout,
                    isDarkMode,
                    isLogout: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String title, IconData icon, bool isDarkMode, {
    bool showTrailing = false,
    bool isLogout = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLogout 
              ? Colors.red.withOpacity(0.1)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red[800] : (isDarkMode ? Colors.white : Colors.black),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red[800] : (isDarkMode ? Colors.white : Colors.black),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: showTrailing
            ? Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              )
            : null,
      ),
    );
  }
}

// Models
enum TransactionType { all, income, expense }

class WalletTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final IconData icon;

  WalletTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.icon,
  });
}

class TransactionFilter {
  final TransactionType type;
  final String label;

  TransactionFilter({
    required this.type,
    required this.label,
  });
}