import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Sweeps a shining highlight horizontally from left to right across its child.
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ?? (isDark ? const Color(0xFF2A3632) : const Color(0xFFE2E6E3));
    final highlight = widget.highlightColor ?? (isDark ? const Color(0xFF3B4A45) : const Color(0xFFF9FAF9));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate from -bounds.width to +bounds.width so the highlight shines smoothly left to right
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.2 - 1.1),
      0.0,
      0.0,
    );
  }
}

/// A basic placeholder box that catches the shimmer mask.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3632) : const Color(0xFFE2E6E3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmering skeleton card representing a customer gig card.
class GigCardSkeleton extends StatelessWidget {
  const GigCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 84, height: 22, borderRadius: 20),
                SkeletonBox(width: 72, height: 14),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 18, borderRadius: 6),
            SizedBox(height: 8),
            SkeletonBox(width: 200, height: 14, borderRadius: 4),
            SizedBox(height: 14),
            Row(
              children: [
                SkeletonBox(width: 110, height: 14),
                Spacer(),
                SkeletonBox(width: 68, height: 20, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering skeleton card representing a worker opportunity card.
class OpportunityCardSkeleton extends StatelessWidget {
  const OpportunityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 42, height: 42, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                SkeletonBox(width: 76, height: 24, borderRadius: 12),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 38, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 38, borderRadius: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering skeleton representing the tasks list inside the category task selector.
class TasksListSkeleton extends StatelessWidget {
  const TasksListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const widths = [180.0, 240.0, 150.0, 210.0, 190.0, 160.0];

    return ShimmerEffect(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final textWidth = widths[index % widths.length];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            child: Row(
              children: [
                const SkeletonBox(
                  width: 20,
                  height: 20,
                  borderRadius: 10,
                ),
                const SizedBox(width: 10),
                SkeletonBox(
                  width: textWidth,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
