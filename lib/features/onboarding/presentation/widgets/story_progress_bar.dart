import 'package:flutter/material.dart';

class StoryProgressBar extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final AnimationController progressController;
  final Function(int) onPageTap;
  
  const StoryProgressBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.progressController,
    required this.onPageTap,
  });
  
  @override
  State<StoryProgressBar> createState() => _StoryProgressBarState();
}

class _StoryProgressBarState extends State<StoryProgressBar> 
    with SingleTickerProviderStateMixin {
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.progressController,
        curve: Curves.linear,
      ),
    );
  }
  
  @override
  void didUpdateWidget(StoryProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      // إذا تغيرت الصفحة، أعد إنشاء الـ Animation
      _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: widget.progressController,
          curve: Curves.linear,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.totalPages, (index) {
        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onPageTap(index),
            child: Container(
              margin: EdgeInsets.only(right: index == widget.totalPages - 1 ? 0 : 4),
              height: 3,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  // الخلفية الرمادية لجميع الأشرطة
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // الصفحات المكتملة
                  if (index < widget.currentPage)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  
                  // الصفحة الحالية مع الحركة السلسة
                  if (index == widget.currentPage)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}