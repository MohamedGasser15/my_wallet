// core/widgets/loading_indicator.dart
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  
  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 40,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}