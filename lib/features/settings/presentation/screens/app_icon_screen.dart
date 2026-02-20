import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> with TickerProviderStateMixin {
  int _selectedIconIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  // قائمة الأيقونات (ممكن تكون مسارات لصور SVG أو أيقونات Flutter)
  final List<Map<String, dynamic>> _appIcons = [
    {'icon': Icons.account_balance_wallet, 'color': Colors.blue, 'name': 'Wallet'},
    {'icon': Icons.savings, 'color': Colors.green, 'name': 'Savings'},
    {'icon': Icons.attach_money, 'color': Colors.orange, 'name': 'Money'},
    {'icon': Icons.currency_exchange, 'color': Colors.purple, 'name': 'Exchange'},
    {'icon': Icons.pie_chart, 'color': Colors.red, 'name': 'Pie Chart'},
    {'icon': Icons.trending_up, 'color': Colors.teal, 'name': 'Trend'},
    {'icon': Icons.show_chart, 'color': Colors.indigo, 'name': 'Chart'},
    {'icon': Icons.credit_card, 'color': Colors.pink, 'name': 'Card'},
    {'icon': Icons.account_balance, 'color': Colors.brown, 'name': 'Bank'},
    {'icon': Icons.money_off, 'color': Colors.cyan, 'name': 'Money Off'},
    {'icon': Icons.price_change, 'color': Colors.lime, 'name': 'Price Change'},
    {'icon': Icons.receipt_long, 'color': Colors.deepOrange, 'name': 'Receipt'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.changeAppIcon),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // زر التطبيق
          TextButton(
            onPressed: _selectedIconIndex == 0
                ? null
                : () {
                    // محاكاة تطبيق التغيير
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('App icon changed (simulated)'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
            child: Text(
              l10n.apply,
              style: TextStyle(
                color: _selectedIconIndex == 0
                    ? theme.disabledColor
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // عرض الأيقونة الحالية بشكل مميز
          Container(
            margin: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  l10n.currentIcon,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _appIcons[_selectedIconIndex]['color'].withOpacity(0.8),
                        _appIcons[_selectedIconIndex]['color'],
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _appIcons[_selectedIconIndex]['color'].withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _appIcons[_selectedIconIndex]['icon'],
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _appIcons[_selectedIconIndex]['name'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // شبكة الأيقونات
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _appIcons.length,
              itemBuilder: (context, index) {
                final iconData = _appIcons[index];
                final isSelected = _selectedIconIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconIndex = index;
                    });
                    _controller.forward(from: 0);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(
                              color: iconData['color'],
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: iconData['color'].withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData['icon'],
                          size: 40,
                          color: isSelected
                              ? iconData['color']
                              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          iconData['name'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? iconData['color']
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // زر التطبيق في الأسفل (للجوالات الكبيرة، ولكن موجود في الـ actions كمان)
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIconIndex == 0
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('App icon changed (simulated)'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}