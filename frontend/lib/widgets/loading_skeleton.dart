import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius = 14,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: ClassroomColors.warmParchment.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: ClassroomColors.borderSubtle),
          ),
        );
      },
    );
  }
}
